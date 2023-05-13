using PDDL

include("load_goals.jl")
include("load_plan.jl")

DOMAIN_DIR = @__DIR__
PROBLEM_DIR = joinpath(@__DIR__, "problems")
PLANS_DIR = joinpath(@__DIR__, "plans")
GOALS_DIR = joinpath(@__DIR__, "goals")

domain = load_domain(joinpath(DOMAIN_DIR, "domain.pddl"))
statics = PDDL.infer_static_fluents(domain)

# Find problem paths
problem_paths = filter(readdir(PROBLEM_DIR, join=true)) do path
    match(r"problem-\d-\d.pddl", path) !== nothing
end

# Find goal paths
goals_paths = filter(readdir(GOALS_DIR, join=true)) do path
    match(r"goals-\d-\d.pddl", path) !== nothing
end

# Find plan paths
plan_paths =
    [[joinpath(PLANS_DIR, "problem-$i-$j", "narrative-plan-$i-$j-$k.pddl") for k in [1, 3, 5]]
     for i in 1:5 for j in 1:5]

# Validate that each plan achieves its corresponding goal
for (problem_path, goals_path, plan_paths) in zip(problem_paths, goals_paths, plan_paths)
    println("== $(basename(problem_path)) ==")
    # Load problem and goals
    problem = load_problem(problem_path)
    descriptions, goals = load_goals(goals_path)
    # Iterate over plans
    for path in plan_paths
        println("Validating $(basename(path)) for $(basename(problem_path))...")
        # Load the plan
        plan, annotations, annotation_idxs = load_plan(path)
        # Initialize state
        state = initstate(domain, problem)
        # Extract goal index
        m = match(r"narrative-plan-\d-\d-(\d).pddl", path)
        goal_idx = parse(Int, m.captures[1])
        # Simplify goal
        goal = goals[goal_idx]
        goal = PDDL.to_nnf(PDDL.dequantify(goal, domain, state, statics))
        goal = PDDL.simplify_statics(goal, domain, state, statics)
        # Excecute plan
        for (i, act) in enumerate(plan)
            try
                state = execute(domain, state, act)
            catch e
                error("Error executing action $act at step $i")
            end
        end
        # Check that final state satisfies goal
        if satisfy(domain, state, goal)
            println("✔ $(basename(path)) achieves the goal")
        else
            println("❌ $(basename(path)) fails to achieve the goal")
        end
    end
    println()
end
