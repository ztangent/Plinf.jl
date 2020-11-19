# Actions Discription:
    # (unstack a b) pick up block a from top of block b
    # Preconditions: block a must be on top of b; block a must be clear; hand must be empty

    # (pick-up a) pick up a block form the table
    # Preconditions: block a must be on the table; block must be clear; hand mus be empty

    # (put-down a) put block a on the table
    # Preconditions: block a must already held (picked-up or unstacked)

    # (stack a b) put block a on top of block b
    # Preconditions: block a must be already held; block b must be clear;

using Julog, PDDL, Gen, Printf
using Plinf

include("render.jl")
include("utils.jl")


# Specify problem name and your list of actions
experiment_number = "4"
experiment_problem = "b2"
problem_name = "experiment-" * experiment_number * experiment_problem * ".pddl"

actions = ["(unstack a w)", "(stack a r)", "(unstack e p)",
        "(stack e a)", "(pick-up w)", "(stack w e)"]

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "block-words")
save_image_path = joinpath(path, "experiments-frames")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, problem_name))

# Initialize problem and visualize initial state
state = initialize(problem)
goal = problem.goal
plt = render(state)

# Execute list of actions and generate intermediate states
function execute_plan(state, domain, actions)
    states = State[]
    timestep = 0
    push!(states, state)
    png(render(state), joinpath(save_image_path, experiment_number,
                                experiment_problem, string(timestep)))
    for action in actions
        print(action)
        action = parse_pddl(action)
        state = execute(action, state, domain)
        timestep += 1
        png(render(state), joinpath(save_image_path, experiment_number,
                                    experiment_problem, string(timestep)))
        push!(states, state)
    end
    return states
end


traj_s = execute_plan(state, domain, actions)
anim = anim_traj(traj_s)

gif(anim, "domains/block-words/experiments-gifs/experiment-" *
            experiment_number * experiment_problem * ".gif", fps=30)
