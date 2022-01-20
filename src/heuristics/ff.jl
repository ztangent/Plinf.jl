## FastForward (FF) delete-relaxation heuristic ##
export FFHeuristic

"FastForward (FF) delete-relaxation heuristic."
struct FFHeuristic <: Heuristic
    graph::PlanningGraph # Precomputed planning graph
    goal_idxs::Union{Nothing,Set{Int}} # Precomputed list of goal indices
    FFHeuristic() = new()
    FFHeuristic(graph, goal_idxs) = new(graph, goal_idxs)
end

Base.hash(heuristic::FFHeuristic, h::UInt) = hash(FFHeuristic, h)

function precompute(h::FFHeuristic,
                    domain::Domain, state::State, spec::Specification)
    if isdefined(h, :graph) && isdefined(h, :goal_idxs) return h end
    # Build planning graph and find goal condition indices
    goal_conds = PDDL.to_cnf_clauses(get_goal_terms(spec))
    graph = build_planning_graph(domain, state, goal_conds)
    goal_idxs = Set(findall(c -> c in goal_conds, graph.conditions))
    return FFHeuristic(graph, goal_idxs)
end

function precompute(h::FFHeuristic,
                    domain::Domain, state::State, spec::NullGoal)
    if isdefined(h, :graph) && isdefined(h, :goal_idxs) return h end
    graph = build_planning_graph(domain, state)
    return FFHeuristic(graph, nothing)
end

function compute(h::FFHeuristic,
                 domain::Domain, state::State, spec::Specification)
    # Precompute if necessary
    if !isdefined(h, :graph)
        h = precompute(h, domain, state, spec)
    end
    # Construct goal indices if necessary
    if h.goal_idxs === nothing
        goal_conds = PDDL.to_cnf_clauses(get_goal_terms(spec))
        goal_idxs = Set(findall(c -> c in goal_conds, h.graph.conditions))
    else
        goal_idxs = h.goal_idxs
    end
    # Compute achievers to each condition node of the relaxed planning graph
    _, achievers = relaxed_graph_search(domain, state, spec,
                                        maximum, h.graph, h.goal_idxs)
    # Extract relaxed plan via backward chaining
    plan = Int[]
    queue = collect(goal_idxs)
    while length(queue) > 0
        cond_idx = popfirst!(queue)
        act_idx = achievers[cond_idx]
        act_idx == -1 && continue # Skip conditions achieved from the start
        push!(plan, act_idx)
        append!(queue, h.graph.act_parents[act_idx])
    end
    # TODO: Store helpful actions
    # Return length of relaxed plan as heuristic estimate
    return length(plan)
end
