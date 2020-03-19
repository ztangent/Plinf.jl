using Julog, PDDL #, Gen, Printf
using InverseTAMP

include("render.jl")

# Load domain and problem
path = joinpath(dirname(pathof(InverseTAMP)), "..", "domains", "doors-keys-gems")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem-2.pddl"))

# Define helper function to convert x-y tuples to Julog term
pos_to_terms(pos) = @julog([xpos == $(pos[1]), ypos == $(pos[2])])

# Initialize state, set goal position
state = initialize(problem)
start_pos = (state[:xpos], state[:ypos])
goal = [problem.goal]

# Check that heuristic search correctly solves the problem
plan, _ = heuristic_search(goal, state, domain; heuristic=goal_count)
println("== Plan ==")
display(plan)
render(state; start=start_pos, plan=plan, show_pos=true)
end_state = execute(plan, state, domain)
@assert satisfy(goal, end_state, domain)[1] == true
