using PDDL, SymbolicPlanners
using DataFrames

include("planner.jl")
include("load_goals.jl")


DOMAIN_DIR = @__DIR__
PROBLEM_DIR = joinpath(@__DIR__, "problems")
GOALS_DIR = joinpath(@__DIR__, "goals")
PLANS_DIR = joinpath(@__DIR__, "plans")

## Plan Generation ##

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
    problem = load_problem(ppath)
    descriptions, goals = load_goals(gpath)
    state = initstate(domain, problem)
    heuristic = memoized(precomputed(FFHeuristic(), domain, state))
    for (k, goal) in enumerate(goals)
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
        plan_dir = joinpath(PLANS_DIR, "problem-$i-$j")
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

## Plan to subgoal translation ##

include("load_plan.jl")

RELEVANT_PREDICATES = 
    Symbol.(["object-at-loc", "in-receptacle", "holding",
             "prepared", "cooked", "combined"])

function compute_achieved_subgoals(
    domain::GenericDomain, state::GenericState, plan::Vector{<:Term};
    relevant_predicates = RELEVANT_PREDICATES,
    final_only = true, include_negated = nothing
)
    if isnothing(include_negated) && final_only
        include_negated = plan[end].name == Symbol("put-down")
    end
    pos_achieved = Term[]
    neg_achieved = Term[]
    for (t, act) in enumerate(plan)
        effect = PDDL.get_effect(domain, act)
        diff = PDDL.effect_diff(domain, state, effect)::PDDL.GenericDiff
        if !final_only || t == length(plan)
            union!(pos_achieved, diff.add)
            setdiff!(pos_achieved, diff.del)
            if include_negated
                union!(neg_achieved, diff.del)
                setdiff!(neg_achieved, diff.add)
            end
        end
        state = PDDL.update(domain, state, diff)
    end
    filter!(pos_achieved) do pred
        relevant_predicates === nothing || pred.name in relevant_predicates
    end
    filter!(neg_achieved) do pred
        relevant_predicates === nothing || pred.name in relevant_predicates
    end
    neg_achieved = [Compound(:not, [pred]) for pred in neg_achieved]
    achieved = union(pos_achieved, neg_achieved)
    return achieved
end

function compute_achieved_subgoals(
    domain::GenericDomain, state::GenericState, plans::Vector{<:Vector{<:Term}};
    kwargs...
)
    all_achieved = Vector{Term}[]
    for plan in plans
        achieved = compute_achieved_subgoals(domain, state, plan; kwargs...)
        push!(all_achieved, achieved)
        for act in plan
            state = PDDL.transition(domain, state, act)
        end
    end
    return all_achieved
end

PROBLEMS = [
    [joinpath(PROBLEM_DIR, "problem-$i-$j.pddl") for j in 1:5] for i in 1:5
]

PLANS = [
    [joinpath(PLANS_DIR, "problem-$i-$j", "narrative-plan-segmented-$i-$j-1.pddl") for j in 1:5] for i in 1:5
]

for (kitchen_id, plan_paths) in enumerate(PLANS)
    println("Processing kitchen $kitchen_id...")
    for (problem_id, path) in enumerate(plan_paths)
        println("Processing $(basename(path))...")
        # Load problem and construct initial state
        problem_path = PROBLEMS[kitchen_id][problem_id]
        problem = load_problem(problem_path)
        state = initstate(domain, problem)
        # Load original plan
        m = match(r"\w+-(\d+)-(\d+)-(\d+)\.pddl", basename(path))
        instance_id = parse(Int, m.captures[3])
        plan, annotations, times = load_plan(path)
        # Split into subplans
        pushfirst!(times, 0)
        subplans = [plan[t1+1:t2] for (t1, t2) in zip(times[1:end-1], times[2:end])]
        # Compute achieved subgoals
        subgoals = compute_achieved_subgoals(domain, state, subplans; final_only=true)
        # Write to file
        plan_dir = dirname(path)
        i, j, k = (kitchen_id, problem_id, instance_id)
        plan_path = joinpath(plan_dir, "narrative-subgoals-segmented-$i-$j-$k.pddl")
        # open(plan_path, "w") do f
        #     for t in eachindex(annotations)
        #         write(f, "; " * annotations[t] * "\n")
        #         write(f, "; Number of subgoals: $(length(subgoals[t]))\n")
        #         subgoal_str = join(write_pddl.(subgoals[t]), "\n")
        #         write(f, subgoal_str * "\n")
        #     end
        # end
    end
end
