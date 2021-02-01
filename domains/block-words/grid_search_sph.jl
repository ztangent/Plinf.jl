using Julog, PDDL, Gen, Printf
using Plinf, CSV
using DataFrames
using Statistics
using JSON

include("render.jl")
include("utils.jl")
include("./new-scenarios/experiment-scenarios.jl")


#--- Generate Search Grid ---#
model_name = "sph"
beta_ = [0.1, 0.5, 0.9, 1.5, 3]
grid_list = Iterators.product(beta_)
grid_dict = []
for item in grid_list
    current_dict = Dict()
    current_dict["beta"] = item[1]
    push!(grid_dict, current_dict)
end
corrolation = []

#--- Initial Setup ---#

# Specify problem
category = "1"
subcategory = "1"
experiment = "scenario-" * category * "-" * subcategory
problem_name = experiment * ".pddl"
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "block-words")

# Load human data
file_name = category * "_" * subcategory * ".csv"
human_data = vec(CSV.read(joinpath(path, "human_results_arrays", file_name), datarow=1, Tables.matrix))

# Load domain, problem, actions, and goal space
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "new-scenarios", problem_name))
actions = get_action(category * "-" * subcategory)
goal_words = get_goal_space(category * "-" * subcategory)
goals = word_to_terms.(goal_words)

# Initialize state
state = initialize(problem)
goal = problem.goal


# Execute list of actions and generate intermediate states
function execute_plan(state, domain, actions)
    states = State[]
    push!(states, state)
    for action in actions
        action = parse_pddl(action)
        state = execute(action, state, domain)
        push!(states, state)
    end
    return states
end
traj = execute_plan(state, domain, actions)

#-- Shortest path heuristic inference --#

"Run goal inference via shortest-path heuristic."
function run_sph_inference(traj::Vector{State}, goals, domain::Domain;
                           beta::Real=1, verbose::Bool=true)
    # Construct new dataframe for this trajectory
    n_goals = length(goals)
    goals = [GoalSpec(g) for g in goals]
    all_goal_probs = [] # Buffer of all goal probabilities over time

    # Compute costs of optimal plans from initial state to each goal
    state = traj[1]
    heuristic = precompute(FFHeuristic(), domain) # Change to GemMazeDist for DKG
    planner = AStarPlanner(heuristic=heuristic, max_nodes=1000)

    # Iterate over timesteps
    if verbose println("Goal probs.:") end
    for (t, state) in enumerate(traj)
        weights = ones(n_goals)
        costs = ones(n_goals)
        for (i, g) in enumerate(goals)
            if t == 1 break end
            # Compute plan cost to each goal
            part_plan, part_traj = planner(domain, state, g)
            costs[i] = part_plan == nothing ? Inf : length(part_plan)
            # Compute heuristic likelihood weight of the plan as cost ratio
            weights[i] = exp(-beta * costs[i])
        end
        # Normalize weights to get posterior
        if iszero(weights) weights = ones(n_goals) end # Handle failed plans
        goal_probs = weights ./ sum(weights)
        if verbose
            for prob in goal_probs @printf("%.3f\t", prob) end
            print("\n")
        end
        push!(all_goal_probs, goal_probs)
    end
    return all_goal_probs
end

for (i, params) in enumerate(grid_dict)
    total = size(grid_dict)[1]
    goal_probs = run_sph_inference(traj, goals, domain; beta = params["beta"])
    flattened_array = collect(Iterators.flatten(goal_probs[1:2:end]))
    push!(corrolation, cor(flattened_array, human_data))
    print("Parameters Set " * string(i) * " / " * string(total) * " done \n")
end

#--- Save Best Parameters ---#
mxval, mxindx = findmax(corrolation)
best_params = grid_dict[mxindx]
best_params["corr"] = mxval
json_data = JSON.json(best_params)
json_file = joinpath(path, model_name, "best_params", experiment*".json")
open(json_file, "w") do f
    JSON.print(f, json_data)
end


#--- Generate Results ---#
number_of_trials = 1
for i in 1:number_of_trials
    goal_probs = run_sph_inference(traj, goals, domain; beta = best_params["beta"])
    df = DataFrame(Timestep=collect(1:length(traj)), Probs=goal_probs)
    CSV.write(joinpath(path, model_name, category * "_" * subcategory, string(i)*".csv"), df)
end
