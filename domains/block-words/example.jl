using Julog, PDDL, Gen, Printf
using Plinf

include("render.jl")

#--- Initial Setup ---#

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "block-words")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem.pddl"))

# Initialize state
state = initialize(problem)
goal = problem.goal

#--- Visualize Plans ---#

# Check that A* heuristic search correctly solves the problem
planner = AStarPlanner(heuristic=h_add)
plan, traj = planner(domain, state, goal)
println("== Plan ==")
display(plan)
anim = anim_traj(traj)

# Visualize full horizon probabilistic A* search
planner = ProbAStarPlanner(heuristic=h_add, search_noise=1)
plt = render(state)
tr = Gen.simulate(sample_plan, (planner, domain, state, goal))
# anim = anim_plan(tr, plt)

# Visualize distribution over trajectories induced by planner
trajs = [planner(domain, state, goal)[2] for i in 1:20]
anim = anim_traj(trajs, plt; alpha=0.1)

# Visualize sample-based replanning search
astar = ProbAStarPlanner(heuristic=h_add, search_noise=0.1)
replanner = Replanner(planner=astar, persistence=(2, 0.95))
plt = render(state)
tr = Gen.simulate(sample_plan, (replanner, domain, state, goal))
# anim = anim_replan(tr, plt)

# Visualize distribution over trajectories induced by replanner
trajs = [replanner(domain, state, goal)[2] for i in 1:5]
anim = anim_traj(trajs; alpha=1/length(trajs))
