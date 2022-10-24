using PDDL, SymbolicPlanners

## Load domain and problem 1-1
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
@assert satisfy(domain, state, problem.goal)

# Use heuristic to check reachability
state = initstate(domain, problem)
heuristic = HMax()
hval = heuristic(domain, state, problem.goal)

# Use planner to solve for goal
planner = AStarPlanner(HAdd(), save_search=true, max_time=300)
sol = planner(domain, state, problem.goal);

# Check if solution was found
@assert !(sol isa NullSolution)

# Print solution
println("== Solution ==")
for act in write_pddl.(collect(sol))
    println(act)
end
println("Solution Length: $(length(sol))")

##  Load domain and problem 2-1
domain = load_domain(joinpath(@__DIR__, "domain.pddl"));
problem = load_problem(joinpath(@__DIR__, "problem-2-1.pddl"));

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
# Put sliced tuna in the plate
state = execute(domain, state, pddl"(move stove-loc food-loc)")
state = execute(domain, state, pddl"(pick-up tuna1 food-loc)")
state = execute(domain, state, pddl"(move food-loc chop-loc)")
state = execute(domain, state, pddl"(place-in tuna1 board1 chop-loc)")
state = execute(domain, state, pddl"(pick-up s-knife1 chop-loc)")
state = execute(domain, state, pddl"(prepare slice board1 s-knife1 tuna1 chop-loc)")
state = execute(domain, state, pddl"(put-down s-knife1 chop-loc)")
state = execute(domain, state, pddl"(take-out tuna1 board1 chop-loc)")
state = execute(domain, state, pddl"(move chop-loc plate-loc)")
state = execute(domain, state, pddl"(place-in tuna1 plate1 plate-loc)")
@assert satisfy(domain, state, problem.goal)

# Use heuristic to check reachability
state = initstate(domain, problem)
heuristic = HMax()
hval = heuristic(domain, state, problem.goal)

# Use planner to solve for goal
planner = AStarPlanner(HAdd(), save_search=true)
sol = planner(domain, state, problem.goal)

# Check if solution was found
@assert !(sol isa NullSolution)

# Print solution
println("== Solution ==")
for act in write_pddl.(collect(sol))
    println(act)
end
println("Solution Length: $(length(sol))")

## Load domain and problem 3-1
domain = load_domain(joinpath(@__DIR__, "domain.pddl"));
problem = load_problem(joinpath(@__DIR__, "problem-3-1.pddl"));

# Manually execute plan and check if goal is satisfied
state = initstate(domain, problem)
# Add hamburger bun to plate
state = execute(domain, state, pddl"(move start-loc food-loc)")
state = execute(domain, state, pddl"(pick-up hamburger-bun1 food-loc)")
state = execute(domain, state, pddl"(move food-loc plate-loc)")
state = execute(domain, state, pddl"(place-in hamburger-bun1 plate1 plate-loc)")
# Cook and transfer beef to plate
state = execute(domain, state, pddl"(move plate-loc food-loc)")
state = execute(domain, state, pddl"(pick-up beef1 food-loc)")
state = execute(domain, state, pddl"(move food-loc stove-loc)")
state = execute(domain, state, pddl"(place-in beef1 pan1 stove-loc)")
state = execute(domain, state, pddl"(cook grill pan1 stove1 stove-loc)")
state = execute(domain, state, pddl"(pick-up pan1 stove-loc)")
state = execute(domain, state, pddl"(move stove-loc plate-loc)")
state = execute(domain, state, pddl"(transfer pan1 plate1 plate-loc)")
state = execute(domain, state, pddl"(put-down pan1 plate-loc)")
# Slice cheese
state = execute(domain, state, pddl"(move plate-loc food-loc)")
state = execute(domain, state, pddl"(pick-up cheese1 food-loc)")
state = execute(domain, state, pddl"(move food-loc chop-loc)")
state = execute(domain, state, pddl"(place-in cheese1 board1 chop-loc)")
state = execute(domain, state, pddl"(pick-up knife1 chop-loc)")
state = execute(domain, state, pddl"(prepare slice board1 knife1 cheese1 chop-loc)")
state = execute(domain, state, pddl"(put-down knife1 chop-loc)")
# Transfer sliced cheese to plate
state = execute(domain, state, pddl"(pick-up board1 chop-loc)")
state = execute(domain, state, pddl"(move chop-loc plate-loc)")
state = execute(domain, state, pddl"(transfer board1 plate1 plate-loc)")
state = execute(domain, state, pddl"(put-down board1 plate-loc)")
@assert satisfy(domain, state, problem.goal)

# Use heuristic to check reachability
state = initstate(domain, problem)
heuristic = HMax()
hval = heuristic(domain, state, problem.goal)

# Use planner to solve for goal
planner = AStarPlanner(HAdd())
sol = planner(domain, state, problem.goal);

# Check if solution was found
@assert !(sol isa NullSolution)

# Print solution
println("== Solution ==")
for act in write_pddl.(collect(sol))
    println(act)
end
println("Solution Length: $(length(sol))")

## Load domain and problem 4-1
domain = load_domain(joinpath(@__DIR__, "domain.pddl"))
problem = load_problem(joinpath(@__DIR__, "problem-4-1.pddl"))

# Manually execute plan and check if goal is satisfied
state = initstate(domain, problem)
# Collect food items and place on tray
state = execute(domain, state, pddl"(move start-loc tray-loc)")
state = execute(domain, state, pddl"(pick-up tray1 tray-loc)")
state = execute(domain, state, pddl"(move tray-loc food-loc)")
state = execute(domain, state, pddl"(put-down tray1 food-loc)")
state = execute(domain, state, pddl"(pick-up dough1 food-loc)")
state = execute(domain, state, pddl"(place-in dough1 tray1 food-loc)")
state = execute(domain, state, pddl"(pick-up cheese1 food-loc)")
state = execute(domain, state, pddl"(place-in cheese1 tray1 food-loc)")
state = execute(domain, state, pddl"(pick-up tomato1 food-loc)")
state = execute(domain, state, pddl"(place-in tomato1 tray1 food-loc)")
state = execute(domain, state, pddl"(pick-up sausage1 food-loc)")
state = execute(domain, state, pddl"(place-in sausage1 tray1 food-loc)")
state = execute(domain, state, pddl"(pick-up tray1 food-loc)")
# Slice sausage at chopping board location
state = execute(domain, state, pddl"(move food-loc chop-loc)")
state = execute(domain, state, pddl"(put-down tray1 chop-loc)")
state = execute(domain, state, pddl"(take-out sausage1 tray1 chop-loc)")
state = execute(domain, state, pddl"(place-in sausage1 board1 chop-loc)")
state = execute(domain, state, pddl"(pick-up knife1 chop-loc)")
state = execute(domain, state, pddl"(prepare slice board1 knife1 sausage1 chop-loc)")
state = execute(domain, state, pddl"(put-down knife1 chop-loc)")
state = execute(domain, state, pddl"(take-out sausage1 board1 chop-loc)")
state = execute(domain, state, pddl"(place-in sausage1 tray1 chop-loc)")
state = execute(domain, state, pddl"(pick-up tray1 chop-loc)")
# Bake pizza ingredients
state = execute(domain, state, pddl"(move chop-loc oven-loc)")
state = execute(domain, state, pddl"(put-down tray1 oven-loc)")
state = execute(domain, state, pddl"(cook bake tray1 oven1 oven-loc)")
state = execute(domain, state, pddl"(pick-up tray1 oven-loc)")
# Transfer to plate
state = execute(domain, state, pddl"(move oven-loc plate-loc)")
state = execute(domain, state, pddl"(transfer tray1 plate1)")
@assert satisfy(domain, state, problem.goal)

# Use heuristic to check reachability
state = initstate(domain, problem)
heuristic = HMax()
hval = heuristic(domain, state, problem.goal)

# Use planner to solve for goal
planner = AStarPlanner(HAdd())
sol = planner(domain, state, problem.goal);

# Check if solution was found
@assert !(sol isa NullSolution)

# Print solution
println("== Solution ==")
for act in write_pddl.(collect(sol))
    println(act)
end
println("Solution Length: $(length(sol))")

## Load domain and problem 5-1
domain = load_domain(joinpath(@__DIR__, "domain.pddl"))
problem = load_problem(joinpath(@__DIR__, "problem-5-1.pddl"))

# Manually execute plan and check if goal is satisfied
state = initstate(domain, problem)
# Collect food items and place in mixing bowl
state = execute(domain, state, pddl"(move start-loc food-loc)")
state = execute(domain, state, pddl"(pick-up flour1 food-loc)")
state = execute(domain, state, pddl"(move food-loc mix-loc)")
state = execute(domain, state, pddl"(place-in flour1 mixing-bowl1 mix-loc)")
state = execute(domain, state, pddl"(move mix-loc food-loc)")
state = execute(domain, state, pddl"(pick-up egg1 food-loc)")
state = execute(domain, state, pddl"(move food-loc mix-loc)")
state = execute(domain, state, pddl"(place-in egg1 mixing-bowl1 mix-loc)")
state = execute(domain, state, pddl"(move mix-loc food-loc)")
state = execute(domain, state, pddl"(pick-up chocolate1 food-loc)")
state = execute(domain, state, pddl"(move food-loc mix-loc)")
state = execute(domain, state, pddl"(place-in chocolate1 mixing-bowl1 mix-loc)")
# Mix ingredients
state = execute(domain, state, pddl"(combine mix mixing-bowl1 mixer1 mix-loc)")
# Bake cake ingredients
state = execute(domain, state, pddl"(pick-up mixing-bowl1 mix-loc)")
state = execute(domain, state, pddl"(move mix-loc oven-loc)")
state = execute(domain, state, pddl"(put-down mixing-bowl1 oven-loc)")
state = execute(domain, state, pddl"(cook bake mixing-bowl1 oven1 oven-loc)")
state = execute(domain, state, pddl"(pick-up mixing-bowl1 oven-loc)")
# Transfer to plate
state = execute(domain, state, pddl"(move oven-loc plate-loc)")
state = execute(domain, state, pddl"(transfer mixing-bowl1 plate1)")
@assert satisfy(domain, state, problem.goal)

# Use heuristic to check reachability
state = initstate(domain, problem)
heuristic = HMax()
hval = heuristic(domain, state, problem.goal)

# Use planner to solve for goal
planner = AStarPlanner(HAdd())
sol = planner(domain, state, problem.goal);

# Check if solution was found
@assert !(sol isa NullSolution)

# Print solution
println("== Solution ==")
for act in write_pddl.(collect(sol))
    println(act)
end
println("Solution Length: $(length(sol))")
