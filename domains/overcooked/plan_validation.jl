using PDDL

include("load_goals.jl")
include("load_plan.jl")

DOMAIN_DIR = @__DIR__
PROBLEM_DIR = joinpath(@__DIR__, "problems")
PLANS_DIR = joinpath(@__DIR__, "plans")

domain = load_domain(joinpath(DOMAIN_DIR, "domain.pddl"))
statics = PDDL.infer_static_fluents(domain)

# Find problem paths
problem_paths = filter(readdir(PROBLEM_DIR, join=true)) do path
    match(r"problem-\d-\d.pddl", path) !== nothing
end

# Find plan paths
plan_paths = [joinpath(PLANS_DIR, "problem-$i-$j", "annotated-plan-$i-$j-1.pddl")
              for i in 1:5 for j in 1:5]

# Validate that each plan achieves its corresponding goal
for (path1, path2) in zip(problem_paths, plan_paths)
    println("Validating $(basename(path2)) for $(basename(path1))...")
    problem = load_problem(path1)
    plan, annotations, annotation_idxs = load_plan(path2)
    # Initialize state
    state = initstate(domain, problem)
    # Simplify problem goal
    goal = problem.goal
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
        println("✔ $(basename(path2)) achieves the goal")
    else
        println("❌ $(basename(path2)) fails to achieve the goal")
    end
end
