using Printf, DataFrames, CSV, Logging
using DataStructures: OrderedDict
using StatsBase
using Julog, PDDL, Gen, Plinf


PDDL.Arrays.register!()

"Path to all experiment files."
EXPERIMENTS_PATH = @__DIR__
"Number of samples/particles per goal."
SAMPLE_MULT = 10
"Number of repeats per observation."
N_REPEATS = 5
"Whether to resample."
RESAMPLE = true
"Rejuvenation move"
REJUVENATE = nothing # :mixed
"Whether to use compiled domains."
COMPILED = true

include("params.jl")
include("precompile.jl")

## Data-loading code ##

"Extract goal and trajectory indices."
function get_idx_from_fn(fn)
    m = match(r".*problem(\d+)_goal(\d+)_(\d+).*", fn)
    if m == nothing
        return parse(Int, match(r".*_goal(\d+).*", fn).captures[1])
    else
        return Tuple(parse.(Int, m.captures))
    end
end

"Load files for a problem (i.e. initial state) in a given domain."
function load_problem_files(path::String, domain_name::String, problem_idx::Int)
    # Load problem and domain
    if COMPILED
        domain = COMPILED_DOMAINS[domain_name][problem_idx]
    else
        domain_dir = joinpath(path, "domains")
        domain = load_domain(joinpath(domain_dir, "$(domain_name).pddl"))
    end
    problem_dir = joinpath(path, "problems", domain_name)
    problem_fn = filter(fn -> occursin("problem_$(problem_idx).pddl", fn),
                        readdir(problem_dir))[1]
    problem = load_problem(joinpath(problem_dir, problem_fn))
    # Load goal hypotheses
    goals = parse_pddl.(readlines(joinpath(path, "goals", domain_name,
                                           "goals_$(problem_idx).pddl")))
    return domain, problem, goals
end

"Load all observed trajectories for a given problem (i.e. initial state)."
function load_observations(obs_path::String, problem_idx::Int,
                           domain::Domain, init_state::State)
    # Load and sort plans
    filt_by_prob = fn -> occursin("problem_$(problem_idx)_", fn)
    plan_fns = filter!(filt_by_prob, readdir(obs_path))
    plan_fns = sort!(plan_fns; by=get_idx_from_fn)

    # Parse plans, produce trajectories from initial state + plans
    obs_plans = [parse_pddl.(readlines(joinpath(obs_path, fn)))
                 for fn in plan_fns]
    obs_trajs = [PDDL.simulate(domain, init_state, p) for p in obs_plans]

    return obs_plans, obs_trajs, plan_fns
end

function load_observations(path::String, domain_name::String, problem_idx::Int,
                           obs_subdir="optimal")
    domain, problem, _ = load_problem_files(path, domain_name, problem_idx)
    obs_path = joinpath(path, "observations", obs_subdir, domain_name)
    init_state = initstate(domain, problem)
    return load_observations(obs_path, problem_idx, domain, init_state)
end

## Dataset generation code ##

"Generate a dataset of observations for the given domain / problem."
function generate_observations(path, domain_name::String, problem_idx::Int,
                               optimal::Bool=false, n_obs::Int=2; subdir=nothing,
                               search_noise=0.1, persistence=(2, 0.95))
    domain, problem, goals = load_problem_files(path, domain_name, problem_idx)
    init_state, n_goals = initstate(domain, problem), length(goals)
    # Make directory for observations
    if isnothing(subdir) subdir = optimal ? "optimal" : "suboptimal" end
    obs_path = mkpath(joinpath(path, "observations", subdir, domain_name))
    # Set up planner
    heuristic = get(HEURISTICS, string(PDDL.get_name(domain)), FFHeuristic)()
    heuristic = precompute(heuristic, domain, init_state)
    if optimal # Generate optimal plans (assuming an admissible heuristic)
        planner = AStarPlanner(heuristic=heuristic)
    else # Generate non-optimal plans using a replanning model
        planner = ProbAStarPlanner(heuristic=heuristic, search_noise=search_noise)
        planner = Replanner(planner=planner, persistence=persistence)
    end
    # Generate n_obs plans for each goal
    println("Generating $n_obs plans per goal for problem $(problem_idx)...")
    for (i, goal) in enumerate(goals)
        goal = Specification(goal)
        for j in 1:n_obs
            plan, _ = planner(domain, init_state, goal)
            filter!(a -> a !=  pddl"(--)", plan) # Filter out no-ops
            plan = write_pddl.(plan) # Convert actions to PDDL strings
            # Write plan to file
            obs_fn = "$(domain_name)_problem_$(problem_idx)_goal$(i-1)_$(j-1).dat"
            open(joinpath(obs_path, obs_fn), "w") do f
                for act in plan println(f, act) end
            end
        end
    end
    return obs_path
end

"Generate a dataset of observations for the given domain / problem."
function generate_observations(path, domain_name::String, optimal::Bool=false,
                               n_obs::Int=2; kwargs...)
    # Extract problem indices
    problem_fns = filter(fn -> occursin(r"problem_(\d+).pddl", fn),
                        readdir(joinpath(path, "problems", domain_name)))
    problem_idxs = [parse(Int, match(r".*problem_(\d+).pddl", fn).captures[1])
                   for fn in problem_fns]
    # Generate observations for each problem
    println("Generating observations for $domain_name...")
    for idx in problem_idxs
        generate_observations(path, domain_name, idx, optimal, n_obs; kwargs...)
    end
end

## Modeling and inference methods ##

"Set-up goal prior, agent model, and world model."
function setup_model(domain::Domain, init_state::State, goals)
    # Construct uniform prior over goals
    n_goals = length(goals)
    @gen goal_prior() =
        Specification(goals[@trace(uniform_discrete(1, n_goals), :goal)])

    # Define observation noise model
    dname = string(PDDL.get_name(domain))
    if haskey(OBS_PARAMS, dname)
        obs_params = OBS_PARAMS[dname]
        obs_params = Plinf.ground_obs_params(obs_params, init_state, domain)
    else
        obs_params = observe_params(domain, pred_noise=0.05; state=init_state)
    end
    obs_terms = collect(keys(obs_params))

    # Configure agent planner with heuristic and noise parameters
    heuristic = get(HEURISTICS, dname, HAdd)()
    heuristic = precompute(heuristic, domain, init_state)
    planner = ProbAStarPlanner(heuristic=heuristic, search_noise=SEARCH_NOISE,
                               cache_actions=!COMPILED)
    replanner = Replanner(planner=planner, persistence=PERSISTENCE)
    agent_planner = replanner

    # Configure agent model with goal prior, planner, and action noise
    agent_init = AgentInit(agent_planner, goal_prior)
    agent_config = AgentConfig(domain, agent_planner, act_noise=ACT_NOISE)

    # Configure world model with agent, initial state, and obs params
    world_init = WorldInit(agent_init, init_state, init_state)
    world_config = WorldConfig(domain, agent_config, obs_params)

    return obs_terms, world_init, world_config
end

"Extract goal probabilities from weighted traces."
function get_goal_probs(traces, weights, goal_idxs=[])
    goal_probs = OrderedDict{Any,Float64}(g => 0.0 for g in goal_idxs)
    for (tr, w) in zip(traces, weights)
        goal_idx = tr[:init => :agent => :goal => :goal]
        prob = get(goal_probs, goal_idx, 0.0)
        goal_probs[goal_idx] = prob + exp(w)
    end
    return goal_probs
end

"Run goal inference via Plan Recognition as Planning (PRP)."
function run_prp_inference(goal_idx, traj, goals, domain, beta=1)
    # Construct new dataframe for this trajectory
    df = DataFrame()
    n_goals = length(goals)

    # Add cost metric to goal specifications if necessary
    if Symbol("total-cost") in keys(domain.functions)
        goals = [MinMetricGoal(g, pddl"total-cost") for g in goals]
    else
        goals = [MinStepsGoal(g) for g in goals]
    end

    # Set up logger and buffer to store logged messages
    log_buffer = IOBuffer() # Buffer of any logged messages
    logger = SimpleLogger(log_buffer)

    # Set up data buffers
    all_goal_probs = [] # Buffer of all goal probabilities over time
    true_goal_probs = Float64[] # Buffer of true goal probabilities
    step_times = Float64[] # Buffer of wall clock durations per step
    log_messages = String[] # Buffer of log messages for each timestep

    # Compute costs of optimal plans from initial state to each goal
    state = traj[1]
    heuristic = get(HEURISTICS, string(PDDL.get_name(domain)), HAdd)()
    heuristic = precompute(heuristic, domain, state)
    planner = AStarPlanner(heuristic=heuristic, max_nodes=1000)
    opt_costs = Vector{Float64}(undef, n_goals)
    start_time = time() # Start timing
    with_logger(logger) do
        for (i, g) in enumerate(goals)
            clear_heuristic_cache!()
            clear_action_cache!(planner)
            opt_plan, opt_traj = planner(domain, state, g)
            cost = g.metric == nothing ?
                length(opt_plan) : opt_traj[end][pddl"total-cost"]
            opt_costs[i] = cost
        end
    end

    # Iterate over timesteps
    with_logger(logger) do
        for (t, state) in enumerate(traj)
            println("Timestep $t")
            weights = ones(n_goals)
            costs = ones(n_goals)
            for (i, g) in enumerate(goals)
                if t == 1 break end
                clear_heuristic_cache!()
                clear_action_cache!(planner)
                # Compute plan cost to each goal
                part_plan, part_traj = planner(domain, state, g)
                costs[i] = g.metric == nothing ?
                    part_plan == nothing ? Inf :
                    t-1+length(part_plan) : part_traj[end][pddl"total-cost"]
                # Compute heuristic likelihood weight of the plan as cost ratio
                # weights[i] = opt_costs[i] / costs[i]
                weights[i] = exp(-beta * (costs[i] - opt_costs[i]))
            end
            # Normalize weights to get posterior
            if iszero(weights) weights = ones(n_goals) end # Handle failed plans
            goal_probs = weights ./ sum(weights)
            push!(step_times, time())
            push!(all_goal_probs, goal_probs)
            push!(true_goal_probs, goal_probs[goal_idx+1])
            push!(log_messages, String(take!(log_buffer)))
        end
    end

    # Process collected data
    all_goal_probs = reduce(hcat, all_goal_probs)'
    step_times = step_times .- start_time
    step_durs = step_times - [0; step_times[1:end-1]]
    states_visited = map(log_messages) do msg
        lines = split(msg,  r"\n|\r\n")
        count = 0
        for l in lines
            m = match(r".*Node Count: (\d+).*", l)
            if m == nothing continue end
            count += parse(Int, m.captures[1])
        end
        return count
    end

    # Add data to dataframe
    df.step_times = step_times
    df.step_durs = step_durs
    df.states_visited = states_visited
    df.true_goal_probs = true_goal_probs
    for (i, goal_probs) in enumerate(eachcol(all_goal_probs))
        df[!, "goal_probs_$(i-1)"] = goal_probs
    end

    # Return dataframe
    return df
end

"Run goal inference via Sequential Inverse Plan Serach (SIPS) on a trajectory."
function run_sips_inference(goal_idx, traj, goals, obs_terms,
                            world_init::WorldInit, world_config::WorldConfig)
    # Construct new dataframe for this trajectory
    df = DataFrame()

    # Set up logger and buffer to store logged messages
    log_buffer = IOBuffer() # Buffer of any logged messages
    logger = SimpleLogger(log_buffer)

    # Set up callback to collect data
    all_goal_probs = [] # Buffer of all goal probabilities over time
    true_goal_probs = Float64[] # Buffer of true goal probabilities
    step_times = Float64[] # Buffer of wall clock durations per step
    log_messages = String[] # Buffer of log messages for each timestep
    function data_callback(t, state, trs, ws)
        push!(step_times, time())
        # println("Timestep $t")
        goal_probs = sort!(get_goal_probs(trs, ws, collect(1:length(goals))))
        push!(all_goal_probs, Vector{Float64}(collect(values(goal_probs))))
        push!(true_goal_probs, goal_probs[goal_idx+1])
        push!(log_messages, String(take!(log_buffer)))
    end

    # Set up rejuvenation moves
    rejuv_fns = Dict(
        :goal => pf -> pf_goal_move_accept!(pf, goals),
        :replan => pf -> pf_replan_move_accept!(pf),
        :mixed => pf -> pf_mixed_move_accept!(pf, goals; mix_prob=0.50),
        nothing => nothing
    )

    # Set up action proposal
    act_proposal = ACT_NOISE > 0 ? forward_act_proposal : nothing
    act_proposal_args = (ACT_NOISE * 2,)

    # Clear available action cache
    planner = world_config.agent_config.planner
    clear_action_cache!(planner)

    # Run a particle filter to perform online goal inference
    n_goals = length(goals)
    n_samples = SAMPLE_MULT * n_goals
    goal_strata = Dict((:init => :agent => :goal => :goal) => collect(1:n_goals))
    start_time = time()
    with_logger(logger) do
        traces, weights = world_particle_filter(
            world_init, world_config, traj, obs_terms, n_samples;
            resample=RESAMPLE, rejuvenate=rejuv_fns[REJUVENATE],
            callback=data_callback, strata=goal_strata,
            act_proposal=act_proposal, act_proposal_args=act_proposal_args);
    end

    # Process collected data
    all_goal_probs = reduce(hcat, all_goal_probs)'
    step_times = step_times .- start_time
    step_durs = step_times - [0; step_times[1:end-1]]
    states_visited = map(log_messages) do msg
        lines = split(msg,  r"\n|\r\n")
        count = 0
        for l in lines
            m = match(r".*Node Count: (\d+).*", l)
            if m == nothing continue end
            count += parse(Int, m.captures[1])
        end
        return count
    end

    # Add data to dataframe
    df.step_times = step_times
    df.step_durs = step_durs
    df.states_visited = states_visited
    df.true_goal_probs = true_goal_probs
    for (i, goal_probs) in enumerate(eachcol(all_goal_probs))
        df[!, "goal_probs_$(i-1)"] = goal_probs
    end

    # Return dataframe
    return df
end

## Per-problem experiment and analysis code ##

"Test solving a problem."
function test_problem(path, domain_name, problem_idx, goal_idx=0)
    domain, problem, goals = load_problem_files(path, domain_name, problem_idx)
    goal = Specification(goals[goal_idx+1])
    state = initstate(domain, problem)
    heuristic = get(HEURISTICS, string(PDDL.get_name(domain)), HAdd)()
    heuristic = precompute(heuristic, domain, state)
    planner = AStarPlanner(heuristic=heuristic)
    replanner = Replanner(planner=planner, persistence=(2, 0.95))
    plan, traj = planner(domain, state, goal)
    return plan
end

"Run experiments for a given problem (i.e. initial state) in a domain."
function run_problem_experiments(path, domain_name, problem_idx,
                                 obs_subdir="optimal", method=:sips,
                                 n_repeats=N_REPEATS)
    # Load domain, problem, and set of goals
    domain, problem, goals = load_problem_files(path, domain_name, problem_idx)
    init_state = initstate(domain, problem)

    # Load dataset of observed trajectories for the current problem
    obs_path = joinpath(path, "observations", obs_subdir, domain_name)
    _, obs_trajs, obs_fns = load_observations(obs_path, problem_idx,
                                              domain, init_state)
    obs_names = map(fn -> match(r"(.*)\.dat", fn).captures[1], obs_fns)

    # Perform method specific setup
    if method == :sips
        obs_terms, world_init, world_config =
            setup_model(domain, init_state, goals)
    elseif method == :prp
        # error("Not implemented.")
    elseif method == :rnn
        error("Not implemented.")
    end

    # Run goal inference for each trajectory
    results_path = mkpath(joinpath(path, "results", domain_name))
    problem_dfs = DataFrame[]
    problem_names = String[]
    for (idx, (traj, name)) in enumerate(zip(obs_trajs, obs_names))
        # Get goal index from file name
        goal_idx = parse(Int, match(r".*_goal(\d+).*", name).captures[1])
        goal = goals[goal_idx+1]
        idx = idx - 1 # Reindex trajectories to start at zero
        println("Inferring goals for trajectory $idx, goal $goal_idx...")
        println("True goal: $goal")
        for i in 1:n_repeats
            println("- Trial $i -")
            # Clear cached values
            clear_heuristic_cache!()
            # Run inference method
            if method == :sips
                df = run_sips_inference(goal_idx, traj, goals, obs_terms,
                                        world_init, world_config)
            elseif method == :prp
                df = run_prp_inference(goal_idx, traj, goals, domain)
            elseif method == :rnn
               error("Not implemented.")
            end
            # Save dataframe
            push!(problem_dfs, df)
            trial_name = name * "_trial_$i"
            push!(problem_names, trial_name)
            df_fn = trial_name * ".csv"
            df_path = joinpath(results_path, df_fn)
            println("Writing results to $df_fn...")
            CSV.write(df_path, df)
        end
   end

   # Summarize and save results
   summary_df = analyze_problem_results(problem_dfs, problem_names)
   df_fn = "$(domain_name)_problem_$(problem_idx)_summary.csv"
   df_path = joinpath(path, "results", domain_name, df_fn)
   println("Writing summary results to $df_fn...")
   CSV.write(df_path, summary_df)

   return problem_dfs, summary_df
end

"Load problem results for a given domain and index."
function load_problem_results(path, domain_name, problem_idx)
    results_path = joinpath(path, "results", domain_name)
    filt_by_prob = fn -> occursin("problem_$(problem_idx)_goal", fn)
    df_fns = filter!(filt_by_prob, readdir(results_path))
    df_fns = sort!(df_fns; by=get_idx_from_fn)
    df_paths = joinpath.(results_path, df_fns)
    problem_dfs = DataFrame.(CSV.File.(df_paths))
    return problem_dfs
end

"Load problem names for a given domain and index."
function load_problem_names(path, domain_name, problem_idx)
    results_path = joinpath(path, "results", domain_name)
    filt_by_prob = fn -> occursin("problem_$(problem_idx)_goal", fn)
    df_fns = filter!(filt_by_prob, readdir(results_path))
    df_fns = sort!(df_fns; by=get_idx_from_fn)
    df_names = map(fn -> match(r"(.*)\.csv", fn).captures[1], df_fns)
    return df_names
end

"Compute summary statistics for a particular problem."
function analyze_problem_results(problem_dfs::Vector{DataFrame},
                                 obs_names=nothing)
    summary_df = DataFrame(
        obs_name = String[],
        problem_idx = Union{Int,Missing}[],
        goal_idx = Union{Int,Missing}[],
        q1_true_goal_prob = Float64[],
        mid_true_goal_prob = Float64[],
        q3_true_goal_prob = Float64[],
        end_true_goal_prob = Float64[],
        q1_is_top_ranked = Bool[],
        mid_is_top_ranked = Bool[],
        q3_is_top_ranked = Bool[],
        end_is_top_ranked = Bool[],
        total_states_visited = Int[],
        initial_states_visited = Int[],
        marginal_states_visited = Float64[],
        average_states_visited = Float64[],
        total_dur = Float64[],
        initial_dur = Float64[],
        marginal_dur = Float64[],
        average_dur = Float64[]
    )
    for (i, df) in enumerate(problem_dfs)
        if obs_names !== nothing
            obs_name = obs_names[i]
            problem_idx =
                parse(Int, match(r".*problem_(\d+)_.*", obs_name).captures[1])
            goal_idx =
                parse(Int, match(r".*_goal(\d+).*", obs_name).captures[1])
        else
            obs_name = ""
            problem_idx = missing
            goal_idx = missing
        end

        n_goals = parse(Int, match(r".*_(\d+)", names(df)[end]).captures[1]) + 1
        q1 = Int(floor(size(df, 1) * 1/4))
        mid = (size(df, 1) + 1) ÷ 2
        q3 = Int(floor(size(df, 1) * 3/4))

        q1_true_goal_prob = df.true_goal_probs[q1]
        mid_true_goal_prob = df.true_goal_probs[mid]
        q3_true_goal_prob = df.true_goal_probs[q3]
        end_true_goal_prob = df.true_goal_probs[end]
        q1_is_top_ranked = q1_true_goal_prob >=
            maximum(df[q1, ["goal_probs_$i" for i in 0:(n_goals-1)]])
        mid_is_top_ranked = mid_true_goal_prob >=
            maximum(df[mid, ["goal_probs_$i" for i in 0:(n_goals-1)]])
        q3_is_top_ranked = q3_true_goal_prob >=
            maximum(df[q3, ["goal_probs_$i" for i in 0:(n_goals-1)]])
        end_is_top_ranked = end_true_goal_prob >=
            maximum(df[end, ["goal_probs_$i" for i in 0:(n_goals-1)]])

        total_states_visited = sum(df.states_visited)
        initial_states_visited = df.states_visited[1]
        marginal_states_visited =
            (total_states_visited - initial_states_visited) / (size(df, 1) - 1)
        average_states_visited = total_states_visited / size(df, 1)

        total_dur = sum(df.step_durs)
        initial_dur = df.step_durs[1]
        marginal_dur = (total_dur - initial_dur) / (size(df, 1) - 1)
        average_dur = total_dur / size(df, 1)

        push!(summary_df,
            [obs_name, problem_idx, goal_idx,
             q1_true_goal_prob, mid_true_goal_prob,
             q3_true_goal_prob, end_true_goal_prob,
             q1_is_top_ranked, mid_is_top_ranked,
             q3_is_top_ranked, end_is_top_ranked,
             total_states_visited, initial_states_visited,
             marginal_states_visited, average_states_visited,
             total_dur, initial_dur, marginal_dur, average_dur])
    end
    return summary_df
end

function analyze_problem_results(path, domain_name, problem_idx, save=false)
    dfs = load_problem_results(path, domain_name, problem_idx)
    names = load_problem_names(path, domain_name, problem_idx)
    summary_df = analyze_problem_results(dfs, names)
    if save
        summary_fn = "$(domain_name)_problem_$(problem_idx)_summary.csv"
        summary_path = joinpath(path, "results", domain_name, summary_fn)
        println("Writing summary results to $summary_fn...")
        CSV.write(summary_path, summary_df)
    end
    return summary_df
end

## Per-domain experiment and analysis code ##

"Run all experiments for a domain."
function run_domain_experiments(path, domain_name, obs_subdir="optimal",
                                method=:sips, n_repeats=N_REPEATS)
    # Extract problem indices
    problem_fns = filter(fn -> occursin(r"problem_(\d+).pddl", fn),
                         readdir(joinpath(path, "problems", domain_name)))
    problem_idxs = [parse(Int, match(r".*problem_(\d+).pddl", fn).captures[1])
                    for fn in problem_fns]

    # Run experiments for each problem
    summary_df = DataFrame()
    for idx in problem_idxs
        println("Running experiments for problem $idx...")
        dfs, s_df = run_problem_experiments(path, domain_name, idx,
                                            obs_subdir, method, n_repeats)
        append!(summary_df, s_df)
    end

    # Write combined results to file
    df_fn = "$(domain_name)_all_problems.csv"
    df_path = joinpath(path, "results", domain_name, df_fn)
    println("Writing combined problem results to $df_fn...")
    CSV.write(df_path, summary_df)

    # Compute and save summary statistics
    summary_stats = analyze_domain_results(summary_df)
    df_fn = "$(domain_name)_summary.csv"
    df_path = joinpath(path, "results", domain_name, df_fn)
    println("Writing domain summary results to $df_fn...")
    CSV.write(df_path, summary_stats)

    return summary_df, summary_stats
end

"Load experimental results for a given domain."
function load_domain_results(path, domain_name)
    problem_fns = filter(fn -> occursin(r"problem_(\d+)_.*\.csv", fn),
                         readdir(joinpath(path, "results", domain_name)))
    problem_idxs = [parse(Int, match(r".*problem_(\d+)_.*", fn).captures[1])
                    for fn in problem_fns]
    sort!(unique!(problem_idxs))
    domain_dfs = load_problem_results.(path, domain_name, problem_idxs)
    obs_names = load_problem_names.(path, domain_name, problem_idxs)
    return domain_dfs, obs_names
end

"Compute summary statistics for a given domain."
function analyze_domain_results(summary_df::DataFrame, n_repeats=N_REPEATS)
    summary_df = summary_df[!, Not([:obs_name, :problem_idx, :goal_idx])]
    mean_dfs = DataFrame[]
    for i in 1:n_repeats
        df = permutedims(describe(summary_df[i:n_repeats:end,1:end], :mean), 1)
        push!(mean_dfs, df[!,2:end])
    end
    mean_df = reduce(vcat, mean_dfs)
    compute_se(v) = std(v) / sqrt(length(v))
    compute_ci(v) = compute_se(v) * 1.96
    return describe(mean_df, :mean, :std, compute_se => :se, compute_ci => :ci)
end

"Compute summary statistics for a given domain."
function analyze_domain_results(path, domain_name,
                                save=false, n_repeats=N_REPEATS)
    domain_dfs, obs_names = load_domain_results(path, domain_name)
    summary_df = reduce(vcat, analyze_problem_results.(domain_dfs, obs_names))
    stats_df = analyze_domain_results(summary_df, n_repeats)
    if save
        df_fn = "$(domain_name)_all_problems.csv"
        df_path = joinpath(path, "results", domain_name, df_fn)
        println("Writing combined problem results to $df_fn...")
        CSV.write(df_path, summary_df)

        stats_fn = "$(domain_name)_summary.csv"
        stats_path = joinpath(path, "results", domain_name, stats_fn)
        println("Writing domain summary results to $stats_fn...")
        CSV.write(stats_path, stats_df)
    end
    return stats_df
end
