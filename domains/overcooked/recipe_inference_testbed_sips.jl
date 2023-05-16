using Base: @kwdef
using Printf
using DataStructures: OrderedDict
using PDDL, SymbolicPlanners
using PDDLViz, GLMakie
using Gen, GenParticleFilters
using Plinf

using SymbolicPlanners: simplify_goal
using GenParticleFilters: softmax

include("recipe_inference_utils.jl")

# Load domain, problem, and goals

include("load_goals.jl")
include("load_plan.jl")
include("planner.jl")

DOMAIN_DIR = @__DIR__
PROBLEM_DIR = joinpath(@__DIR__, "problems")
GOALS_DIR = joinpath(@__DIR__, "goals")
PLANS_DIR = joinpath(@__DIR__, "plans")

# Load PDDL domain and problem
domain = load_domain(joinpath(DOMAIN_DIR, "domain.pddl"))
problem_path = joinpath(PROBLEM_DIR, "problem-1-3.pddl")
problem = load_problem(problem_path)

# Initialize state
state = initstate(domain, problem)

## Inference over a known set of goals ##

# Load possible goals
descriptions, goals = load_goals(joinpath(GOALS_DIR, "goals-1-3.pddl"))
true_goal = goals[1]
true_goal_spec = Specification(true_goal)

# Pre-simplify goals
goal_specs = [simplify_goal(Specification(g), domain, state) for g in goals]

# Add served term to each goal, and distinguish the recipes
goal_specs = add_served.(goal_specs)
goal_specs = distinguish_recipes(goal_specs)

# Define uniform prior over possible goals
@gen function goal_prior()
    goal_idx = {:goal} ~ uniform_discrete(1, length(goals))
    return goal_specs[goal_idx]
end
goal_addr = :init => :agent => :goal => :goal
goal_strata = choiceproduct((goal_addr, 1:length(goals)))

# Compile and cache domain for faster performance
domain, state = compiled(domain, state)
cached_methods = [:available, :infer_static_fluents, :infer_affected_fluents]
domain = CachedDomain(domain, cached_methods)

# Construct a nested planning heuristic
ff = memoized(precomputed(FFHeuristic(), domain, state)) # Base heuristic is FF
oc_planner = OvercookedPlanner( # Overcooked planner uses FF heuristic
    planner=AStarPlanner(ff, h_mult=2.0),
    max_time=10.0,
)
oc_heuristic = PlannerHeuristic(oc_planner) # Wrap planner in heuristic
oc_heuristic = memoized(oc_heuristic) # Memoize heuristic for faster performance

# Define agent planner as a real-time heuristic search variant
planner = RTDP(heuristic=oc_heuristic, n_rollouts=0)

# Configure agent model with domain, planner, and goal prior
agent_config = AgentConfig(
    domain, planner;
    goal_config = StaticGoalConfig(goal_prior), # Assume fixed goal over time
    act_temperature = 8.0 # Assume Boltzmann action noise
)

# Configure world model with agent configuration, domain and initial state
world_config = WorldConfig(
    agent_config = agent_config,
    env_config = PDDLEnvConfig(domain, state),
    obs_config = PerfectObsConfig()
)

# Configure SIPS particle filter
sips = SIPS(world_config, resample_cond=:none)

# Load plan to do inference on 
plan, annotations, split_idxs =
    load_plan(joinpath(PLANS_DIR, "problem-1-3", "narrative-plan-1-3-1.pddl"))
act_choices = act_choicemap_pairs(plan)

# Construct data logger callback
n_goals = length(goals)
logger_cb = DataLoggerCallback(
    t = (t, pf) -> t::Int,
    goal_probs = pf -> probvec(pf, goal_addr, 1:n_goals)::Vector{Float64},
    action = (t, pf) -> t > 0 ? write_pddl(plan[t])::String : "(--)",
    systime = pf -> time(),
    narrative = (t, pf) -> begin
        i = findfirst(==(t), split_idxs)
        return i === nothing ? "" : annotations[i]
    end,
    verbose = true
)

# Construct plot callback
figure = Figure(resolution=(900, 450))
goal_colors = PDDLViz.colorschemes[:vibrant][1:n_goals];
goal_lines_cb = SeriesPlotCallback(
    figure,
    logger_cb, :goal_probs, # Look up :goal_probs variable
    ps -> reduce(hcat, ps); # Convert vectors to matrix for plotting
    color = goal_colors,
    axis = (xlabel="Time", ylabel = "Probability",
            limits=((1, nothing), (0, 1)))
)

callback = CombinedCallback(logger_cb, goal_lines_cb, sleep=0.0)

# Run a particle filter to perform online goal inference
n_samples = 5
pf_state = sips(
    n_samples, act_choices;
    init_args=(init_strata=goal_strata,),
    callback=callback
)

data = logger_cb.data

## Inference over an unknown set of goals ##

include("goal_prior_baseline.jl")
include("goal_prior_gpt3.jl")
include("recipe_writing.jl")

# Define state-dependent baseline prior over possible goals
@gen function baseline_prior(state::State)
    recipe = {*} ~ initial_state_recipe_prior(state)
    return add_served(Specification(recipe))
end
goal_addr = :init => :agent => :goal
baseline_goal_config = StaticGoalConfig(baseline_prior, true)
baseline_init_strata = nothing

# Define LLM prior over possible goals
include_description = true
orig_domain = PDDL.get_source(PDDL.get_source(domain))
@gen function gpt3_goal_prior()
    recipe = {*} ~ gpt3_stratified_recipe_prior(orig_domain, problem_path, include_description)
    return add_served(Specification(recipe))
end
gpt3_goal_config = StaticGoalConfig(gpt3_goal_prior, false)
gpt3_recipe_addr = :init => :agent => :goal => :recipe_id
gpt3_init_strata = choiceproduct((gpt3_recipe_addr, 1:200))

# Sample from GPT3 prior to pre-cache recipes
test_recipe = gpt3_goal_prior()

# Select between baseline and GPT-3 goal priors
goal_config = baseline_goal_config
init_strata = baseline_init_strata

# Construct a nested planning heuristic
ff = memoized(precomputed(FFHeuristic(), domain, state)) # Base heuristic is FF
oc_planner = OvercookedPlanner( # Overcooked planner uses FF heuristic
    planner=AStarPlanner(ff, h_mult=2.0),
    max_time=10.0,
)
oc_heuristic = PlannerHeuristic(oc_planner) # Wrap planner in heuristic
oc_heuristic = memoized(oc_heuristic) # Memoize heuristic for faster performance

# Define agent planner as a real-time heuristic search variant
planner = RTDP(heuristic=oc_heuristic, n_rollouts=0)

# Configure agent model with domain, planner, and goal prior
agent_config = AgentConfig(
    domain, planner;
    goal_config = goal_config,
    act_temperature = 4.0 # Assume Boltzmann action noise
)

# Configure world model with agent configuration, domain and initial state
world_config = WorldConfig(
    agent_config = agent_config,
    env_config = PDDLEnvConfig(domain, state),
    obs_config = PerfectObsConfig()
)

# Configure SIPS particle filter
sips = SIPS(world_config, resample_cond=:none)

# Load plan to do inference on 
plan, annotations, split_idxs =
    load_plan(joinpath(PLANS_DIR, "problem-1-3", "narrative-plan-1-3-1.pddl"))
act_choices = act_choicemap_pairs(plan)

# Construct data logger callbacks
logger_cb = DataLoggerCallback(
    t = (t, pf) -> t::Int,
    true_goal_probs =
        pf -> mean(g -> recipe_overlap(true_goal, g) >= 1.0, pf, goal_addr)::Float64,
    true_overlap =
        pf -> mean(g -> recipe_overlap(true_goal, g), pf, goal_addr)::Float64,
    action =
        (t, pf) -> t > 0 ? write_pddl(plan[t])::String : "(--)",
    narrative = (t, pf) -> begin
        i = findfirst(==(t), split_idxs)
        return i === nothing ? "" : annotations[i]
    end,
    verbose = true
)

silent_logger_cb = DataLoggerCallback(
    systime = pf -> time(),
    term_counts = recipe_term_counts_cb,
)

figure = Figure(resolution=(900, 600))
true_probs_lines_cb = SeriesPlotCallback(
    figure[1, 1],
    logger_cb, :true_goal_probs, # Look up :true_goal_probs variable
    vals -> permutedims(copy(vals)), # Convert vector to matrix for plotting
    axis = (xlabel="Time", ylabel = "Probability of True Goal",
            limits=((1, nothing), (0, 1)))
)
overlap_lines_cb = SeriesPlotCallback(
    figure[2, 1],
    logger_cb, :true_overlap, # Look up :true_overlap variable
    vals -> permutedims(copy(vals)), # Convert vector to matrix for plotting
    axis = (xlabel="Time", ylabel = "Overlap with True Goal",
            limits=((1, nothing), (0, 1)))
)

callback = CombinedCallback(
    logger_cb, silent_logger_cb,
    true_probs_lines_cb, overlap_lines_cb, sleep=0.05
)

# Run a particle filter to perform online goal inference
empty!(logger_cb)
empty!(silent_logger_cb)
n_samples = 200
pf_state = sips(
    n_samples, act_choices;
    init_args = (init_strata = init_strata,),
    callback=callback
)
