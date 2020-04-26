export AbstractPlanner
export set_max_resource, get_call, sample_plan, get_proposal, propose_plan
export BFSPlanner, AStarPlanner, ProbAStarPlanner

"Abstract planner type, which defines the interface for planners."
abstract type AbstractPlanner end

"Call planner without tracing internal random choices."
(planner::AbstractPlanner)(domain::Domain, state::State, goal_spec::GoalSpec) =
    get_call(planner)(planner, domain, state, goal_spec)

(planner::AbstractPlanner)(domain::Domain, state::State, goals::Vector{<:Term}) =
    get_call(planner)(planner, domain, state, GoalSpec(goals))

(planner::AbstractPlanner)(domain::Domain, state::State, goal::Term) =
    get_call(planner)(planner, domain, state, GoalSpec(goal))

"Return copy of the planner with adjusted resource bound."
set_max_resource(planner::AbstractPlanner, val) = planner

"Returns the generative function that defines the planning algorithm."
get_call(::AbstractPlanner)::GenerativeFunction = planner_call

"Abstract planner call interface."
@gen function planner_call(planner::AbstractPlanner,
                           domain::Domain, state::State, goal_spec::GoalSpec)
    error("Not implemented.")
    return plan, traj
end

"Sample a plan given a planner, domain, initial state and goal specification."
@gen function sample_plan(planner::AbstractPlanner,
                          domain::Domain, state::State, goal_spec)
    goal_spec = isa(goal_spec, GoalSpec) ? goal_spec : GoalSpec(goal_spec)
    call = get_call(planner)
    return @trace(call(planner, domain, state, goal_spec))
end

"Returns the data-driven proposal associated with the planning algorithm."
get_proposal(::AbstractPlanner)::GenerativeFunction = planner_propose

"Default data-driven proposal to the planner's internal random choices."
@gen function planner_propose(planner::AbstractPlanner,
                              domain::Domain, state::State, goal_spec::GoalSpec,
                              obs_states::Vector{<:Union{State,Nothing}})
    call = get_call(planner) # Default to proposing from the prior
    return @trace(call(planner, domain, state, goal_spec))
end

"Propose a plan given a planner and a sequence of observed states."
@gen function propose_plan(planner::AbstractPlanner,
                           domain::Domain, state::State, goal_spec,
                           obs_states::Vector{<:Union{State,Nothing}})
    goal_spec = isa(goal_spec, GoalSpec) ? goal_spec : GoalSpec(goal_spec)
    proposal = get_proposal(planner)
    return @trace(proposal(planner, domain, state, goal_spec, obs_states))
end

"Uninformed breadth-first search planner."
@kwdef struct BFSPlanner <: AbstractPlanner
    max_depth::Number = Inf
end

set_max_resource(planner::BFSPlanner, val) = @set planner.max_depth = val

get_call(::BFSPlanner)::GenerativeFunction = bfs_call

"Uninformed breadth-first search for a plan."
@gen function bfs_call(planner::BFSPlanner,
                       domain::Domain, state::State, goal_spec::GoalSpec)
    @unpack goals = goal_spec
    plan, traj = Term[], State[state]
    queue = [(plan, traj)]
    while length(queue) > 0
        plan, traj = popfirst!(queue)
        # Only search up to max_depth
        step = length(plan) + 1
        if step > planner.max_depth continue end
        # Get list of available actions
        state = traj[end]
        actions = available(state, domain)
        # Iterate over actions
        for act in actions
            # Execute actions on state
            next_state = transition(domain, state, act)
            # Add action term to plan sequence
            next_plan = Term[plan; act]
            next_traj = State[traj; next_state]
            # Return plan if goals are satisfied
            sat, _ = satisfy(goals, next_state, domain)
            if sat return (next_plan, next_traj) end
            # Otherwise push to queue
            push!(queue, (next_plan, next_traj))
        end
    end
    return nothing, nothing
end

"Deterministic A* (heuristic search) planner."
@kwdef struct AStarPlanner <: AbstractPlanner
    heuristic::Function = goal_count
    max_nodes::Real = Inf
end

set_max_resource(planner::AStarPlanner, val) = @set planner.max_nodes = val

get_call(::AStarPlanner)::GenerativeFunction = astar_call

"Deterministic A* search for a plan."
@gen function astar_call(planner::AStarPlanner,
                         domain::Domain, state::State, goal_spec::GoalSpec)
    @unpack goals, metric, constraints = goal_spec
    @unpack max_nodes, heuristic = planner
    # Initialize path costs and priority queue
    parents = Dict{State,Tuple{State,Term}}()
    path_costs = Dict{State,Int64}(state => 0)
    queue = PriorityQueue{State,Int64}(state => heuristic(goals, state, domain))
    count = 0
    while length(queue) > 0
        # Get state with lowest estimated cost to goal
        state = dequeue!(queue)
        # Return plan if search budget is reached or goals are satisfied
        if count >= max_nodes || satisfy(goals, state, domain)[1]
            return reconstruct_plan(state, parents) end
        # Get list of available actions
        actions = available(state, domain)
        # Iterate over actions
        for act in actions
            # Execute action and trigger all post-action events
            next_state = transition(domain, state, act)
            # Check if next state satisfies trajectory constraints
            if !isempty(constraints) && !satisfy(constraints, state, domain)[1]
                continue end
            # Compute path cost
            act_cost = metric == nothing ? 1 :
                next_state[domain, metric] - state[domain, metric]
            path_cost = path_costs[state] + act_cost
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

"Probabilistic A* planner with search noise."
@kwdef struct ProbAStarPlanner <: AbstractPlanner
    heuristic::Function = goal_count
    max_nodes::Real = Inf
    search_noise::Real = 1.0
end

set_max_resource(planner::ProbAStarPlanner, val) = @set planner.max_nodes = val

get_call(::ProbAStarPlanner)::GenerativeFunction = prob_astar_call

"Probabilistic A* search for a plan."
@gen function prob_astar_call(planner::ProbAStarPlanner,
                              domain::Domain, state::State, goal_spec::GoalSpec)
    @unpack goals, metric, constraints = goal_spec
    @unpack heuristic, max_nodes, search_noise = planner
    # Initialize path costs and priority queue
    parents = Dict{State,Tuple{State,Term}}()
    path_costs = Dict{State,Int64}(state => 0)
    queue = OrderedDict{State,Int64}(state => heuristic(goals, state, domain))
    # Initialize trace address
    count = 0
    while length(queue) > 0
        # Sample state from queue with probability exp(-beta*est_cost)
        probs = softmax([-v / search_noise for v in values(queue)])
        state = @trace(labeled_cat(collect(keys(queue)), probs), (:node, count))
        delete!(queue, state)
        count += 1
        # Return plan if search budget is reached or goals are satisfied
        if count >= max_nodes || satisfy(goals, state, domain)[1]
            return reconstruct_plan(state, parents)
        end
        # Get list of available actions
        actions = available(state, domain)
        # Iterate over actions
        for act in actions
            # Execute action and trigger all post-action events
            next_state = transition(domain, state, act)
            # Check if next state satisfies trajectory constraints
            if !isempty(constraints) && !satisfy(constraints, state, domain)[1]
                continue end
            # Compute path cost
            act_cost = metric == nothing ? 1 :
                next_state[domain, metric] - state[domain, metric]
            path_cost = path_costs[state] + act_cost
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
