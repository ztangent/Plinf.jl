using DataStructures: PriorityQueue, OrderedDict, enqueue!, dequeue!

"Uninformed forward search for a plan."
function basic_search(goals::Vector{<:Term}, state::State, domain::Domain;
                      horizon::Number=Inf)
    plan, traj = Term[], State[state]
    queue = [(plan, traj)]
    while length(queue) > 0
        plan, traj = popfirst!(queue)
        # Only plan up to length of horizon
        step = length(plan) + 1
        if step > horizon continue end
        # Get list of available actions
        state = traj[end]
        actions = available(state, domain)
        # Iterate over actions
        for act in actions
            # Execute actions on state
            next_state = execute(act, state, domain)
            # Add action term to plan sequence
            next_plan = Term[plan; act]
            # Trigger all post-action events
            next_state = trigger(domain.events, next_state, domain)
            next_traj = State[traj; next_state]
            # Return plan if goals are satisfied
            sat, _ = satisfy(goals, next_state, domain)
            if sat return (next_plan, next_traj) end
            # Otherwise push to queue
            push!(queue, (next_plan, next_traj))
        end
    end
    return nothing
end

"Reconstruct plan from current state and back-pointers."
function reconstruct_plan(state::State, parents::Dict{State,Tuple{State,Term}})
    plan, traj = Term[], State[state]
    while state in keys(parents)
        state, act = parents[state]
        pushfirst!(plan, act)
        pushfirst!(traj, state)
    end
    return plan, traj
end

"Heuristic-informed forward search for a plan."
function heuristic_search(goals::Vector{<:Term}, state::State, domain::Domain;
                          heuristic::Function=goal_count)
    # Remove conjunctions in goals
    goals = reduce(vcat, map(g -> (g.name == :and) ? g.args : Term[g], goals))
    # Initialize path costs and priority queue
    parents = Dict{State,Tuple{State,Term}}()
    path_costs = Dict{State,Int64}(state => 0)
    queue = PriorityQueue{State,Int64}(state => heuristic(goals, state, domain))
    while length(queue) > 0
        # Get state with lowest estimated cost to goal
        state = dequeue!(queue)
        # Return plan if goals are satisfied
        sat, _ = satisfy(goals, state, domain)
        if sat return reconstruct_plan(state, parents) end
        # Get list of available actions
        actions = available(state, domain)
        # Iterate over actions
        for act in actions
            # Execute action and trigger all post-action events
            next_state = execute(act, state, domain)
            next_state = trigger(domain.events, next_state, domain)
            path_cost = path_costs[state] + 1
            # Update path costs if new path is shorter
            cost_diff = get(path_costs, next_state, Inf) - path_cost
            if cost_diff > 0
                parents[next_state] = (state, act)
                path_costs[next_state] = path_cost
                # Update estimated cost from next state to goal
                if !(next_state in keys(queue))
                    est_cost = path_cost + heuristic(goals, next_state, domain)
                    enqueue!(queue, next_state, est_cost)
                else
                    queue[next_state] -= cost_diff
                end
            end
        end
    end
    return nothing, nothing
end

"Sample-based heuristic search for a plan."
@gen function sample_search(goals::Vector{<:Term}, state::State, domain::Domain,
                            search_noise::Float64=0.1, max_nodes::Number=Inf,
                            heuristic::Function=manhattan)
    # Remove conjunctions in goals
    goals = reduce(vcat, map(g -> (g.name == :and) ? g.args : Term[g], goals))
    # Initialize path costs and priority queue
    parents = Dict{State,Tuple{State,Term}}()
    path_costs = Dict{State,Int64}(state => 0)
    queue = OrderedDict{State,Int64}(state => heuristic(goals, state, domain))
    # Initialize trace address
    node_count = 0
    addr = (:init, node_count)
    while length(queue) > 0
        # Sample state from queue with probability exp(-beta*est_cost)
        probs = [exp(-search_noise*v) for v in values(queue)]
        probs /= sum(probs)
        idx = @trace(categorical(probs), addr)
        state, _ = iterate(queue, idx)[1]
        delete!(queue, state)
        # Update trace address, indexing by state and count
        node_count += 1
        addr = (hash(state), node_count)
        # Return plan if max nodes is reached or goals are satisfied
        if node_count >= max_nodes || satisfy(goals, state, domain)[1]
            return reconstruct_plan(state, parents)
        end
        # Get list of available actions
        actions = available(state, domain)
        # Iterate over actions
        for act in actions
            # Execute action and trigger all post-action events
            next_state = execute(act, state, domain)
            next_state = trigger(domain.events, next_state, domain)
            path_cost = path_costs[state] + 1
            # Update path costs if new path is shorter
            cost_diff = get(path_costs, next_state, Inf) - path_cost
            if cost_diff > 0
                parents[next_state] = (state, act)
                path_costs[next_state] = path_cost
                # Update estimated cost from next state to goal
                if !(next_state in keys(queue))
                    est_cost = path_cost + heuristic(goals, state, domain)
                    queue[next_state] = est_cost
                else
                    queue[next_state] -= cost_diff
                end
            end
        end
    end
    return nothing, nothing
end

@gen function replan_search(goals::Vector{<:Term}, state::State, domain::Domain,
                            search_noise::Float64=0.1, persistence::Float64=0.9,
                            max_plans::Int=10, heuristic::Function=manhattan)
    count = 0
    plan, traj = Term[], State[]
    while count < max_plans
        # Sample a maximum number of nodes to expand during search
        max_nodes = @trace(geometric(1-persistence), (:max_nodes, count))
        # Plan to achieve the goals until the maximum node budget
        part_plan, part_traj = @trace(sample_search(goals, state, domain,
            search_noise, max_nodes, heuristic), (:plan, count))
        if part_plan == nothing return (plan, traj) end
        # Append the partial plan and state trajectory
        append!(plan, part_plan)
        append!(traj, part_traj)
        # Continue planning from the end of the trajectory
        state = traj[end]
        # Return plan if the goals are satisfied
        sat, _ = satisfy(goals, state, domain)
        if sat return (plan, traj) end
        count += 1
    end
end
