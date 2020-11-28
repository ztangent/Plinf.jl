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
category = "0"
subcategory = "4"
experiment = "experiment-" * category * "-" * subcategory
problem_name =  experiment * ".pddl"

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "block-words")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, problem_name))

# Initialize problem and visualize initial state
state = initialize(problem)
goal = problem.goal
plt = render(state)

# Generate plan
planner = AStarPlanner(heuristic=HAdd())
plan, traj = planner(domain, state, goal)
println("== Plan ==")
display(plan)
anim = anim_traj(traj)
