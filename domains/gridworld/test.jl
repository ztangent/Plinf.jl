using Julog, PDDL, Test
using InverseTAMP

include("render.jl")

path = joinpath(dirname(pathof(InverseTAMP)), "..", "domains", "gridworld")

domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem-3.pddl"))

state = initialize(problem)
start_pos = (state[:xpos], state[:ypos])
goal_pos = (5, 5)
goal_terms = @julog[xpos == $(goal_pos[1]), ypos == $(goal_pos[2])]

plan = heuristic_search(goal_terms, state, domain; heuristic=manhattan)
println("== Plan ==")
display(plan)
state = execute(plan, state, domain)
@test satisfy(goal_terms, state, domain)[1] == true

render(state, start=start_pos, goal=goal_pos, plan=plan)
