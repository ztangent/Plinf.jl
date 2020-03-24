using DataStructures: PriorityQueue, OrderedDict, enqueue!, dequeue!

"Sample a plan given a planner, goal, initial state and domain."
@gen function sample_plan(planner, goal, state, domain, args)
    if isa(planner, GenerativeFunction)
        return @trace(planner(goal, state, domain, args...))
    else
        return planner(goal, state, domain, args...)
    end
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
    count = 0
    while length(queue) > 0
        # Return plan to state with best heuristic value if max nodes is reached
        if count >= max_nodes
            state = findmax(queue)[2]
            return reconstruct_plan(state, parents)
        end
        # Sample state from queue with probability exp(-beta*est_cost)
        probs = softmax([-search_noise*v for v in values(queue)])
        state = @trace(labeled_cat(collect(keys(queue)), probs), (:node, count))
        delete!(queue, state)
        count += 1
        # Return plan if goals are satisfied
        if satisfy(goals, state, domain)[1]
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

struct ReplanState
    rel_step::Int
    plan_length::Int
    part_plan::Vector{Term}
    part_traj::Vector{State}
end

@gen function replan_step(t::Int, rp::ReplanState,
                          goals::Vector{<:Term}, domain::Domain,
                          search_noise::Float64=0.1, persistence::Float64=0.9,
                          heuristic::Function=manhattan, observe=nothing)
    # Get most recent world state
    state = rp.part_traj[rp.rel_step]
    # If plan has already reached this time step, do nothing
    if t <= rp.plan_length
        if observe != nothing @trace(observe(state)) end
        rel_step = rp.rel_step + 1
        return ReplanState(rel_step, rp.plan_length, rp.part_plan, rp.part_traj)
    end
    # Sample a maximum number of nodes to expand during search
    max_nodes = @trace(geometric(1-persistence), :max_nodes)
    # Plan to achieve the goals until the maximum node budget
    part_plan, part_traj = @trace(sample_search(goals, state, domain,
        search_noise, max_nodes, heuristic), :plan)
    if part_plan == nothing || length(part_plan) == 0
        # Return no-op if goal is reached or no satisfying plan can be found
        part_plan, part_traj = Term[@julog(idle())], State[state]
    else
        # Don't double count initial state
        part_traj = part_traj[2:end]
    end
    if observe != nothing @trace(observe(part_traj[1])) end
    plan_length = rp.plan_length + length(part_plan)
    return ReplanState(1, plan_length, part_plan, part_traj)
end

replan_step_unfold = Unfold(replan_step)

function extract_plan(rp_states)
    plan = Term[rp.part_plan[rp.rel_step] for rp in rp_states]
    if length(rp_states[end].part_plan) > rp_states[end].rel_step
        tail = rp_states[end].part_plan[rp_states[end].rel_step+1:end]
        append!(plan, tail)
    end
    return plan
end

function extract_traj(rp_states)
    traj = State[rp.part_traj[rp.rel_step] for rp in rp_states]
    if length(rp_states[end].part_traj) > rp_states[end].rel_step
        tail = rp_states[end].part_traj[rp_states[end].rel_step+1:end]
        append!(traj, tail)
    end
    return traj
end

@gen function replan_search(timesteps::Int, goals::Vector{<:Term},
                            state::State, domain::Domain,
                            search_noise::Float64=0.1, persistence::Float64=0.9,
                            heuristic::Function=manhattan)
    rp_init = ReplanState(1, 0, Term[], [state])
    rp_states = @trace(replan_step_unfold(timesteps, rp_init, goals, domain,
                                          search_noise, persistence, heuristic),
                       :replan)
    plan = extract_plan(rp_states)
    traj = [state; extract_traj(rp_states)]
    return plan, traj
end
