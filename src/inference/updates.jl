# Custom SMC updates and proposals

export plan_update_proposal

"Data-driven proposal for plan extensions."
@gen function plan_update_proposal(trace::Trace, t1::Int, t2::Int,
                                   obs_states::Vector{State})
    _, _, world_config = Gen.get_args(trace)
    @unpack domain, planner = world_config
    goal_spec = trace[:goal_init]
    world_states = get_retval(trace)
    proposal_args = fill((nothing,), t2-t1+1)
    plan_state = t1 > 1 ? world_states[t1-1].plan_state : trace[:plan_init]
    env_state = t1 > 1 ? world_states[t1-1].env_state : trace[:env_init]
    env_state = transition(domain, env_state, get_action(plan_state))
    {*} ~ propose_step_range(t1, t2, plan_state, planner, domain,
                             env_state, goal_spec, obs_states, proposal_args)
end
