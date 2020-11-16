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
problem_name = "experiment-2.pddl"
actions = ["(unstack p r)", "(put-down p)", "(unstack c e)",
        "(stack c p)", "(pick-up e)", "(stack e r)",
        "(pick-up o)", "(stack o e)", "(pick-up w)",
        "(stack w o)", "(unstack c p)", "(stack c w)",
        "(unstack c w)", "(put-down c)", "(unstack w o)",
        "(put-down w)", "(unstack o e)", "(put-down o)",
        "(pick-up w)", "(stack w e)", "(pick-up o)",
        "(stack o w)", "(pick-up c)",
        "(stack c o)"] #list of strings

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "block-words")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, problem_name))

# Initialize problem and visualize initial state
state = initialize(problem)
goal = problem.goal
plt = render(state)

# Execute list of actions and generate intermediate states
function execute_plan(state, domain, actions)
    states = State[]
    push!(states, state)
    for action in actions
        print(action)
        action = parse_pddl(action)
        state = execute(action, state, domain)
        push!(states, state)
    end
    return states
end



traj_s = execute_plan(state, domain, actions)
anim = anim_traj(traj_s)


gif(anim, "domains/block-words/experiments-gifs/experiment-2.gif", fps=30)
