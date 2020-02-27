using DataStructures: PriorityQueue, OrderedDict, enqueue!, dequeue!

"Uninformed forward search for a plan."
function basic_search(goals::Vector{<:Term}, state::State, domain::Domain;
                      horizon::Number=Inf)
    plan = Term[]
    queue = [(state, plan)]
    while length(queue) > 0
        state, plan = popfirst!(queue)
        # Only plan up to length of horizon
        step = length(plan) + 1
        if step > horizon continue end
        # Get list of available actions
        actions = available(state, domain)
        # Iterate over actions
        for act in actions
            # Execute actions on state
            next_state = execute(act, state, domain)
            # Add action term to plan sequence
            next_plan = Term[plan; act]
            # Trigger all post-action events
            next_state = trigger(domain.events, next_state, domain)
            # Return plan if goals are satisfied
            sat, _ = satisfy(goals, next_state, domain)
            if sat return next_plan end
            # Otherwise push to queue
            push!(queue, (next_state, next_plan))
        end
    end
    return nothing
end

"Reconstruct plan from current state and back-pointers."
function reconstruct_plan(state::State, parents::Dict{State,Tuple{State,Term}})
    plan = Term[]
    while state in keys(parents)
        state, act = parents[state]
        pushfirst!(plan, act)
    end
    return plan
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
    return nothing
end

"Heuristic that counts the number of goals unsatisfied in the domain."
function goal_count(goals, state, domain)
    count = 0
    for g in goals
        sat, _ = satisfy(g, state, domain)
        count += sat ? 0 : 1
    end
    return count
end

"Manhattan distance heuristic."
function manhattan(goals, state, domain; fluents=@julog([xpos, ypos]))
    goal = PDDL.clauses_to_state(Vector{Clause}(goals))
    goal_vals = [evaluate(f, goal, domain) for f in fluents]
    curr_vals = [evaluate(f, state, domain) for f in fluents]
    dist = sum(abs(g.name - c.name) for (g, c) in zip(goal_vals, curr_vals))
    return dist
end

"Sample-based heuristic search for a plan."
@gen function sample_search(goals::Vector{<:Term}, state::State, domain::Domain,
                            heuristic::Function, search_noise::Float64)
    # Remove conjunctions in goals
    goals = reduce(vcat, map(g -> (g.name == :and) ? g.args : Term[g], goals))
    # Initialize path costs and priority queue
    parents = Dict{State,Tuple{State,Term}}()
    path_costs = Dict{State,Int64}(state => 0)
    queue = OrderedDict{State,Int64}(state => heuristic(goals, state, domain))
    # Initialize trace address
    count = 0
    addr = (:init, count)
    while length(queue) > 0
        # Sample state from queue with probability exp(-beta*est_cost)
        probs = [exp(-search_noise*v) for v in values(queue)]
        probs /= sum(probs)
        idx = @trace(categorical(probs), addr)
        state, _ = iterate(queue, idx)[1]
        delete!(queue, state)
        # Update trace address, indexing by state and count
        count += 1
        addr = (hash(state), count)
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
                    est_cost = path_cost + heuristic(goals, state, domain)
                    queue[next_state] = est_cost
                else
                    queue[next_state] -= cost_diff
                end
            end
        end
    end
    return nothing
end
