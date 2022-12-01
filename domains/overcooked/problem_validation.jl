using PDDL, SymbolicPlanners

include("planner.jl")

DOMAIN_DIR = @__DIR__
PROBLEM_DIR = @__DIR__

# Load domain
domain = load_domain(joinpath(DOMAIN_DIR, "domain.pddl"))
# Find problem paths
problem_paths = filter(readdir(PROBLEM_DIR, join=true)) do path
    match(r"problem-\d-\d.pddl", path) !== nothing
end

# Iterate over problems
for path in problem_paths
    # Load problem
    problem = load_problem(path)
    # Use heuristic to check reachability
    state = initstate(domain, problem)
    heuristic = HMax()
    hval = heuristic(domain, state, problem.goal)
    if hval == Inf
        println("❌ $(basename(path)) is unsolvable")
        continue
    end
    # Use planner to solve for goal
    planner = OvercookedPlanner(planner=AStarPlanner(HAdd()), max_time=300.0)
    sol = planner(domain, state, problem.goal);
    if sol isa NullSolution
        println("❌ $(basename(path)) is unsolvable")
    end
    println("✔ $(basename(path)) is solvable")
end