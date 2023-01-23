using PDDL, SymbolicPlanners

include("planner.jl")
include("load_goals.jl")

DOMAIN_DIR = @__DIR__
PROBLEM_DIR = joinpath(@__DIR__, "problems")
GOALS_DIR = joinpath(@__DIR__, "goals")

# Load domain
domain = load_domain(joinpath(DOMAIN_DIR, "domain.pddl"))

# Validate that each problem is solvable
problem_paths = filter(readdir(PROBLEM_DIR, join=true)) do path
    match(r"problem-\d-\d.pddl", path) !== nothing
end

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
    planner = OvercookedPlanner(
        planner=AStarPlanner(HAdd()),
        ordering=:cluster,
        max_time=300.0
    )
    sol = planner(domain, state, problem.goal);
    if sol isa NullSolution
        println("❌ $(basename(path)) is unsolvable")
    end
    println("✔ $(basename(path)) is solvable")
end

# Validate that each goal in a problem set is solvable in the reference problem
N_PROBLEM_SETS = 5

for i in 1:N_PROBLEM_SETS
    # Find problem paths
    problem_paths = filter(readdir(PROBLEM_DIR, join=true)) do path
        m = match(r"problem-(\d)-\d.pddl", path)
        return m !== nothing && parse(Int, m.captures[1]) == i
    end
    # Load last problem as reference problem
    ref_path = problem_paths[end]
    ref_problem = load_problem(ref_path)
    state = initstate(domain, ref_problem)
    heuristic = memoized(precomputed(HAdd(), domain, state))
    println("Validating $(basename(ref_path))...")
    # Load goal of each problem and check if reachable
    for path in problem_paths
        problem = load_problem(path)
        hval = heuristic(domain, state, problem.goal)
        if hval == Inf
            println("❌ Goal from $(basename(path)) is unsolvable")
            continue
        end
        # Use planner to solve for goal
        planner = OvercookedPlanner(planner=AStarPlanner(heuristic), max_time=300.0)
        sol = planner(domain, state, problem.goal);
        if sol isa NullSolution
            println("❌ Goal from $(basename(path)) is unsolvable")
        end
        println("✔ Goal from $(basename(path)) is solvable")
    end
end

# Validate the correspondence between problem goals and goal files
problem_paths = filter(readdir(PROBLEM_DIR, join=true)) do path
    match(r"problem-\d-\d.pddl", path) !== nothing
end

goals_paths = filter(readdir(GOALS_DIR, join=true)) do path
    match(r"goals-\d-\d.pddl", path) !== nothing
end

for (ppath, gpath) in zip(problem_paths, goals_paths)
    problem = load_problem(ppath)
    descriptions, goals = load_goals(gpath)
    idx = findfirst(==(problem.goal), goals)
    if idx !== nothing
        println("✔ Goals match for $(basename(ppath)) at index $idx")
    else
        println("❌ Error: Goals do not match for $(basename(ppath))")
    end
end

# Validate the solvability of each goal for each problem
for (ppath, gpath) in zip(problem_paths, goals_paths)
    problem = load_problem(ppath)
    descriptions, goals = load_goals(gpath)
    state = initstate(domain, problem)
    heuristic = memoized(precomputed(HAdd(), domain, state))
    for (idx, goal) in enumerate(goals)
        hval = heuristic(domain, state, goal)
        if hval == Inf
            println("❌ Goal $idx for $(basename(ppath)) is unsolvable")
            continue
        end
        # Use planner to solve for goal
        planner = OvercookedPlanner(
            planner=AStarPlanner(heuristic),
            max_time=300.0
        )
        sol = planner(domain, state, goal);
        if sol isa NullSolution
            println("❌ Goal $idx for $(basename(ppath)) is unsolvable")
        end
        println("✔ Goal $idx from $(basename(ppath)) is solvable")
    end
end
