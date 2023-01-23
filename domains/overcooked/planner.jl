using Base: @kwdef
using PDDL, SymbolicPlanners
import SymbolicPlanners: Planner

include("recipe_utils.jl")

"Custom landmark based planner for Overcooked problems."
@kwdef mutable struct OvercookedPlanner{T <: Planner} <: Planner
    planner::T # Planner to use for each subgoal
    ordering::Symbol = :predicate # How to order subgoals
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
    # Order into subgoals
    if planner.ordering == :predicate
        subgoals = order_subgoals_by_predicate(goal)
    elseif planner.ordering == :cluster
        subgoals = order_subgoals_by_cluster(goal)
    else
        error("Unrecognized ordering flag: $(planner.ordering)")
    end
    # Solve each set of subgoals in sequence
    plan = Term[]
    for goals in subgoals
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

"Orders subgoals in a recipe by predicate type."
function order_subgoals_by_predicate(goal::Term)
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
    return [prepare_goals, combine_goals, cook_goals, serve_goals, misc_goals]
end

"Orders subgoals in a recipe by ingredient cluster."
function order_subgoals_by_cluster(goal::Term)
    subgoals = Vector{Term}[]
    # Extract ingredients and recipe terms
    ingredients = extract_ingredients(goal)
    terms = PDDL.flatten_conjs(goal)
    # Extract combine clusters
    combine_clusters, combine_cluster_terms = 
        extract_ingredient_clusters(goal, Symbol("combined-with"))
    for term in terms # Add ingredients cooked on their own
        term.name == :combined || continue
        pushfirst!(combine_clusters, [term.args[2]])
        pushfirst!(combine_cluster_terms, [term])
    end
    # Extract cook clusters
    cook_clusters, cook_cluster_terms = 
        extract_ingredient_clusters(goal, Symbol("cooked-with"))
    for term in terms # Add ingredients cooked on their own
        term.name == :cooked || continue
        pushfirst!(cook_clusters, [term.args[2]])
        pushfirst!(cook_cluster_terms, [term])
    end
    # Add prepare terms not in any cluster
    prepare_terms = filter(terms) do term
        term.name == :prepared &&
        !any(term.args[2] in c for c in cook_clusters) &&
        !any(term.args[2] in c for c in combine_clusters)
    end
    if !isempty(prepare_terms)
        push!(subgoals, prepare_terms)
        setdiff!(terms, prepare_terms)
    end
    # Add corresponding in-receptacle terms
    in_receptacle_terms = map(prepare_terms) do prepare_term
        idx = findfirst(terms) do term
            term.name == Symbol("in-receptacle") &&
            term.args[1] == prepare_term.args[2]
        end
        return terms[idx]
    end
    if !isempty(in_receptacle_terms)
        push!(subgoals, in_receptacle_terms)
        setdiff!(terms, in_receptacle_terms)
    end
    # Add subgoals for each cook cluster
    for (cluster, cluster_terms) in zip(cook_clusters, cook_cluster_terms)
        # Find all subsumed combination clusters
        idxs = findall(x -> x ⊆ cluster, combine_clusters)
        combine_subclusters = combine_clusters[idxs]
        combine_subcluster_terms = combine_cluster_terms[idxs]
        # Iterate over subclusters
        for (c, c_terms) in zip(combine_subclusters, combine_subcluster_terms)
            # Find all prepare terms involving subcluster ingredients
            prepare_terms = filter(terms) do term
                term.name == :prepared && term.args[2] in c
            end
            # Add prepare terms as subgoals
            if !isempty(prepare_terms)
                push!(subgoals, prepare_terms)
                setdiff!(terms, prepare_terms)
            end
                # Add combine terms as subgoals
            push!(subgoals, c_terms)
            setdiff!(terms, c_terms)
        end
        # Remove added subclusters
        deleteat!(combine_clusters, idxs)
        deleteat!(combine_cluster_terms, idxs)
        # Add remaining prepare terms involving cluster ingredients
        prepare_terms = filter(terms) do term
            term.name == :prepared && term.args[2] in cluster
        end
        if !isempty(prepare_terms)
            push!(subgoals, prepare_terms)
            setdiff!(terms, prepare_terms)
        end
        # Add cook cluster terms as subgoals
        push!(subgoals, cluster_terms)
        setdiff!(terms, cluster_terms)
        # Add in-receptacle terms as subgoals
        in_receptacle_terms = filter(terms) do term
            term.name == Symbol("in-receptacle") && term.args[1] in cluster
        end
        if !isempty(in_receptacle_terms)
            push!(subgoals, in_receptacle_terms)
            setdiff!(terms, in_receptacle_terms)
        end
    end
    # Add subgoals for each remaining combine cluster
    for (cluster, cluster_terms) in zip(combine_clusters, combine_cluster_terms)
        # Add prepare terms involving cluster ingredients
        prepare_terms = filter(terms) do term
            term.name == :prepared && term.args[2] in cluster
        end
        if !isempty(prepare_terms)
            push!(subgoals, prepare_terms)
            setdiff!(terms, prepare_terms)
        end
        # Add combine cluster terms as subgoals
        push!(subgoals, cluster_terms)
        setdiff!(terms, cluster_terms)
        # Add in-receptacle terms as subgoals
        in_receptacle_terms = filter(terms) do term
            term.name == Symbol("in-receptacle") && term.args[1] in cluster
        end
        if !isempty(in_receptacle_terms)
            push!(subgoals, in_receptacle_terms)
            setdiff!(terms, in_receptacle_terms)
        end
    end
    # Add all remaining terms as subgoals
    if !isempty(terms)
        push!(subgoals, terms)
    end
    return subgoals
end
