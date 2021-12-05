export BackwardPlanner

"Heuristic-guided backward search planner."
@kwdef struct BackwardPlanner <: Planner
    heuristic::Heuristic = GoalCountHeuristic(:backward)
    h_mult::Real = 1
    max_nodes::Real = Inf
    trace_states::Bool = false
end

set_max_resource(planner::BackwardPlanner, val) = @set planner.max_nodes = val

get_call(::BackwardPlanner)::GenerativeFunction = bwd_call

"Deterministic backward search for a plan."
@gen function bwd_call(planner::BackwardPlanner,
                       domain::Domain, state::State, spec::Specification)
    @unpack max_nodes, h_mult, heuristic, trace_states = planner
    # Perform any precomputation required by the heuristic
    heuristic = precompute(heuristic, domain, state, spec)
    # Convert to backward search goal specification
    spec = BackwardSearchGoal(spec, state)
    state = goalstate(domain, PDDL.get_objtypes(state), get_goal_terms(spec))
    # Initialize path costs and priority queue
    state_hash = hash(state)
    state_dict = Dict{UInt,State}(state_hash => state)
    parents = Dict{UInt,Tuple{UInt,Term}}()
    path_costs = Dict{UInt,Float64}(state_hash => 0)
    est_cost = heuristic(domain, state, spec)
    queue = PriorityQueue{UInt,Float64}(state_hash => est_cost)
    count = 1
    while length(queue) > 0
        # Get state with lowest estimated cost to goal
        state_hash = dequeue!(queue)
        state = state_dict[state_hash]
        if trace_states @trace(labeled_unif([state]), (:state, count)) end
        # Return plan if search budget is reached or initial state is implied
        if count >= max_nodes
            return nothing, nothing
        elseif is_goal(spec, domain, state)
            plan, traj = reconstruct_plan(state_hash, state_dict, parents)
            return reverse!(plan), reverse!(traj)
        end
        count += 1
        # Get list of relevant actions
        actions = relevant(domain, state)
        # Iterate over actions
        for act in actions
            # Regress (reverse-execute) the action
            prev_state = regress(domain, state, act; check=false)
            # Add constraints to regression state
            add_constraints!(spec, domain, state)
            prev_hash = hash(prev_state)
            # Compute path cost
            act_cost = get_cost(spec, domain, state, act, prev_state)
            path_cost = path_costs[state_hash] + act_cost
            # Update path costs if new path is shorter
            cost_diff = get(path_costs, prev_hash, Inf) - path_cost
            if cost_diff > 0
                if !(prev_hash in keys(state_dict))
                    state_dict[prev_hash] = prev_state end
                parents[prev_hash] = (state_hash, act)
                path_costs[prev_hash] = path_cost
                # Update estimated cost from prev state to start
                if !(prev_hash in keys(queue))
                    est_remain_cost = heuristic(domain, prev_state, spec)
                    est_remain_cost *= h_mult
                    enqueue!(queue, prev_hash, path_cost + est_remain_cost)
                else
                    queue[prev_hash] -= cost_diff
                end
            end
        end
    end
    return nothing, nothing
end
