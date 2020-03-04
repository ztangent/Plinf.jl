using Julog, PDDL, Gen
using InverseTAMP

include("model.jl")
include("render.jl")

path = joinpath(dirname(pathof(InverseTAMP)), "..", "domains", "gridworld")

domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem-3.pddl"))

# Initialize state, set goal position
state = initialize(problem)
start_pos = (state[:xpos], state[:ypos])
goal_pos = (7, 8)
goal_terms = @julog[xpos == $(goal_pos[1]), ypos == $(goal_pos[2])]

# Check that heuristic search correctly solves the problem
plan, _ = heuristic_search(goal_terms, state, domain; heuristic=manhattan)
println("== Plan ==")
display(plan)
render(state; start=start_pos, goal=goal_pos, plan=plan)
end_state = execute(plan, state, domain)
@test satisfy(goal_terms, end_state, domain)[1] == true

# Visualize full horizon sample-based search
plt = render(state; start=start_pos, goal=goal_pos, show_pos=false)
@gif for i=1:20
    plan, _ = sample_search(goal_terms, state, domain, 0.1)
    plt = render!(plan, start_pos; alpha=0.05)
end
display(plt)

# Visualize sample-based replanning search
plt = render(state; start=start_pos, goal=goal_pos, show_pos=false)
@gif for i=1:20
    plan, _ = replan_search(goal_terms, state, domain, 0.1, 0.95)
    plt = render!(plan, start_pos; alpha=0.05)
end
display(plt)

# Visualize sample-based search with observation noise
traj = model([goal_terms], state, domain)
plt = render(state; start=start_pos, goal=goal_pos, show_pos=false)
plt = render!(traj, plt)
