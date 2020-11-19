# Actions Discription:
    # (unstack a b) pick up block a from top of block b
    # Preconditions: block a must be on top of b; block a must be clear; hand must be empty

    # (pick-up a) pick up a block form the table
    # Preconditions: block a must be on the table; block must be clear; hand mus be empty

    # (put-down a) put block a on the table
    # Preconditions: block a must already held (picked-up or unstacked)

    # (stack a b) put block a on top of block b
    # Preconditions: block a must be already held; block b must be clear;

using Julog, PDDL, Gen, Printf, JSON
using Plinf

include("render.jl")
include("utils.jl")
include("experiment-scenarios.jl")

# Specify problem name
category = "3"
subcategory = "d"
experiment = "experiment-" * category * subcategory
problem_name =  experiment * ".pddl"

actions = get_action(category * subcategory)

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "block-words")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, problem_name))

save_image_path = joinpath(path, "experiments-frames", category, subcategory)

# Initialize problem and visualize initial state
state = initialize(problem)
goal = problem.goal
plt = render(state)

# Initialize items for json file
json_dict =  Dict()
json_dict["goal"] = goal
json_dict["actions"] = actions

# Execute list of actions and generate intermediate states
function execute_plan(state, domain, actions)
    states = State[]
    timestep = 0
    push!(states, state)

    json_dict[string(timestep)] = state
    png(render(state), joinpath(save_image_path, string(timestep)))

    for action in actions
        print(action)
        action = parse_pddl(action)
        state = execute(action, state, domain)
        timestep += 1
        json_dict[string(timestep)] = state
        png(render(state), joinpath(save_image_path, string(timestep)))
        push!(states, state)
    end
    return states
end


traj_s = execute_plan(state, domain, actions)
anim = anim_traj(traj_s)

json_data = JSON.json(json_dict)
json_file = joinpath(save_image_path, experiment * ".json")
open(json_file, "w") do f
    JSON.print(f, json_data)
end

gif(anim, joinpath(save_image_path, experiment * ".gif"), fps=30)
