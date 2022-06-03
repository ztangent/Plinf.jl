export RTDPlanner

"Real Time Dynamic Programming (RTDP) planner."
@kwdef struct RTDPlanner <: Planner
    heuristic::Heuristic = GoalCountHeuristic()
    act_noise::Float64 = 1.0
    max_length::Int = 50
    n_rollouts::Int = 50
    rollout_len::Int = 50
    rollout_noise::Float64 = 5.0
end

set_max_resource(planner::RTDPlanner, val) = @set planner.n_rollouts = val

get_call(::RTDPlanner)::GenerativeFunction = rtdp_call

"Policy values computed by RTDP planner."
struct Policy
    V::Dict{UInt64,Float64}
    Q::Dict{UInt64,Dict{Term,Float64}}
end

Policy() = Policy(Dict(), Dict())

function solve(planner::RTDPlanner, domain::Domain,
               init_states::AbstractVector{<:State}, spec::Specification)
    @unpack n_rollouts, rollout_len, rollout_noise = planner
    @unpack heuristic, act_noise = planner
    policy = Policy()
    # Perform any precomputation required by the heuristic
    heuristic = precompute(heuristic, domain, init_states[1], spec)
    # Perform rollouts from randomly sampled initial state
    visited = Vector{eltype(init_states)}()
    for n in 1:n_rollouts
        state = rand(init_states)
        # Rollout until maximum depth
        for t in 1:rollout_len
            push!(visited, state)
            if is_goal(spec, domain, state) break end
            update_values!(planner, policy, domain, state, spec)
            actions, qvals = unzip_pairs(policy.Q[hash(state)])
            probs = softmax(qvals ./ rollout_noise)
            act = actions[categorical(probs)]
            state = transition(domain, state, act)
        end
        # Post-rollout update
        while length(visited) > 0
            state = pop!(visited)
            update_values!(planner, policy, domain, state, spec)
        end
    end
    return policy
end

solve(planner::RTDPlanner, domain::Domain, state::State, spec::Specification) =
    solve(planner, domain, [state], spec)

function update_values!(planner::RTDPlanner, policy::Policy,
                        domain::Domain, state::State, spec::Specification)
    actions = collect(available(domain, state))
    state_id = hash(state)
    if is_goal(spec, domain, state)
        qs = zeros(length(actions))
        policy.Q[state_id] = Dict{Term,Float64}(a => 0 for a in actions)
        policy.V[state_id] = 0.0
        return
    end
    qs = map(actions) do act
        next_state = transition(domain, state, act)
        r = get_reward(spec, domain, state, act, next_state)
        next_value = get!(policy.V, hash(next_state)) do
            planner.heuristic(domain, next_state, spec)
        end
        return get_discount(spec) * next_value + r
    end
    policy.Q[state_id] = Dict{Term,Float64}(zip(actions, qs))
    policy.V[state_id] = planner.act_noise == 0 ?
        maximum(qs) : sum(softmax(qs ./ planner.act_noise) .* qs)
end

function default_qvals(planner::RTDPlanner, policy::Policy,
                       domain::Domain, state::State, spec::Specification)
    @unpack heuristic = planner
    actions = available(domain, state)
    qs = map(actions) do act
        next_state = transition(domain, state, act)
        r = get_reward(spec, domain, state, act, next_state)
        next_value = get!(policy.V, hash(next_state)) do
            planner.heuristic(domain, next_state, spec)
        end
        return get_discount(spec) * next_value + r
    end
    return Dict{Term,Float64}(zip(actions, qs))
end

@gen function rtdp_call(planner::RTDPlanner,
                        domain::Domain, state::State, spec::Specification)
    # Compute policy
    policy = solve(planner, domain, state, spec)
    # Construct plan by sampling from policy until goal is reached
    @unpack act_noise, max_length = planner
    plan, traj = Term[], State[state]
    count = 0
    while !is_goal(spec, domain, state) && count < max_length
        count += 1
        qs = get(policy.Q, hash(state)) do
            default_qvals(planner, policy, domain, state, spec)
        end
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
    policy::Union{Policy,Nothing}
    act_noise::Float64
    actions::Vector{Term}
    qvalues::Vector{Float64}
end

init_plan_state(::RTDPlanner) =
    PolicyState(nothing, 0.0, Term[pddl"(--)"], [1.0])

get_action(ps::PolicyState) = ps.actions[argmax(ps.qvalues)]

get_step(::RTDPlanner)::GenerativeFunction = rtdp_step

"Step-wise planning call for RTDPlanner, returns a local policy."
@gen function rtdp_step(t::Int, ps::PolicyState, planner::RTDPlanner,
                        domain::Domain, state::State, spec::Specification)
    policy = ps.policy === nothing ?
        solve(planner, domain, state, spec) : ps.policy
    qs = get(policy.Q, hash(state),
             default_qvals(planner, policy, domain, state, spec))
    actions = collect(keys(qs))
    qvalues = collect(values(qs))
    return PolicyState(policy, planner.act_noise, actions, qvalues)
end
