export forward_act_proposal

"Deterministic action selection from current plan."
@gen planned_act_step(t, agent_state, env_state, domain) =
    @trace(labeled_unif([get_action(agent_state.plan_state)]), :act)

"ϵ-noisy action selection from current plan."
@gen function noisy_act_step(t, agent_state, env_state, domain, eps)
    if t == 1 # TODO: Re-index to avoid this hack
        return @trace(labeled_unif([Const(PDDL.no_op.name)]), :act)
    end
    intended = get_action(agent_state.plan_state)
    actions = pushfirst!(available(env_state, domain), Const(PDDL.no_op.name))
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
        agent_state = trace[:init => :agent]
        env_state = trace[:init => :env]
    end
    # Call proposal
    @trace(proposal_fn(domain, agent_state, env_state,
                       next_obs_state, prop_args...),
           :timestep => t+1 => :act)
end

"Proposes an action among those available that matches the observed state."
@gen function forward_act_proposal(domain, agent_state, env_state,
                                   next_obs_state, eps=0.0)
    guess = get_action(agent_state.plan_state)
    actions = pushfirst!(available(env_state, domain), Const(PDDL.no_op.name))
    for act in actions
        next_state = transition(domain, env_state, act)
        if next_state == next_obs_state
            guess = act
            break
        end
    end
    weights = [act == guess ? (1. - eps) / eps : 1. for act in actions]
    probs = weights ./ sum(weights)
    act = @trace(labeled_cat(actions, probs), :act)
end
