using PDDL, SymbolicPlanners

# Load domain and problem
domain = load_domain(joinpath(@__DIR__, "domain.pddl"))
problem = load_problem(joinpath(@__DIR__, "problem-1-1.pddl"))

# Manually execute plan and check if goal is satisfied
state = initstate(domain, problem)
state = execute(domain, state, pddl"(move start-loc food-loc)")
state = execute(domain, state, pddl"(pick-up lettuce1 food-loc)")
state = execute(domain, state, pddl"(move food-loc chop-loc)")
state = execute(domain, state, pddl"(place-in lettuce1 board1 chop-loc)")
state = execute(domain, state, pddl"(pick-up knife1 chop-loc)")
state = execute(domain, state, pddl"(prepare slice board1 knife1 lettuce1 chop-loc)")
state = execute(domain, state, pddl"(put-down knife1 chop-loc)")
state = execute(domain, state, pddl"(take-out lettuce1 board1 chop-loc)")
state = execute(domain, state, pddl"(move chop-loc plate-loc)")
state = execute(domain, state, pddl"(place-in lettuce1 plate1 plate-loc)")
satisfy(domain, state, problem.goal)

# Use planner to solve for goal
state = initstate(domain, problem)
planner = AStarPlanner(HAdd())
planner = FastDownward(heuristic="add", verbose=true)

@time sol = planner(domain, state, problem.goal)

# Print solution
write_pddl.(collect(sol))

# Load domain and problem 2
domain = load_domain(joinpath(@__DIR__, "domain.pddl"))
problem = load_problem(joinpath(@__DIR__, "problem-2-1.pddl"))

# Manually execute plan and check if goal is satisfied
state = initstate(domain, problem)
# Put the nori in the plate
state = execute(domain, state, pddl"(move start-loc food-loc)")
state = execute(domain, state, pddl"(pick-up nori1 food-loc)")
state = execute(domain, state, pddl"(move food-loc plate-loc)")
state = execute(domain, state, pddl"(place-in nori1 plate1 plate-loc)")
# Put boiled rice in the plate
state = execute(domain, state, pddl"(move plate-loc food-loc)")
state = execute(domain, state, pddl"(pick-up rice1 food-loc)")
state = execute(domain, state, pddl"(move food-loc stove-loc)")
state = execute(domain, state, pddl"(place-in rice1 pot1 stove-loc)")
state = execute(domain, state, pddl"(cook boil pot1 stove1 stove-loc)")
state = execute(domain, state, pddl"(pick-up pot1 stove-loc)")
state = execute(domain, state, pddl"(move stove-loc plate-loc)")
state = execute(domain, state, pddl"(transfer pot1 plate1)")
state = execute(domain, state, pddl"(move plate-loc stove-loc)")
state = execute(domain, state, pddl"(put-down pot1 stove-loc)")
# Put sliced fish in the plate
state = execute(domain, state, pddl"(move stove-loc food-loc)")
state = execute(domain, state, pddl"(pick-up fish1 food-loc)")
state = execute(domain, state, pddl"(move food-loc chop-loc)")
state = execute(domain, state, pddl"(place-in fish1 board1 chop-loc)")
state = execute(domain, state, pddl"(pick-up knife1 chop-loc)")
state = execute(domain, state, pddl"(prepare slice board1 knife1 fish1 chop-loc)")
state = execute(domain, state, pddl"(put-down knife1 chop-loc)")
state = execute(domain, state, pddl"(take-out fish1 board1 chop-loc)")
state = execute(domain, state, pddl"(move chop-loc plate-loc)")
state = execute(domain, state, pddl"(place-in fish1 plate1 plate-loc)")

satisfy(domain, state, problem.goal)
