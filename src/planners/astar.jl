export AStarPlanner, ProbAStarPlanner

"Deterministic A* (heuristic search) planner."
@kwdef struct AStarPlanner <: Planner
    heuristic::Heuristic = GoalCountHeuristic()
    h_mult::Real = 1
    max_nodes::Real = Inf
    trace_states::Bool = false
end

set_max_resource(planner::AStarPlanner, val) = @set planner.max_nodes = val

get_call(::AStarPlanner)::GenerativeFunction = astar_call

"Deterministic A* search for a plan."
@gen function astar_call(planner::AStarPlanner,
                         domain::Domain, state::State, goal_spec::GoalSpec)
    @unpack goals, metric, constraints = goal_spec
    @unpack max_nodes, h_mult, heuristic, trace_states = planner
    # Perform any precomputation required by the heuristic
    heuristic = precompute(heuristic, domain, state, goal_spec)
    # Initialize path costs and priority queue
    state_hash = hash(state)
    state_dict = Dict{UInt,State}(state_hash => state)
    parents = Dict{UInt,Tuple{UInt,Term}}()
    path_costs = Dict{UInt,Float64}(state_hash => 0)
    est_cost = heuristic(domain, state, goal_spec)
    queue = PriorityQueue{UInt,Float64}(state_hash => est_cost)
    count = 1
    while length(queue) > 0
        # Get state with lowest estimated cost to goal
        state_hash = dequeue!(queue)
        state = state_dict[state_hash]
        if trace_states @trace(labeled_unif([state]), (:state, count)) end
        # Return plan if search budget is reached or goals are satisfied
        if count >= max_nodes || satisfy(goals, state, domain)[1]
            @info "Node Count: $count"
            return reconstruct_plan(state_hash, state_dict, parents) end
        count += 1
        # Get list of available actions
        actions = available(state, domain)
        # Iterate over actions
        for act in actions
            # Execute action and trigger all post-action events
            next_state = transition(domain, state, act; check=false)
            next_hash = hash(next_state)
            # Check if next state satisfies trajectory constraints
            if !isempty(constraints) && !satisfy(constraints, state, domain)[1]
                continue end
            # Compute path cost
            act_cost = metric == nothing ? 1 :
                next_state[domain, metric] - state[domain, metric]
            path_cost = path_costs[state_hash] + act_cost
            # Update path costs if new path is shorter
            cost_diff = get(path_costs, next_hash, Inf) - path_cost
            if cost_diff > 0
                if !(next_hash in keys(state_dict))
                    state_dict[next_hash] = next_state end
                parents[next_hash] = (state_hash, act)
                path_costs[next_hash] = path_cost
                # Update estimated cost from next state to goal
                if !(next_hash in keys(queue))
                    est_remain_cost = heuristic(domain, next_state, goal_spec)
                    est_remain_cost *= h_mult
                    enqueue!(queue, next_hash, path_cost + est_remain_cost)
                else
                    queue[next_hash] -= cost_diff
                end
            end
        end
    end
    return nothing, nothing
end

"Probabilistic A* planner with search noise."
@kwdef struct ProbAStarPlanner <: Planner
    heuristic::Heuristic = GoalCountHeuristic()
    max_nodes::Real = Inf
    search_noise::Real = 1.0
    trace_states::Bool = false
end

set_max_resource(planner::ProbAStarPlanner, val) = @set planner.max_nodes = val

get_call(::ProbAStarPlanner)::GenerativeFunction = aprob_call

"Probabilistic A* search for a plan."
@gen function aprob_call(planner::ProbAStarPlanner,
                         domain::Domain, state::State, goal_spec::GoalSpec)
    @unpack goals, metric, constraints = goal_spec
    @unpack heuristic, max_nodes, search_noise, trace_states = planner
    # Perform any precomputation required by the heuristic
    heuristic = precompute(heuristic, domain, state, goal_spec)
    # Initialize path costs and priority queue
    state_hash = hash(state)
    state_dict = Dict{UInt,State}(state_hash => state)
    parents = Dict{UInt,Tuple{UInt,Term}}()
    path_costs = Dict{UInt,Float64}(state_hash => 0)
    est_cost = heuristic(domain, state, goal_spec)
    queue = OrderedDict{UInt,Float64}(state_hash => est_cost)
    # Initialize node count
    count = 1
    while length(queue) > 0
        # Sample state from queue with probability exp(-beta*est_cost)
        probs = softmax([-v / search_noise for v in values(queue)])
        state_hash =
            @trace(labeled_cat(collect(keys(queue)), probs), (:node, count))
        state = state_dict[state_hash]
        if trace_states @trace(labeled_unif([state]), (:state, count)) end
        delete!(queue, state_hash)
        # Return plan if search budget is reached or goals are satisfied
        if count >= max_nodes || satisfy(goals, state, domain)[1]
            @info "Node Count: $count"
            return reconstruct_plan(state_hash, state_dict, parents)
        end
        count += 1
        # Get list of available actions
        actions = available(state, domain)
        # Iterate over actions
        for act in actions
            # Execute action and trigger all post-action events
            next_state = transition(domain, state, act; check=false)
            next_hash = hash(next_state)
            # Check if next state satisfies trajectory constraints
            if !isempty(constraints) && !satisfy(constraints, state, domain)[1]
                continue end
            # Compute path cost
            act_cost = metric == nothing ? 1 :
                next_state[domain, metric] - state[domain, metric]
            path_cost = path_costs[state_hash] + act_cost
            # Update path costs if new path is shorter
            cost_diff = get(path_costs, next_hash, Inf) - path_cost
            if cost_diff > 0
                if !(next_hash in keys(state_dict))
                    state_dict[next_hash] = next_state end
                parents[next_hash] = (state_hash, act)
                path_costs[next_hash] = path_cost
                # Update estimated cost from next state to goal
                if !(next_hash in keys(queue))
                    est_remain_cost = heuristic(domain, next_state, goal_spec)
                    queue[next_hash] = path_cost + est_remain_cost
                else
                    queue[next_hash] -= cost_diff
                end
            end
        end
    end
    return nothing, nothing
end

"Returns the data-driven proposal associated with the planning algorithm."
get_proposal(::ProbAStarPlanner)::GenerativeFunction = aprob_propose

"Data-driven proposal for probabilistic A* search."
@gen function aprob_propose(planner::ProbAStarPlanner,
                            domain::Domain, state::State, goal_spec::GoalSpec,
                            obs_states::Vector{<:Union{State,Nothing}})
    @param obs_bias::Float64 # How much more likely an observed state is sampled
    @unpack goals, metric, constraints = goal_spec
    @unpack heuristic, max_nodes, search_noise, trace_states = planner
    # Perform any precomputation required by the heuristic
    heuristic = precompute(heuristic, domain, state, goal_spec)
    # Initialize path costs and priority queue
    state_hash = hash(state)
    state_dict = Dict{UInt,State}(state_hash => state)
    parents = Dict{UInt,Tuple{UInt,Term}}()
    path_costs = Dict{UInt,Float64}(state_hash => 0)
    est_cost = heuristic(domain, state, goal_spec)
    queue = OrderedDict{UInt,Float64}(state_hash => est_cost)
    # Initialize observation queue and descendants
    obs_queue = [s == nothing ? nothing : hash(s) for s in obs_states]
    last_idx = findlast(s -> s != nothing, obs_states)
    obs_descs = last_idx == nothing ?
        Set{UInt}() : Set{UInt}([hash(obs_states[last_idx])])
    # Initialize node count
    count = 1
    while length(queue) > 0
        # Compute (un-normalized) original probabilities of sampling each state
        max_score = - minimum(values(queue)) / search_noise
        probs = OrderedDict(s => exp(-v / search_noise - max_score)
                            for (s, v) in queue)
        if count >= max_nodes && isempty(obs_queue) &&
           !isempty(intersect(obs_descs, keys(probs)))
            # Select final node to be a descendant of the last observation
            for s in obs_descs
                probs[s] += obs_bias * (exp(0) + probs[s]) end
            probs = collect(values(probs)) ./ sum(values(probs))
            state_hash = @trace(labeled_cat(collect(keys(queue)), probs),
                                (:node, count))
            if trace_states
                state = state_dict[state_hash]
                @trace(labeled_unif([state]), (:state, count))
            end
            return reconstruct_plan(state_hash, state_dict, parents)
        elseif isempty(obs_queue)
            # Bias search towards descendants
            for s in intersect(obs_descs, keys(probs))
                probs[s] += obs_bias * (exp(0) + probs[s]) end
        elseif obs_queue[1] != nothing && obs_queue[1] in keys(probs)
            # Bias search towards observed states
            obs_hash = obs_queue[1]
            nodes_left = max_nodes - count + 1
            node_mult = min(0.5 * length(obs_queue) / nodes_left, 10)
            probs[obs_hash] += node_mult * obs_bias * (exp(0) + probs[obs_hash])
        end
        probs = collect(values(probs)) ./ sum(values(probs))
        state_hash =
            @trace(labeled_cat(collect(keys(queue)), probs), (:node, count))
        state = state_dict[state_hash]
        if trace_states @trace(labeled_unif([state]), (:state, count)) end
        # Remove states / observations from respective queues
        delete!(queue, state_hash)
        if !isempty(obs_queue) &&
            (obs_queue[1] == nothing || obs_queue[1] == state_hash)
            popfirst!(obs_queue) end
        # Return plan if goals are satisfied
        if count >= max_nodes || satisfy(goals, state, domain)[1]
            return reconstruct_plan(state_hash, state_dict, parents)
        end
        count += 1
        # Get list of available actions
        actions = available(state, domain)
        # Iterate over actions
        for act in actions
            # Execute action and trigger all post-action events
            next_state = transition(domain, state, act; check=false)
            next_hash = hash(next_state)
            # Check if next state satisfies trajectory constraints
            if !isempty(constraints) && !satisfy(constraints, state, domain)[1]
                continue end
            # Compute path cost
            act_cost = metric == nothing ? 1 :
                next_state[domain, metric] - state[domain, metric]
            path_cost = path_costs[state_hash] + act_cost
            # Update path costs if new path is shorter
            cost_diff = get(path_costs, next_hash, Inf) - path_cost
            if cost_diff > 0
                if !(next_hash in keys(state_dict))
                    state_dict[next_hash] = next_state end
                parents[next_hash] = (state_hash, act)
                path_costs[next_hash] = path_cost
                # Update estimated cost from next state to goal
                if !(next_hash in keys(queue))
                    est_remain_cost = heuristic(domain, next_state, goal_spec)
                    queue[next_hash] = path_cost + est_remain_cost
                else
                    queue[next_hash] -= cost_diff
                end
                # Add next state to descendants of observations
                if state_hash in obs_descs push!(obs_descs, next_hash) end
            end
        end
        # Remove state from observation descendants once expanded
        if state_hash in obs_descs delete!(obs_descs, state_hash) end
    end
    return nothing, nothing
end

# Initialize bias towards sampling observed states
init_param!(aprob_propose, :obs_bias, 2)
