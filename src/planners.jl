export Planner, BFSPlanner, AStarPlanner, ProbAStarPlanner
export set_max_resource, get_call, get_proposal, get_step
export sample_plan, propose_plan, sample_step_range, propose_step_range
export extract_plan, extract_traj

"Abstract planner type, which defines the interface for planners."
abstract type Planner end

"Call planner without tracing internal random choices."
(planner::Planner)(domain::Domain, state::State, goal_spec::GoalSpec) =
    get_call(planner)(planner, domain, state, goal_spec)

(planner::Planner)(domain::Domain, state::State, goals::Vector{<:Term}) =
    get_call(planner)(planner, domain, state, GoalSpec(goals))

(planner::Planner)(domain::Domain, state::State, goal::Term) =
    get_call(planner)(planner, domain, state, GoalSpec(goal))

"Return copy of the planner with adjusted resource bound."
set_max_resource(planner::Planner, val) = planner

"Returns the generative function that defines the planning algorithm."
get_call(::Planner)::GenerativeFunction = planner_call

"Returns the data-driven proposal associated with the planning algorithm."
get_proposal(::Planner)::GenerativeFunction = planner_propose

"Returns a step-wise version of the planning call."
get_step(::Planner)::GenerativeFunction = planner_step

"Returns the data-driven proposal for a planning step."
get_step_proposal(::Planner)::GenerativeFunction = planner_propose_step

"Abstract planner call template, to be implemented by concrete planners."
@gen function planner_call(planner::Planner,
                           domain::Domain, state::State, goal_spec::GoalSpec)
    error("Not implemented.")
    return plan, traj
end

"Default data-driven proposal to the planner's internal random choices."
@gen function planner_propose(planner::Planner,
                              domain::Domain, state::State, goal_spec::GoalSpec,
                              obs_states::Vector{<:Union{State,Nothing}})
    call = get_call(planner) # Default to proposing from the prior
    return @trace(call(planner, domain, state, goal_spec))
end

"Sample a plan given a planner, domain, initial state and goal specification."
@gen function sample_plan(planner::Planner,
                          domain::Domain, state::State, goal_spec)
    goal_spec = isa(goal_spec, GoalSpec) ? goal_spec : GoalSpec(goal_spec)
    call = get_call(planner)
    return @trace(call(planner, domain, state, goal_spec))
end

"Propose a plan given a planner and a sequence of observed states."
@gen function propose_plan(planner::Planner,
                           domain::Domain, state::State, goal_spec,
                           obs_states::Vector{<:Union{State,Nothing}})
    goal_spec = isa(goal_spec, GoalSpec) ? goal_spec : GoalSpec(goal_spec)
    proposal = get_proposal(planner)
    return @trace(proposal(planner, domain, state, goal_spec, obs_states))
end

"Abstract plan state for step-wise plan computation."
abstract type AbstractPlanState end

"Returns current action, given the step-wise planning state."
get_action(ps::AbstractPlanState)::Term = error("Not implemented.")

"Default state implementation for a planning step."
struct PlanState <: AbstractPlanState
    step::Int
    plan::Vector{Term}
    traj::Vector{State}
end

get_action(ps::PlanState)::Term =
    0 < ps.step <= length(ps.plan) ? ps.plan[ps.step] : Const(PDDL.no_op.name)

"Extract plan from a sequence of planning states."
extract_plan(plan_states::AbstractArray{PlanState}) = plan_states[end].plan

"Extract planned trajectory from a sequence of planning states."
extract_traj(plan_states::AbstractArray{PlanState}) = plan_states[end].traj

"Intialize step-wise planning state."
initialize_state(::Planner, env_state::State)::AbstractPlanState =
    PlanState(0, Term[], State[env_state])

"Default step-wise planning call, which does all planning up-front."
@gen function planner_step(t::Int, ps::PlanState, planner::Planner,
                           domain::Domain, state::State, goal_spec::GoalSpec)
   if ps.step == 0 # Calls planner at the start
       call = get_call(planner)
       plan, traj = @trace(call(planner, domain, state, goal_spec))
       if plan == nothing || traj == nothing # Return no-op on plan failure
           plan, traj = Term[Const(PDDL.no_op.name)], State[state]
       end
       return PlanState(1, plan, traj)
   else
       return PlanState(ps.step + 1, ps.plan, ps.traj)
   end
end

"Sample planning steps for timesteps in `t1:t2`."
@gen function sample_step_range(t1::Int, t2::Int, ps::AbstractPlanState,
                                planner::Planner, domain::Domain,
                                state::State, goal_spec::GoalSpec)
   step_call = get_step(planner)
   plan_states = Vector{typeof(ps)}()
   for t in 1:(t2-t1+1)
       ps = @trace(step_call(t+t1-1, ps, planner, domain,
                             obs_states[t], goal_spec),
                   :timestep => t+t1-1 => :plan)
       push!(plan_states, ps)
   end
   return plan_states
end

"Default proposal for planner step."
@gen function planner_propose_step(t::Int, ps::AbstractPlanState,
                                   planner::Planner, domain::Domain,
                                   state::State, goal_spec::GoalSpec,
                                   obs_states::Vector{<:Union{State,Nothing}},
                                   proposal_args::Tuple)
    # Default to using prior as proposal
    step_call = get_step(planner)
    return @trace(step_call(t, ps, planner, domain, state, goal_spec))
end

"Propose planning steps for timesteps in `t1:t2`."
@gen function propose_step_range(t1::Int, t2::Int, ps::AbstractPlanState,
                                 planner::Planner, domain::Domain,
                                 state::State, goal_spec::GoalSpec,
                                 obs_states::Vector{<:Union{State,Nothing}},
                                 proposal_args::Vector{Union{Tuple,Nothing}})
   step_propose = get_step_proposal(planner)
   plan_states = Vector{typeof(ps)}()
   for t in 1:(t2-t1+1)
       ps = @trace(step_propose(t+t1-1, ps, planner, domain, obs_states[t],
                                goal_spec, obs_states[t:end], proposal_args[t]),
                   :timestep => t+t1-1 => :plan)
       push!(plan_states, ps)
   end
   return plan_states
end

"Uninformed breadth-first search planner."
@kwdef struct BFSPlanner <: Planner
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
            next_state = transition(domain, state, act; check=false)
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
                probs[s] += obs_bias * exp(0) end
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
            for state_hash in intersect(obs_descs, keys(probs))
                probs[state_hash] += obs_bias * exp(0) end
        elseif obs_queue[1] != nothing && obs_queue[1] in keys(probs)
            # Bias search towards observed states
            obs_hash = obs_queue[1]
            nodes_left = max_nodes - count + 1
            node_mult = min(0.5 * length(obs_queue) / nodes_left, 10)
            probs[obs_hash] += node_mult * obs_bias * exp(0)
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
init_param!(aprob_propose, :obs_bias, 5)

"Reconstruct plan from current state and back-pointers."
function reconstruct_plan(state_hash::UInt, state_dict::Dict{UInt,State},
                          parents::Dict{UInt,Tuple{UInt,Term}})
    plan, traj = Term[], State[state_dict[state_hash]]
    while state_hash in keys(parents)
        state_hash, act = parents[state_hash]
        pushfirst!(plan, act)
        pushfirst!(traj, state_dict[state_hash])
    end
    return plan, traj
end
