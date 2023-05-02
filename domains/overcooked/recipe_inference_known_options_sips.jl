# Recipe inference with a discrete uniform prior #

using Base: @kwdef
using Printf
using DataStructures: OrderedDict
using PDDL, SymbolicPlanners
using PDDLViz, GLMakie
using Gen, GenParticleFilters
using CSV, DataFrames, Dates
using Plinf

using SymbolicPlanners: simplify_goal
using GenParticleFilters: softmax

include("load_goals.jl")
include("load_plan.jl")
include("planner.jl")

DOMAIN_DIR = @__DIR__
PROBLEM_DIR = joinpath(@__DIR__, "problems")
GOALS_DIR = joinpath(@__DIR__, "goals")
PLANS_DIR = joinpath(@__DIR__, "plans")

# Kitchen names
KITCHEN_NAMES = [
    "salad bar", 
    "sushi bar",
    "delicatessen",
    "pizzeria",
    "fruits and desserts"
]

# Paths to problems to generate recipe descriptions for
PROBLEMS = [
    [joinpath(PROBLEM_DIR, "problem-$i-$j.pddl") for j in 1:5] for i in 1:5
]

GOALS = [
    [joinpath(GOALS_DIR, "goals-$i-$j.pddl") for j in 1:5] for i in 1:5
]

# Find plan paths
PLANS = [
    [joinpath(PLANS_DIR, "problem-$i-$j", "narrative-plan-$i-$j-1.pddl") for j in 1:5] for i in 1:5
]

N_GOALS_PER_PROBLEM = 5

DISTINGUISH_GOALS = true
ACT_TEMPERATURES = 2.0 .^ collect(-1:0.5:4)
H_MULT = 2.0

# Initialize data frame
df = DataFrame(
    :kitchen_id => Int[],
    :kitchen_name => String[],
    :problem => String[],
    :distinguish_goals => Bool[],
    :act_temperature => Float64[],
    :h_mult => Float64[],
    :timestep => Int[],
    :systime => Float64[],
    :action => String[],
    :narrative => String[],
    :log_ml_est => Float64[],
    (Symbol("goal_logprobs_$i") => Float64[] for i in 1:N_GOALS_PER_PROBLEM)...,
    (Symbol("goal_probs_$i") => Float64[] for i in 1:N_GOALS_PER_PROBLEM)...,
    :true_goal_probs => Float64[],
    :true_overlap => Float64[],
    :brier_score => Float64[],
    :runtime => Float64[]
)
df_types = eltype.(eachcol(df))
datetime = Dates.format(Dates.now(), "yyyy-mm-ddTHH-MM-SS")
df_path = "inferences_known_options_sips_$(datetime).csv"
df_path = joinpath(@__DIR__, df_path)

# Load domain
domain = load_domain(joinpath(@__DIR__, "domain.pddl"))

# Iterate over kitchen types
for (idx, kitchen_name) in collect(enumerate(KITCHEN_NAMES))
    println("== Kitchen $idx : $kitchen_name ==")

    # Iterate over problems and goals for each kitchen type
    for (problem_path, goals_path, plan_path) in zip(PROBLEMS[idx], GOALS[idx], PLANS[idx])
        println("-- Problem: $(basename(problem_path)) --")

        # Load problem and construct initial state
        problem = load_problem(problem_path)
        state = initstate(domain, problem)

        # Load the set of goals and natural language descriptions
        descriptions, goals = load_goals(goals_path)
        true_goal_idx = 1
        true_goal = goals[true_goal_idx]

        # Load plan to do inference on 
        plan, annotations, split_idxs = load_plan(plan_path)
        println()
        println("- Annotations -")
        for line in annotations
            println(line)
        end
        println()
        annotation_idx = 0

        # Pre-simplify goals
        goal_specs = [simplify_goal(Specification(g), domain, state)
                      for g in goals]
        # Add served term to each goal
        goal_specs = add_served.(goal_specs)
        # Distinguish goals through negation
        if DISTINGUISH_GOALS
            goal_specs = distinguish_recipes(goal_specs)
        end

        # Define uniform prior over possible goals
        @gen function goal_prior()
            goal_idx = {:goal} ~ uniform_discrete(1, length(goals))
            return goal_specs[goal_idx]
        end
        goal_addr = :init => :agent => :goal => :goal
        goal_strata = choiceproduct((goal_addr, 1:length(goals)))
        
        # Compile and cache domain for faster performance
        println("Compiling domain...")
        c_domain, c_state = compiled(domain, state)
        cached_methods = [:available, :infer_static_fluents, :infer_affected_fluents]
        c_domain = CachedDomain(c_domain, cached_methods)

        # Construct a nested planning heuristic
        println("Precomputing planning heuristics...")
        ff = memoized(precomputed(FFHeuristic(), domain, state)) # Base heuristic is FF
        oc_planner = OvercookedPlanner( # Overcooked planner uses FF heuristic
            planner=AStarPlanner(ff, h_mult=H_MULT),
            max_time=10.0
        )
        oc_heuristic = PlannerHeuristic(oc_planner) # Wrap planner in heuristic
        oc_heuristic = memoized(oc_heuristic) # Memoize heuristic for faster performance

        # Define agent planner as a real-time heuristic search variant
        planner = RTDP(heuristic=oc_heuristic, n_rollouts=0)

        # Iterate over temperature values
        for act_temperature in ACT_TEMPERATURES
            println("Act temperature: $act_temperature")

            # Configure agent model with domain, planner, and goal prior
            agent_config = AgentConfig(
                c_domain, planner;
                goal_config = StaticGoalConfig(goal_prior),
                act_temperature = act_temperature
            )

            # Configure world model with agent configuration, domain and initial state
            world_config = WorldConfig(
                agent_config = agent_config,
                env_config = PDDLEnvConfig(c_domain, c_state),
                obs_config = PerfectObsConfig()
            )

            # Configure SIPS particle filter
            sips = SIPS(world_config, resample_cond=:none)

            # Construct data logger callbacks
            n_goals = length(goals)
            verbose_cb = DataLoggerCallback(
                timestep = (t, pf) -> t::Int,
                goal_probs = pf -> probvec(pf, goal_addr, 1:n_goals)::Vector{Float64},
                action = (t, pf) -> t > 0 ? write_pddl(plan[t])::String : "(--)",
                verbose = true
            )
            silent_cb = DataLoggerCallback(
                log_ml_est = (t, pf) -> (get_lml_est(pf) + log(n_goals))::Float64,
                systime = pf -> time(),
                narrative = (t, pf) -> begin
                    i = findfirst(==(t), split_idxs)
                    return i === nothing ? "" : annotations[i]
                end
            )
            callback = CombinedCallback(verbose_cb, silent_cb)

            # Construct action choicemaps from plan
            act_choices = act_choicemap_pairs(plan)

            # Run a particle filter to perform online goal inference
            println("Running SIPS goal inference...\n")
            pf_state = sips(
                n_goals, act_choices;
                init_args=(init_strata=goal_strata,),
                callback=callback
            )

            # Construct dataframe from logged data
            verbose_data = verbose_cb.data
            silent_data = silent_cb.data
            goal_probs = reduce(hcat, verbose_data[:goal_probs])
            n_rows = length(verbose_data[:timestep])
            new_df = DataFrame(
                :kitchen_id => fill(idx, n_rows),
                :kitchen_name => fill(kitchen_name, n_rows),
                :problem => fill(basename(problem_path), n_rows),
                :distinguish_goals => fill(DISTINGUISH_GOALS, n_rows),
                :act_temperature => fill(act_temperature, n_rows),
                :h_mult => fill(H_MULT, n_rows),
                :timestep => verbose_data[:timestep],
                :systime => silent_data[:systime],
                :action => verbose_data[:action],
                :narrative => silent_data[:narrative],
                :log_ml_est => silent_data[:log_ml_est],
                (Symbol("goal_logprobs_$i") =>
                    log.(goal_probs[i, :]) for i in 1:n_goals)...,
                (Symbol("goal_probs_$i") =>
                    goal_probs[i, :] for i in 1:n_goals)...,
                :true_goal_probs => goal_probs[true_goal_idx, :],
            )

            # Compute semantic overlap with respect to true goal
            goal_overlaps = [recipe_overlap(true_goal, g) for g in goals]
            new_df.true_overlap = goal_probs' * goal_overlaps

            # Compute Brier score with respect to true goal
            is_true_goal = zero(goal_probs)
            is_true_goal[true_goal_idx, :] .= 1.0
            brier_score = sum((is_true_goal .- goal_probs).^2, dims=1)
            new_df.brier_score = vec(brier_score)

            # Compute runtime
            systime = silent_data[:systime]
            new_df.runtime = diff([systime[1]; systime])

            # Append dataframe
            append!(df, new_df)
            CSV.write(df_path, df)
            println()
        end
        # Manually garbarge collect to free up memory
        GC.gc()
    end
end

CSV.write(df_path, df)
