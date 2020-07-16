using Julog, PDDL, Gen, Printf
using Plinf

#--- Initial Setup ---#

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "polycraft")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem.pddl"))

# Initialize state
state = initialize(problem)
goal = problem.goal

#--- Visualize Plans ---#

# Check that forward heuristic search correctly solves the problem
planner = AStarPlanner(heuristic=HAdd())
plan, traj = planner(domain, state, goal)

# Check that backward heuristic search correctly solves the problem
planner = BackwardPlanner(heuristic=HAddR())
plan, traj = planner(domain, state, goal)
