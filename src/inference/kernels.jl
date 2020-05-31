export pf_replan_move_mh!, pf_replan_move_reweight!

"Error-driven replanning move proposal that resamples new partial plans."
@gen function replan_move_proposal(trace::Trace, use_obs::Bool=true)
    # Unpack trace
    _, _, world_config = Gen.get_args(trace)
    @unpack domain, planner = world_config
    goal_spec = trace[:goal_init]
    world_states = get_retval(trace)
    env_states = [ws.env_state for ws in world_states]
    obs_states = [ws.obs_state for ws in world_states]
    plan_states = [ws.plan_state for ws in world_states]
    # Compute time of divergence between hypothesized and observed states
    t_current = length(world_states)
    t_diverge = findfirst(hash.(env_states) .!= hash.(obs_states))
    if (t_diverge == nothing) t_diverge = t_current + 1 end
    # Decide whether to resample partial plans
    t_diff = t_current - t_diverge
    resample_prob = t_diff < 0 ? 0.1 : exp(1)/6 * t_diff * exp(-t_diff/5)
    resample ~ bernoulli(resample_prob)
    if !resample return end
    # Find earliest plan that diverges from observations
    t_plans, _ = get_planning_steps(plan_states)
    plan_idx = max(searchsortedfirst(t_plans, t_diverge) - 1, 1)
    # Propose timestep to resample plans from
    n_plans = length(t_plans)
    idx_probs = (n_plans == 1) ? [1.0] :
        [i == plan_idx ? 0.9 : 0.1 / (n_plans-1) for i in 1:n_plans]
    resample_idx ~ categorical(idx_probs)
    t_resamp = t_plans[resample_idx]
    # Propose maximum node budget for first partial plan resampled
    t_diff = t_diverge - t_resamp
    if t_diff <= 0 || !use_obs # Sample node budget from prior
        n_attempts, p_cont = planner.persistence
        max_resource ~ neg_binom(n_attempts, 1-p_cont)
    else
        max_resource_guess = t_diff * length(domain.actions)
        max_resource ~ geometric(1 / (t_diff+1))
    end
    # Propose partial plans from t_resample to t_current
    proposal_args = [(max_resource,); fill((nothing,), t_current - t_resamp)]
    plan_state = t_resamp == 1 ?
        initialize_state(planner, env_states[1]) : plan_states[t_resamp-1]
    obs_states = use_obs ?
        obs_states[t_resamp:t_current] : fill(nothing, t_current-t_resamp+1)
    {*} ~ propose_step_range(t_resamp, t_current, plan_state,
                             planner, domain, env_states[t_resamp], goal_spec,
                             obs_states, proposal_args)
    return (t_resamp, t_current)
end

"Involution for the replanning move kernel."
@involution function replan_move_involution(m_args, p_args, p_retval)
    resample = @read_discrete_from_proposal(:resample)
    @write_discrete_to_proposal(:resample, resample)
    if !resample return end
    t_resamp, t_current = p_retval
    @copy_proposal_to_proposal(:resample_idx, :resample_idx)
    @copy_model_to_proposal(:timestep => t_resamp => :plan => :max_resource,
                            :max_resource)
    for t in t_resamp:t_current
        addr = :timestep => t => :plan
        @copy_proposal_to_model(addr, addr)
        @copy_model_to_proposal(addr, addr)
    end
end

"Metropolis-Hastings replanning move kernel."
replan_move_mh_kernel(trace::Trace) =
    mh(trace, replan_move_proposal, (), replan_move_involution)

"Move-reweight replanning kernel."
replan_move_reweight(trace::Trace) =
    move_reweight(trace, replan_move_proposal, (true,),
                  replan_move_proposal, (false,), replan_move_involution)

"Apply replanning move kernel to particle filter state."
pf_replan_move_mh!(pf_state::Gen.ParticleFilterState, n_iters::Int=3) =
    pf_move_mh!(pf_state, replan_move_mh_kernel, n_iters)

"Apply move-reweight kernel to particle filter state."
pf_replan_move_reweight!(pf_state::Gen.ParticleFilterState, n_iters::Int=3) =
    pf_move_reweight!(pf_state, replan_move_reweight, n_iters)
