export Planner, BFSPlanner, AStarPlanner, FastDownwardPlanner, ProbAStarPlanner
export set_max_resource, get_call, get_proposal, get_step
export sample_plan, propose_plan
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

"Returns a step-wise version of the planning call."
get_step(::Planner)::GenerativeFunction = planner_step

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
@kwdef struct AStarPlanner <: Planner
    heuristic::Heuristic = GoalCountHeuristic()
    h_mult::Real = 1
    max_nodes::Real = Inf
end

set_max_resource(planner::AStarPlanner, val) = @set planner.max_nodes = val

get_call(::AStarPlanner)::GenerativeFunction = astar_call

"Deterministic A* search for a plan."
@gen function astar_call(planner::AStarPlanner,
                         domain::Domain, state::State, goal_spec::GoalSpec)
    @unpack goals, metric, constraints = goal_spec
    @unpack max_nodes, h_mult, heuristic = planner
    # Perform any precomputation required by the heuristic
    heuristic = precompute(heuristic, domain, state, goal_spec)
    # Initialize path costs and priority queue
    parents = Dict{State,Tuple{State,Term}}()
    path_costs = Dict{State,Int64}(state => 0)
    est_cost = heuristic(domain, state, goal_spec)
    queue = PriorityQueue{State,Int64}(state => est_cost)
    count = 1
    while length(queue) > 0
        # Get state with lowest estimated cost to goal
        state = dequeue!(queue)
        # Return plan if search budget is reached or goals are satisfied
        if count >= max_nodes || satisfy(goals, state, domain)[1]
            return reconstruct_plan(state, parents) end
        count += 1
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
                    est_remain_cost = heuristic(domain, next_state, goal_spec)
                    est_remain_cost *= h_mult
                    enqueue!(queue, next_state, path_cost + est_remain_cost)
                else
                    queue[next_state] -= cost_diff
                end
            end
        end
    end
    return nothing, nothing
end

"FastDownward planner."
@kwdef struct FastDownwardPlanner <: Planner
    timeout::Int = 10
    max_nodes::Real = Inf
    domain_path::String
    problem_path::String
    heuristic::String
    heuristic_params::Dict{String, String} = Dict()
end

set_max_resource(planner::FastDownwardPlanner, val) = @set planner.max_nodes = val

get_call(::FastDownwardPlanner)::GenerativeFunction = fastdownward_call

"FastDownward search for a plan. Currently assumes A* search"
@gen function fastdownward_call(planner::FastDownwardPlanner,
                                domain::Domain, state::State, goal_spec::GoalSpec)
    @unpack timeout, max_nodes, domain_path, problem_path, heuristic, heuristic_params = planner
    params = join(["$key=$val" for (key, val) in heuristic_params], ", ")
    heuristic_with_params = "$heuristic($params)"

    py"""
    import sys
    import os
    import re
    import subprocess

    def fastdownward_wrapper(heuristic_with_params, timeout, domain_path, problem_path):
        if 'FD_PATH' not in os.environ:
            raise Exception((
                "Environment variable `FD_PATH` not found. Make sure fd is installed "
                "and FF_PATH is set to the path of fast-downward.py"
            ))
        FD_PATH = os.environ['FD_PATH']
        timeout_cmd = "gtimeout" if sys.platform == "darwin" else "timeout"
        cmd_str = "{} {} {} {} {} --search 'astar({})'".format(timeout_cmd, timeout,
                                                                FD_PATH, domain_path,
                                                                problem_path, heuristic_with_params)
        output = subprocess.getoutput(cmd_str)
        if "Solution found" not in output:
            return None
        steps = []
        with open("sas_plan") as f:
            steps = f.readlines()[:-1]
        os.remove("sas_plan")
        return steps
    """

    plan = py"fastdownward_wrapper"(heuristic_with_params, timeout, domain_path, problem_path)
    if plan == nothing
        return nothing, nothing
    end
    plan = [(parse_pddl(step[1:(length(step) - 1)])) for step in plan]
    println(plan)
    traj = [state]
    for step in plan
        push!(traj, transition(domain, traj[length(traj)], step))
    end
    return plan, traj
end



"Probabilistic A* planner with search noise."
@kwdef struct ProbAStarPlanner <: Planner
    heuristic::Heuristic = GoalCountHeuristic()
    max_nodes::Real = Inf
    search_noise::Real = 1.0
end

set_max_resource(planner::ProbAStarPlanner, val) = @set planner.max_nodes = val

get_call(::ProbAStarPlanner)::GenerativeFunction = aprob_call

"Probabilistic A* search for a plan."
@gen function aprob_call(planner::ProbAStarPlanner,
                         domain::Domain, state::State, goal_spec::GoalSpec)
    @unpack goals, metric, constraints = goal_spec
    @unpack heuristic, max_nodes, search_noise = planner
    # Perform any precomputation required by the heuristic
    heuristic = precompute(heuristic, domain, state, goal_spec)
    # Initialize path costs and priority queue
    parents = Dict{State,Tuple{State,Term}}()
    path_costs = Dict{State,Int64}(state => 0)
    est_cost = heuristic(domain, state, goal_spec)
    queue = OrderedDict{State,Int64}(state => est_cost)
    # Initialize node count
    count = 1
    while length(queue) > 0
        # Sample state from queue with probability exp(-beta*est_cost)
        probs = softmax([-v / search_noise for v in values(queue)])
        state = @trace(labeled_cat(collect(keys(queue)), probs), (:node, count))
        delete!(queue, state)
        # Return plan if search budget is reached or goals are satisfied
        if count >= max_nodes || satisfy(goals, state, domain)[1]
            return reconstruct_plan(state, parents)
        end
        count += 1
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
                    est_remain_cost = heuristic(domain, next_state, goal_spec)
                    queue[next_state] = path_cost + est_remain_cost
                else
                    queue[next_state] -= cost_diff
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
    @unpack heuristic, max_nodes, search_noise = planner
    # Perform any precomputation required by the heuristic
    heuristic = precompute(heuristic, domain, state, goal_spec)
    # Initialize path costs and priority queue
    parents = Dict{State,Tuple{State,Term}}()
    path_costs = Dict{State,Int64}(state => 0)
    est_cost = heuristic(domain, state, goal_spec)
    queue = OrderedDict{State,Int64}(state => est_cost)
    # Initialize observation queue and descendants
    obs_queue = copy(obs_states)
    last_idx = findlast(s -> s != nothing, obs_states)
    obs_descs = last_idx == nothing ?
        Set{State}() : Set{State}([obs_states[last_idx]])
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
            probs = [s in obs_descs ? (2*obs_bias+1)*p : p for (s, p) in probs]
            probs = probs ./ sum(probs)
            state = @trace(labeled_cat(collect(keys(queue)), probs),
                           (:node, count))
            return reconstruct_plan(state, parents)
        elseif isempty(obs_queue)
            for state in obs_descs # Bias search towards descendants
                if (state in keys(probs))
                    probs[state] += obs_bias * probs[state] end
            end
        elseif obs_queue[1] != nothing && obs_queue[1] in keys(probs)
            obs = obs_queue[1]
            nodes_left = max_nodes - count + 1
            node_mult = min(2 * length(obs_queue) / nodes_left + 1, 10)
            # Bias search towards observed states
            probs[obs] += node_mult * obs_bias * probs[obs]
        end
        probs = collect(values(probs)) ./ sum(values(probs))
        state = @trace(labeled_cat(collect(keys(queue)), probs), (:node, count))
        # Remove states / observations from respective queues
        delete!(queue, state)
        if !isempty(obs_queue) &&
            (obs_queue[1] == nothing || obs_queue[1] == state)
            popfirst!(obs_queue) end
        # Return plan if goals are satisfied
        if count >= max_nodes || satisfy(goals, state, domain)[1]
            return reconstruct_plan(state, parents)
        end
        count += 1
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
                    est_remain_cost = heuristic(domain, next_state, goal_spec)
                    queue[next_state] = path_cost + est_remain_cost
                else
                    queue[next_state] -= cost_diff
                end
                # Add next state to descendants of observations
                if state in obs_descs push!(obs_descs, next_state) end
            end
        end
        # Remove state from observation descendants once expanded
        if state in obs_descs delete!(obs_descs, state) end
    end
    return nothing, nothing
end

# Initialize bias towards sampling observed states
init_param!(aprob_propose, :obs_bias, 2)

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
