using Julog, PDDL, Gen, Printf
using Plinf, CSV
using DataFrames
using Statistics
using JSON

include("render.jl")
include("utils.jl")

#--- Generate Search Grid ---#
model = "birl"
action_noise = [0.125, 0.25, 0.5, 1, 2, 4]
grid_list = Iterators.product(action_noise)
grid_dict = []
for item in grid_list
    current_dict = Dict()
    current_dict["action_noise"] = item[1]
    push!(grid_dict, current_dict)
end


#--- Initial Setup ---#

# Specify problem
category = "1"
subcategory = "1"
corrolation = []
experiment = "scenario-" * category * "-" * subcategory
problem_name = experiment * ".pddl"
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "doors-keys-gems")

# Load human data
file_name = category * "_" * subcategory * ".csv"
human_data = vec(CSV.read(joinpath(path, "human_results_arrays", file_name), datarow=1, Tables.matrix))


# Load domain, problem, actions, and goal space
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "new-scenarios", problem_name))
file_name = category * "_" * subcategory * ".dat"
actions = readlines(joinpath(path, "new-scenarios", "actions" ,file_name))
goals = @julog  [has(gem1), has(gem2), has(gem3)] 

goal_colors = [colorant"#D41159", colorant"#FFC20A", colorant"#1A85FF"]
gem_terms = @julog [gem1, gem2, gem3]
gem_colors = Dict(zip(gem_terms, goal_colors))

# Initialize state
state = initialize(problem)
start_pos = (state[:xpos], state[:ypos])
goal = [problem.goal]


#-- Bayesian IRL inference --#

function generate_init_states(state::State, domain::Domain, goals, k=5)
    ff = precompute(GemMazeDist(), domain)
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
    init_states = [generate_init_states(state, domain, goals);
                   PDDL.simulate(domain, state, plan)]
    # Solve MDP for each goal via real-time dynamic programming
    h = precompute(GemMazeDist(), domain) # Change to GemMazeDist for DKG
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

for (i, params) in enumerate(grid_dict)
    plan = parse_pddl.(actions)
    total = size(grid_dict)[1]
    goal_probs = run_birl_inference(state, plan, goals, domain, act_noise=params["action_noise"], verbose=true)
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
number_of_trials = 5
csv_path = path * "/" * model_name * "/" * category * "_" * subcategory
mkpath(csv_path)

for i in 1:number_of_trials
    plan = parse_pddl.(actions)
    total = size(grid_dict)[1]
    goal_probs = run_birl_inference(state, plan, goals, domain, act_noise=best_params["action_noise"])
    df = DataFrame(Timestep=collect(1:length(traj)), Probs=goal_probs)
    CSV.write(joinpath(path, model_name, category * "_" * subcategory, string(i)*".csv"), df)
end
