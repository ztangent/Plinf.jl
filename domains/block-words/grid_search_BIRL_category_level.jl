using Julog, PDDL, Gen, Printf
using Plinf, CSV
using DataFrames
using Statistics
using JSON

include("render.jl")
include("utils.jl")
include("./new-scenarios/experiment-scenarios.jl")
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "block-words")
domain = load_domain(joinpath(path, "domain.pddl"))

#--- Generate Search Grid ---#
model_name = "birl"
action_noise = [0.125, 0.25, 0.5, 1, 2, 4]
grid_list = Iterators.product(action_noise)
grid_dict = []
for item in grid_list
    current_dict = Dict()
    current_dict["action_noise"] = item[1]
    push!(grid_dict, current_dict)
end

#--- Bayesian IRL inference ---#

function generate_init_states(state::State, domain::Domain, k=5)
    ff = precompute(FFHeuristic(), domain)
    prob_astar = ProbAStarPlanner(heuristic=ff, search_noise=0.1)
    replanner = Replanner(planner=prob_astar, persistence=(2, 0.95))
    optimal_trajs =
        reduce(vcat, (prob_astar(domain, state, g)[2] for g in goals))
    suboptimal_trajs =
        reduce(vcat, (replanner(domain, state, g)[2]
                      for g in goals for i in 1:k))
    return [optimal_trajs; suboptimal_trajs]
end

function run_birl_inference(state::State, plan::Vector{<:Term},
                            goals, domain::Domain;
                            act_noise::Real=0.1, verbose::Bool=true)
    # Generate set of initial states to sample from
    init_states = [generate_init_states(state, domain);
                   PDDL.simulate(domain, state, plan)]
    # Solve MDP for each goal via real-time dynamic programming
    h = precompute(FFHeuristic(), domain) # Change to GemMazeDist for DKG
    planners =  [RTDPlanner(heuristic=h, act_noise=act_noise, rollout_len=5,
                            n_rollouts=length(init_states)*10) for g in goals]
    for (planner, goal) in zip(planners, goals)
        if verbose println("Solving for $goal...") end
        Plinf.solve!(planner, domain, init_states, GoalSpec(goal))
    end
    # Iterate across plan and compute goal probabilities
    goal_probs = fill(1.0/length(goals), length(goals))
    all_goal_probs = [goal_probs]
    if verbose println("Goal probs.:") end
    for act in plan
        # For each goal, compute likelihood of act given current state
        step_probs = map(zip(planners, goals)) do (planner, goal)
            goal_spec = GoalSpec(goal)
            qs = get!(planner.qvals, hash(state),
                      Plinf.default_qvals(planner, domain, state, goal_spec))
            act_probs = Plinf.softmax(values(qs) ./ planner.act_noise)
            act_probs = Dict(zip(keys(qs), act_probs))
            return act_probs[act]
        end
        # Compute filtering distribution over goals
        goal_probs = goal_probs .* step_probs
        goal_probs ./= sum(goal_probs)
        if verbose
            for prob in goal_probs @printf("%.3f\t", prob) end
            print("\n")
        end
        # Advance to next state
        state = transition(domain, state, act)
        push!(all_goal_probs, goal_probs)
    end
    return all_goal_probs
end


#--- Search ---#

category = "1"
mkpath(joinpath(path, model_name, "category_"*category))

# Load human data
human_data = []
for scenario in 1:4
    scenario = string(scenario)
    file_name = category * "_" * scenario * ".csv"
    temp = vec(CSV.read(joinpath(path, "human_results_arrays", file_name), datarow=1, Tables.matrix))
    append!(human_data, temp)
end

# Search parameters
best_R = -10
corrolation = []
for (i, params) in enumerate(grid_dict)
    model_data = []
    for scenario in 1:4

        #--- Initial Setup ---#
        # Specify problem
        scenario = string(scenario)
        experiment = "scenario-" * category * "-" * scenario
        problem_name = experiment * ".pddl"

        # Load domain, problem, actions, and goal space
        problem = load_problem(joinpath(path, "new-scenarios", problem_name))
        actions = get_action(category * "-" * subcategory)
        goal_words = get_goal_space(category * "-" * subcategory)
        goals = word_to_terms.(goal_words)

        # Initialize state
        state = initialize(problem)
        goal = problem.goal

        plan = parse_pddl.(actions)
        total = size(grid_dict)[1]
        goal_probs = run_birl_inference(state, plan, goals, domain, act_noise=params["action_noise"])
        flattened_array = collect(Iterators.flatten(goal_probs[1:2:end]))
        append!(model_data, flattened_array)
    end

    R = cor(model_data, human_data)
    if R > best_R
        best_R = R
        best_params = params
    end

    # #--- Save Parameters ---#
    params["corr"] = R
    json_data = JSON.json(params)
    json_file = joinpath(path, model_name, "category_"*category, "parameter_set_"*string(i)*".json")
    open(json_file, "w") do f
        JSON.print(f, json_data)
    end

    #--- Save Best Parameters ---#
    best_params["corr"] = best_R
    json_data = JSON.json(best_params)
    json_file = joinpath(path, model_name, "category_"*category, "best_params.json")
    open(json_file, "w") do f
        JSON.print(f, json_data)
    end

    print("Parameters Set " * string(i) * " / " * string(total) * " done \n")
end


#--- Generate Results ---#

best_params = Dict()
open(joinpath(path, model_name, "category_"*category, "best_params.json"), "r") do f
    string_dict = read(f,String) # file information to string
    string_dict=JSON.parse(string_dict)  # parse and transform data
    best_params=JSON.parse(string_dict)
end

number_of_trials = 5
mkpath(joinpath(path, model_name*"_category_level"))
for scenario in 1:4
    #--- Initial Setup ---#
    # Specify problem
    scenario = string(scenario)
    experiment = "scenario-" * category * "-" * scenario
    problem_name = experiment * ".pddl"

    # Load domain, problem, actions, and goal space
    problem = load_problem(joinpath(path, "new-scenarios", problem_name))
    actions = get_action(category * "-" * subcategory)
    goal_words = get_goal_space(category * "-" * subcategory)
    goals = word_to_terms.(goal_words)

    # Initialize state
    state = initialize(problem)
    goal = problem.goal
    plan = parse_pddl.(actions)

    # Generate results
    for i in 1:number_of_trials:
        goal_probs = run_birl_inference(state, plan, goals, domain, act_noise=best_params["action_noise"])
        df = DataFrame(Timestep=collect(1:length(traj)), Probs=goal_probs)
        CSV.write(joinpath(path, model_name, category * "_" * subcategory, string(i)*".csv"), df)
    end
end
