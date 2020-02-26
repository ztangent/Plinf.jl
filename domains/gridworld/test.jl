using Julog, PDDL, Test
using InverseTAMP

include("render.jl")

path = joinpath(dirname(pathof(InverseTAMP)), "..", "domains", "gridworld")

domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem-3.pddl"))

state = initialize(problem)
plan = heuristic_search([problem.goal], state, domain; heuristic=manhattan)
println("== Plan ==")
display(plan)
state = execute(plan, state, domain)
@test satisfy(problem.goal, state, domain)[1] == true

render(state, start=(1,1), plan=plan)
