using Base: @kwdef
using PDDL, SymbolicPlanners
import SymbolicPlanners: Planner, OrderedSolution
import SymbolicPlanners: precompute!, compute, is_precomputed

include("recipe_utils.jl")

struct OvercookedPlannerSolution <: OrderedSolution
    plan::Vector{Term}
    subplans::Vector{Vector{Term}}
    subgoals::Vector{Vector{Term}}
end

Base.copy(sol::OvercookedPlannerSolution) =
    OvercookedPlannerSolution(copy(sol.plan), copy(sol.subplans), copy(sol.subgoals))

get_action(sol::OvercookedPlannerSolution, t::Int) = sol.plan[t]

Base.iterate(sol::OvercookedPlannerSolution) = iterate(sol.plan)
Base.iterate(sol::OvercookedPlannerSolution, istate) = iterate(sol.plan, istate)
Base.getindex(sol::OvercookedPlannerSolution, i::Int) = getindex(sol.plan, i)
Base.length(sol::OvercookedPlannerSolution) = length(sol.plan)

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
    # Check if goal can be solved using subplanner heuristic
    if hasproperty(planner.planner, :heuristic)
        hval = planner.planner.heuristic(domain, state, goal)
        if hval == Inf
            return NullSolution(:failure)
        end
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
    subplans = Vector{Term}[]
    for goals in subgoals
        if planner.verbose
            println("Subgoals: ", join(write_pddl.(goals), ", "))
        end
        if isempty(goals)
            push!(subplans, Term[])
            continue
        end
        # Check if time limit has been exceeded
        time_elapsed = time() - start_time
        time_left = planner.max_time - time_elapsed
        if time_left < 0
            return NullSolution(:max_time)
        end
        planner.planner.max_time = time_left
        # Check if subgoals can be solved using subplanner heuristic
        if hasproperty(planner.planner, :heuristic)
            hval = planner.planner.heuristic(domain, state, goals)
            if hval == Inf
                return NullSolution(:failure)
            end
        end
        # Check if any negative goals are irreversibly satisfied
        irreversible = (
            :prepared, 
            :combined, Symbol("is-combined"), Symbol("combined-with"),
            :cooked, Symbol("is-cooked"), Symbol("cooked-with")
        )
        for term in goals
            term.name != :not && continue
            term = term.args[1]
            if (term.name in irreversible && state[term])
                return NullSolution(:failure)
            end
        end
        # Check for negative interactions among combine and cook  goals
        for term in goals
            if term.name == Symbol("combined-with")
                state[term] && continue
                t1 = Compound(:combined, term.args[[1, 2]])
                t2 = Compound(:combined, term.args[[1, 3]])
                if state[t1] || state[t2]
                    return NullSolution(:failure)
                end
            end
            if term.name == Symbol("cooked-with")
                state[term] && continue
                t1 = Compound(:cooked, term.args[[1, 2]])
                t2 = Compound(:cooked, term.args[[1, 3]])
                if state[t1] || state[t2]
                    return NullSolution(:failure)
                end
            end
        end
        # Run planner
        sol = planner.planner(domain, state, goals)
        if sol.status != :success
            return NullSolution(sol.status)
        end
        # Collect subplan
        actions = collect(sol)
        if planner.verbose
            println("Subplan: ", join(write_pddl.(actions), ", "))
        end
        push!(subplans, actions)
        # Advance to last state of subplan
        state = sol.trajectory[end]
    end
    plan = reduce(vcat, subplans)
    # Check that goal is satisfied
    if !PDDL.satisfy(domain, state, goal) 
        return NullSolution()
    end
    return OvercookedPlannerSolution(plan, subplans, subgoals)
end

"Custom landmark-based heuristic for Overcooked problems."
@kwdef mutable struct OvercookedHeuristic{H <: Heuristic, F} <: Heuristic
    heuristic::H = FFHeuristic() # Sub-heuristic to evaluate distance to each subgoal 
    op::F = sum # Aggregation operator for sub-heuristic costs
    ordering::Symbol = :predicate # How to order subgoals
    subgoals::Dict{UInt,Vector{Vector{Term}}} = Dict{UInt,Vector{Vector{Term}}}()
end

function precompute!(h::OvercookedHeuristic,
                     domain::Domain, state::State, spec::Specification)
    precompute!(h.heuristic, domain, state, spec)
    return h
end

function precompute!(h::OvercookedHeuristic,
                     domain::Domain, state::State)
    precompute!(h.heuristic, domain, state)
    return h
end

is_precomputed(h::OvercookedHeuristic) = is_precomputed(h.heuristic)

function compute(h::OvercookedHeuristic,
                 domain::Domain, state::State, spec::Specification)
    # Compute subgoals if not already cached
    spec_hash = hash(spec)
    subgoals = get!(h.subgoals, spec_hash) do 
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
        if h.ordering == :predicate
            subgoals = order_subgoals_by_predicate(goal)
            subgoals = filter(sg -> !isempty(sg), subgoals)
        elseif h.ordering == :cluster
            subgoals = order_subgoals_by_cluster(goal)
        else
            error("Unrecognized ordering flag: $(planner.ordering)")
        end
        return subgoals
    end
    # Compute and aggregate heuristic values across subgoals
    hvals = (compute(h.heuristic, domain, state, sg) for sg in subgoals)
    return length(subgoals) == 0 ? 0 : h.op(hvals)
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
        elseif term.name in (:combined, Symbol("combined-with"))
            push!(combine_goals, term)
        elseif term.name in (:cooked, Symbol("cooked-with"))
            push!(cook_goals, term)
        elseif term.name == Symbol("in-receptacle")
            push!(serve_goals, term)
        elseif term.name != :not
            push!(misc_goals, term)
        end
    end
    all_subgoals = [prepare_goals, combine_goals, cook_goals,
                    serve_goals, misc_goals]
    # Ensure negative terms are added to each non-empty subgoal list
    neg_terms = filter(t -> t.name == :not, subgoals)
    if !isempty(neg_terms)
        for gs in all_subgoals
            isempty(gs) || append!(gs, neg_terms)
        end
    end
    return all_subgoals
end

"Orders subgoals in a recipe by ingredient cluster."
function order_subgoals_by_cluster(goal::Term)
    subgoals = Vector{Term}[]
    # Extract ingredients and recipe terms
    ingredients = extract_ingredients(goal)
    terms = PDDL.flatten_conjs(goal)
    # Extract negative terms
    neg_terms = filter(t -> t.name == :not, terms)
    setdiff!(terms, neg_terms)
    # Extract combine clusters
    combine_clusters, combine_cluster_terms = 
        extract_ingredient_clusters(goal, Symbol("combined-with"))
    for term in terms # Add ingredients cooked on their own
        term.name == :combined || continue
        pushfirst!(combine_clusters, [term.args[2]])
        pushfirst!(combine_cluster_terms, [[term]; neg_terms])
    end
    # Extract cook clusters
    cook_clusters, cook_cluster_terms = 
        extract_ingredient_clusters(goal, Symbol("cooked-with"))
    for term in terms # Add ingredients cooked on their own
        term.name == :cooked || continue
        pushfirst!(cook_clusters, [term.args[2]])
        pushfirst!(cook_cluster_terms, [[term]; neg_terms])
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
    # Ensure negative goals are added to each non-empty subgoal list
    if !isempty(neg_terms)
        for gs in subgoals
            isempty(gs) || append!(gs, neg_terms)
        end
    end
    return subgoals
end
