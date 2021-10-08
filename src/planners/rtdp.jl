export RTDPlanner

"Real Time Dynamic Programming (RTDP) planner."
@kwdef struct RTDPlanner <: Planner
    heuristic::Heuristic = GoalCountHeuristic()
    discount::Float64 = 1.0
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
               init_states::AbstractVector{<:State}, goal_spec::GoalSpec)
    @unpack goals, metric, constraints = goal_spec
    @unpack n_rollouts, rollout_len, heuristic, rollout_noise = planner
    @unpack discount, act_noise = planner
    policy = Policy()
    # Perform any precomputation required by the heuristic
    heuristic = precompute(heuristic, domain, init_states[1], goal_spec)
    # Perform rollouts from randomly sampled initial state
    for n in 1:n_rollouts
        state = rand(init_states)
        count = 0
        while count < rollout_len
            if satisfy(domain, state, goals)
                policy.V[hash(state)] = 0.0
                break
            end
            actions = available(domain, state)
            succs = [transition(domain, state, act) for act in actions]
            qs = map(succs) do s
                h = heuristic(domain, s, goals)
                discount * get!(policy.V, hash(s), -h == -Inf ? -1000 : -h) - 1
            end
            policy.Q[hash(state)] = Dict{Term,Float64}(zip(actions, qs))
            probs = softmax(qs ./ act_noise)
            policy.V[hash(state)] = act_noise > 0 ?
                sum(softmax(qs ./ act_noise) .* qs) : maximum(qs)
            state = succs[categorical(softmax(qs ./ rollout_noise))]
            count += 1
        end
    end
    return policy
end

solve(planner::RTDPlanner, domain::Domain, state::State, goal_spec::GoalSpec) =
    solve(planner, domain, [state], goal_spec)

function default_qvals(planner::RTDPlanner, policy::Policy,
                       domain::Domain, state::State, goal_spec::GoalSpec)
    @unpack goals = goal_spec
    @unpack heuristic, discount = planner
    actions = available(domain, state)
    qs = map(actions) do act
        s = transition(domain, state, act)
        h = heuristic(domain, s, goals)
        discount * get(policy.V, hash(s), -h == -Inf ? -1000 : -h) - 1
    end
    return Dict{Term,Float64}(zip(actions, qs))
end

@gen function rtdp_call(planner::RTDPlanner,
                        domain::Domain, state::State, goal_spec::GoalSpec)
    # Compute policy
    policy = solve(planner, domain, state, goal_spec)
    # Construct plan by sampling from policy until goal is reached
    @unpack goals = goal_spec
    @unpack act_noise, max_length = planner
    plan, traj = Term[], State[state]
    count = 0
    while !satisfy(domain, state, goals) && count < max_length
        count += 1
        qs = get(policy.Q, hash(state),
                 default_qvals(planner, policy, domain, state, goal_spec))
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
    actions::Vector{Term}
    probs::Vector{Float64}
end

init_plan_state(::RTDPlanner) =
    PolicyState(nothing, Term[pddl"(--)"], [1.0])

get_action(ps::PolicyState) = ps.actions[argmax(ps.probs)]

get_step(::RTDPlanner)::GenerativeFunction = rtdp_step

"Step-wise planning call for RTDPlanner, returns a local policy."
@gen function rtdp_step(t::Int, ps::PolicyState, planner::RTDPlanner,
                        domain::Domain, state::State, goal_spec::GoalSpec)
    policy = ps.policy === nothing ?
        solve(planner, domain, state, goal_spec) : ps.policy
    qs = get(policy.Q, hash(state),
             default_qvals(planner, policy, domain, state, goal_spec))
    actions = collect(keys(qs))
    probs = softmax(values(qs) ./ planner.act_noise)
    return PolicyState(policy, actions, probs)
end
