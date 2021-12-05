## FastForward (FF) delete-relaxation heuristic ##
export FFHeuristic

"FastForward (FF) delete-relaxation heuristic."
struct FFHeuristic <: Heuristic
    graph::PlanningGraph # Precomputed planning graph
    goal_idxs::Set{Int} # Precomputed list of goal indices
    FFHeuristic() = new()
    FFHeuristic(graph, goal_idxs) = new(graph, goal_idxs)
end

Base.hash(heuristic::FFHeuristic, h::UInt) = hash(FFHeuristic, h)

function precompute(h::FFHeuristic,
                    domain::Domain, state::State, spec::Specification)
    # Build planning graph and find goal condition indices
    goal_conds = PDDL.to_cnf_clauses(get_goal_terms(spec))
    graph = build_planning_graph(domain, state, goal_conds)
    goal_idxs = Set(findall(c -> c in goal_conds, graph.conditions))
    return FFHeuristic(graph, goal_idxs)
end

function compute(h::FFHeuristic,
                 domain::Domain, state::State, spec::Specification)
    # Precompute if necessary
    if !isdefined(h, :graph)
        h = precompute(h, domain, state, spec)
    end
    # Compute achievers to each condition node of the relaxed planning graph
    _, achievers = relaxed_graph_search(domain, state, spec,
                                        maximum, h.graph, h.goal_idxs)
    # Extract relaxed plan via backward chaining
    plan = Int[]
    queue = collect(h.goal_idxs)
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
