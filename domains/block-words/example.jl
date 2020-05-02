using Julog, PDDL, Gen, Printf
using Plinf

# include("render.jl")

#--- Initial Setup ---#

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "block-words")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem.pddl"))

# Initialize state, set goal position
state = initialize(problem)

#--- Visualize Plans ---#

# Check that A* heuristic search correctly solves the problem
planner = AStarPlanner(heuristic=h_add)
plan, traj = planner(domain, state, problem.goal)
println("== Plan ==")
display(plan)
