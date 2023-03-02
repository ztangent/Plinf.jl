using PDDL, SymbolicPlanners
using DataFrames

include("planner.jl")
include("load_goals.jl")

DOMAIN_DIR = @__DIR__
PROBLEM_DIR = joinpath(@__DIR__, "problems")
GOALS_DIR = joinpath(@__DIR__, "goals")

# Load domain
domain = load_domain(joinpath(DOMAIN_DIR, "domain.pddl"))

# Find problem paths
problem_paths = filter(readdir(PROBLEM_DIR, join=true)) do path
    match(r"problem-\d-\d.pddl", path) !== nothing
end

# Find goal paths
goals_paths = filter(readdir(GOALS_DIR, join=true)) do path
    match(r"goals-\d-\d.pddl", path) !== nothing
end

function extract_problem_idxs(path)
    m = match(r"problem-(\d+)-(\d+)\.pddl", path)
    return parse.(Int, (m.captures[1], m.captures[2]))
end

# Generate a plan for each goal and problem
for (ppath, gpath) in zip(problem_paths, goals_paths)
    i, j = extract_problem_idxs(ppath)
    if (i, j) != (3, 4) continue end
    problem = load_problem(ppath)
    descriptions, goals = load_goals(gpath)
    state = initstate(domain, problem)
    heuristic = memoized(precomputed(FFHeuristic(), domain, state))
    for (k, goal) in enumerate(goals)
        if k in [1, 3, 4] continue end
        # Compute goal heuristic to determine reachability
        hval = heuristic(domain, state, goal)
        if hval == Inf
            println("❌ Goal $k for $(basename(ppath)) is unsolvable")
            continue
        end
        # Use planner to solve for goal
        planner = OvercookedPlanner(
            planner=AStarPlanner(heuristic),
            ordering=:cluster,
            max_time=300.0
        )
        sol = planner(domain, state, goal);
        if sol isa NullSolution
            # Try different subgoal ordering if first fails
            planner = OvercookedPlanner(
                planner=AStarPlanner(heuristic),
                ordering=:cluster,
                max_time=300.0
            )
            sol = planner(domain, state, goal);
            if sol isa NullSolution
                println("❌ Goal $k for $(basename(ppath)) is unsolvable")
                continue
            end
        end
        println("Saving plan to goal $k for $(basename(ppath))...")
        plan_dir = joinpath(@__DIR__, "plans", "problem-$i-$j")
        mkpath(plan_dir)
        plan_path = joinpath(plan_dir, "plan-$i-$j-$k.pddl")
        open(plan_path, "w") do f
            for (subplan, subgoal) in zip(sol.subplans, sol.subgoals)
                subplan_str = join(write_pddl.(subplan), "\n")
                write(f, subplan_str)
                subgoal_str = join(write_pddl.(subgoal), " ")
                write(f, "\n; $subgoal_str\n")
            end
        end
    end
end
