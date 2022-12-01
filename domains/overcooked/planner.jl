using Base: @kwdef
using PDDL, SymbolicPlanners
import SymbolicPlanners: Planner

"Custom landmark based planner for Overcooked problems."
@kwdef mutable struct OvercookedPlanner{T <: Planner} <: Planner
    planner::T # Planner to use for each subgoal
    max_time::Float64 = Inf
    verbose::Bool = false
end

function SymbolicPlanners.solve(
    planner::OvercookedPlanner,
    domain::Domain, state::State, spec::Specification
)
    start_time = time()
    # Dequantify and simplify goal condition
    statics = PDDL.infer_static_fluents(domain)
    goal = Compound(:and, SymbolicPlanners.get_goal_terms(spec))
    goal = PDDL.to_nnf(PDDL.dequantify(goal, domain, state, statics))
    goal = PDDL.simplify_statics(goal, domain, state, statics)
    # If there are multiple ways of satisfying goal, pick the first
    if PDDL.is_dnf(goal)
        goal = goal.args[1]
    end
    subgoals = PDDL.flatten_conjs(goal)
    # Split goal into preparation, combination, cooking, and plating
    prepare_goals = Term[]
    combine_goals = Term[]
    cook_goals = Term[]
    serve_goals = Term[]
    misc_goals = Term[]
    for term in subgoals
        if term.name == :prepared
            push!(prepare_goals, term)
        elseif term.name == :combined || term.name == Symbol("combined-with")
            push!(combine_goals, term)
        elseif term.name == :cooked || term.name == Symbol("cooked-with")
            push!(cook_goals, term)
        elseif term.name == Symbol("in-receptacle")
            push!(serve_goals, term)
        else
            push!(misc_goals, term)
        end
    end
    # Solve each set of subgoals in sequence
    plan = Term[]
    for goals in (prepare_goals, combine_goals, cook_goals, serve_goals, misc_goals)
        if planner.verbose
            println("Subgoals: ", join(write_pddl.(goals), ", "))
        end
        time_elapsed = time() - start_time
        time_left = planner.max_time - time_elapsed
        if time_left < 0
            return NullSolution(:max_time)
        end
        planner.planner.max_time = time_left
        sol = planner.planner(domain, state, goals)
        if sol.status != :success
            return NullSolution(sol.status)
        end
        actions = collect(sol)
        if planner.verbose
            println("Subplan: ", join(write_pddl.(actions), ", "))
        end
        append!(plan, actions)
        state = sol.trajectory[end]
    end
    # Check that goal is satisfied
    if !PDDL.satisfy(domain, state, goal) 
        return NullSolution()
    end
    return OrderedPlan(plan)
end