export RTDPlanner

"Real Time Dynamic Programming (RTDP) planner."
@kwdef mutable struct RTDPlanner <: Planner
    heuristic::Heuristic = GoalCountHeuristic()
    discount::Float64 = 1.0
    act_noise::Float64 = 1.0
    max_length::Int = 50
    n_rollouts::Int = 50
    rollout_len::Int = 50
    rollout_noise::Float64 = 5.0
    solved::Bool = false
    vals::Dict{UInt64,Float64} = Dict()
    qvals::Dict{UInt64,Dict{Term,Float64}} = Dict()
end

set_max_resource(planner::RTDPlanner, val) = @set planner.n_rollouts = val

get_call(::RTDPlanner)::GenerativeFunction = rtdp_call

function solve!(planner::RTDPlanner,
                domain::Domain, init_states::Vector{State}, goal_spec::GoalSpec)
    @unpack goals, metric, constraints = goal_spec
    @unpack n_rollouts, rollout_len, heuristic, rollout_noise = planner
    @unpack vals, qvals, discount, act_noise = planner
    # Perform any precomputation required by the heuristic
    heuristic = precompute(heuristic, domain, init_states[1], goal_spec)
    planner.heuristic = heuristic
    # Perform rollouts from randomly sampled initial state
    for n in 1:n_rollouts
        state = rand(init_states)
        count = 0
        while count < rollout_len
            if satisfy(goals, state, domain)[1]
                vals[hash(state)] = 0.0
                break
            end
            actions = available(state, domain)
            succs = [transition(domain, state, act) for act in actions]
            qs = map(succs) do s
                h = heuristic(domain, s, goals)
                discount * get!(vals, hash(s), -h == -Inf ? -1000 : -h) - 1
            end
            qvals[hash(state)] = Dict{Term,Float64}(zip(actions, qs))
            probs = softmax(qs ./ act_noise)
            vals[hash(state)] = act_noise > 0 ?
                sum(softmax(qs ./ act_noise) .* qs) : maximum(qs)
            state = succs[categorical(softmax(qs ./ rollout_noise))]
            count += 1
        end
    end
    planner.solved = true
    return planner
end

solve!(planner::RTDPlanner, domain::Domain, state::State, goal_spec::GoalSpec) =
    solve!(planner, domain, [state], goal_spec)

function default_qvals(planner::RTDPlanner,
                       domain::Domain, state::State, goal_spec::GoalSpec)
    @unpack goals = goal_spec
    @unpack heuristic, discount, vals = planner
    actions = available(state, domain)
    qs = map(actions) do act
        s = transition(domain, state, act)
        h = heuristic(domain, s, goals)
        discount * get!(vals, hash(s), -h == -Inf ? -1000 : -h) - 1
    end
    return Dict{Term,Float64}(zip(actions, qs))
end

@gen function rtdp_call(planner::RTDPlanner,
                        domain::Domain, state::State, goal_spec::GoalSpec)
    # Solve MDP if not yet solved
    if !planner.solved solve!(planner, domain, state, goal_spec) end
    # Construct plan by sampling from policy until goal is reached
    @unpack goals = goal_spec
    @unpack qvals, act_noise, max_length = planner
    plan, traj = Term[], State[state]
    count = 0
    while !satisfy(goals, state, domain)[1] && count < max_length
        count += 1
        qs = get!(qvals, hash(state),
                  default_qvals(planner, domain, state, goal_spec))
        actions = collect(keys(qs))
        probs = softmax(values(qs) ./ act_noise)
        act = @trace(labeled_cat(actions, probs), (:act, count))
        state = transition(domain, state, act)
        push!(plan, act)
        push!(traj, state)
    end
    return plan, traj
end

"Represents policy at a particular state."
struct PolicyState <: AbstractPlanState
    actions::Vector{Term}
    probs::Vector{Float64}
end

get_action(ps::PolicyState) = actions[argmax(probs)]

get_step(::RTDPlanner)::GenerativeFunction = rtdp_step

"Step-wise planning call for RTDPlanner, returns a local policy."
@gen function rtdp_step(t::Int, ps::PolicyState, planner::RTDPlanner,
                        domain::Domain, state::State, goal_spec::GoalSpec)
   if !planner.solved solve!(planner, domain, state, goal_spec) end
   qs = get!(planner.qvals, hash(state),
             default_qvals(planner, domain, state, goal_spec))
   actions = collect(keys(qs))
   probs = softmax(values(qs) ./ planner.act_noise)
   return PolicyState(actions, probs)
end
