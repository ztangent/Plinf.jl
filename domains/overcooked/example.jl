using PDDL, SymbolicPlanners

# Load domain and problem 1
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
heuristic = HMax()
hval = heuristic(domain, state, problem.goal)
planner = AStarPlanner(HAdd(), save_search=true, max_time=300)
@time sol = planner(domain, state, problem.goal);

# Print solution
write_pddl.(collect(sol)) |> display

# Load domain and problem 2
domain = load_domain(joinpath(@__DIR__, "domain.pddl"));
problem = load_problem(joinpath(@__DIR__, "problem-3-1.pddl"));

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

goal = pddl"
(exists (?hamburger-bun - food ?beef - food ?cheese - food ?onion - food ?plate - receptacle)
        (and (food-type beef ?beef)
             (food-type hamburger-bun ?hamburger-bun)
             (food-type cheese ?cheese)
             (food-type onion ?onion)
             (receptacle-type plate ?plate)
             (cooked grill ?beef)
             (prepared slice ?cheese)
             (prepared chop ?onion)
             (in-receptacle ?hamburger-bun ?plate)
             (in-receptacle ?beef ?plate)
             (in-receptacle ?cheese ?plate)
             (in-receptacle ?onion ?plate)))
"
goal

statics = PDDL.infer_static_fluents(domain)
goal = PDDL.to_nnf(PDDL.dequantify(goal, domain, state))
goal = PDDL.simplify_statics(goal, domain, state, statics)

@time heuristic = precomputed(HMax(), domain, state, problem.goal);
@time hval = heuristic(domain, state, goal)
planner = AStarPlanner(HAdd(), save_search=true, max_time=300)
@time sol = planner(domain, state, problem.goal);


# Use planner to solve for goal
state = initstate(domain, problem)
planner = AStarPlanner(FFHeuristic(), save_search=true)
@time sol = planner(domain, state, problem.goal)

# Print solution
write_pddl.(collect(sol))

# Load domain and problem 4
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
satisfy(domain, state, problem.goal)

# Use planner to solve for goal
state = initstate(domain, problem)
heuristic = HMax()
hval = heuristic(domain, state, problem.goal)
planner = AStarPlanner(HAdd(), save_search=true, max_time=300)
@time sol = planner(domain, state, problem.goal);

# Print solution
write_pddl.(collect(sol)) |> display

# Load domain and problem 5
domain = load_domain(joinpath(@__DIR__, "domain.pddl"))
problem = load_problem(joinpath(@__DIR__, "problem-5-1.pddl"))

available(domain, state)

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
#Mix ingredients
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
satisfy(domain, state, problem.goal)

# Use planner to solve for goal
state = initstate(domain, problem)
heuristic = HMax()
hval = heuristic(domain, state, problem.goal)
planner = AStarPlanner(HAdd(), save_search=true, max_time=300)
@time sol = planner(domain, state, problem.goal);

# Print solution
write_pddl.(collect(sol)) |> display
