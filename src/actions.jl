export forward_act_proposal

"Deterministic action selection from current plan."
@gen planned_act_step(t, agent_state, env_state, domain) =
    @trace(labeled_unif([get_action(agent_state.plan_state)]), :act)

"Boltzmann action selection from precomputed policy."
@gen function boltzmann_act_step(t, agent_state, env_state, domain)
    @unpack actions, probs = agent_state.plan_state
    @trace(labeled_cat(actions, probs), :act)
end

"ϵ-noisy action selection from current plan."
@gen function noisy_act_step(t, agent_state, env_state, domain, eps)
    if t == 1 # TODO: Re-index to avoid this hack
        return @trace(labeled_unif([Const(Symbol("--"))]), :act)
    end
    intended = get_action(agent_state.plan_state)
    actions = pushfirst!(collect(available(domain, env_state)), Const(Symbol("--")))
    weights = [act == intended ? (1. - eps) / eps : 1. for act in actions]
    probs = weights ./ sum(weights)
    act = @trace(labeled_cat(actions, probs), :act)
end

"Proposes the next action, given the current trace of `world_model`."
@gen function propose_act(trace::Trace, next_obs_state::State,
                          proposal_fn::GenerativeFunction, prop_args::Tuple)
    # Unpack trace
    t, _, world_config = Gen.get_args(trace)
    @unpack domain = world_config
    if t > 0
        agent_state = trace[:timestep => t => :agent]
        env_state = trace[:timestep => t => :env]
    else
        agent_state, _ = trace[:init => :agent]
        env_state = trace[:init => :env]
    end
    # Call proposal
    @trace(proposal_fn(t+1, domain, agent_state, env_state,
                       next_obs_state, prop_args...),
           :timestep => t+1 => :act)
end

"Proposes an action among those available that matches the observed state."
@gen function forward_act_proposal(t, domain, agent_state, env_state,
                                   next_obs_state, eps=0.0, include_noop=true)
    if t == 1 # TODO: Re-index to avoid this hack
        return @trace(labeled_unif([Const(Symbol("--"))]), :act)
    end
    guess = get_action(agent_state.plan_state)
    actions = collect(available(domain, env_state))
    if include_noop pushfirst!(actions, Const(Symbol("--"))) end
    for act in actions
        next_state = transition(domain, env_state, act)
        if next_state == next_obs_state
            guess = act
            break
        end
    end
    if eps > 0
        weights = [act == guess ? (1. - eps) / eps : 1. for act in actions]
        probs = weights ./ sum(weights)
    else
        probs = [act == guess ? 1.0 : 0.0 for act in actions]
    end
    act = @trace(labeled_cat(actions, probs), :act)
end
