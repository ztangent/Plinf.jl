export goal_pf, pf_replan_move_mh!, pf_replan_move_reweight!

"Return traces for constrained to each value and random choice in `enumerands`."
function enumerate_traces(gen_fn::GenerativeFunction, args::Tuple,
                          enumerands::AbstractDict{<:Any,<:AbstractVector},
                          constraints::ChoiceMap=choicemap())
    grid = Iterators.product((collect(key => val for val in vals)
                            for (key, vals) in enumerands)...)
    tr_ws = [generate(gen_fn, args, merge(constraints, choicemap(elt...)))
             for elt in grid]
    traces, weights = unzip(tr_ws)
    return traces, weights
end

"Initialize a particle filter with stratified sampling."
function initialize_pf_stratified(model::GenerativeFunction{T,U},
                                  model_args::Tuple, observations::ChoiceMap,
                                  strata::AbstractDict{<:Any,<:AbstractVector},
                                  n_particles::Int) where {T,U}
    traces = Vector{Any}(undef, n_particles)
    log_weights = Vector{Float64}(undef, n_particles)
    n_strata = reduce(*, length(vals) for (addr, vals) in strata, init=1)
    n_repeats = n_particles ÷ n_strata
    n_remain = n_particles % n_strata
    # Repeat discrete enumeration of traces over provided strata
    for i in 1:n_repeats
        i_particle = (i-1) * n_strata + 1
        trs, ws = enumerate_traces(model, model_args, strata, observations)
        traces[i_particle:i_particle + n_strata - 1] = trs
        log_weights[i_particle:i_particle + n_strata - 1] = ws
    end
    # Select the remainder at random from the full set of enumerated traces
    if n_remain > 0
        i_particle = n_particles - n_remain + 1
        trs, ws = enumerate_traces(model, model_args, strata, observations)
        idxs = randperm(n_strata)[1:n_remain]
        traces[i_particle:end] = trs[idxs]
        log_weights[i_particle:end] = ws[idxs]
    end
    return Gen.ParticleFilterState{U}(traces, Vector{U}(undef, n_particles),
                                      log_weights, 0., collect(1:n_particles))
end

"Online goal inference using a particle filter."
function goal_pf(world_init::WorldInit, world_config::WorldConfig,
                 obs_traj::Vector{State}, obs_terms::Vector{<:Term},
                 n_particles::Int; resample=true, rejuvenate=nothing,
                 callback=nothing, goal_strata=nothing,
                 goal_addr=(:goal_init => :goal))
    # Construct choicemaps from observed trajectory
    @unpack domain = world_config
    obs_choices = traj_choicemaps(obs_traj, domain, obs_terms)
    # Initialize particle filter with initial observations
    world_args = (world_init, world_config)
    argdiffs = (UnknownChange(), NoChange(), NoChange())
    if goal_strata != nothing
        # Perform stratified sampling from goal prior
        strata = Dict(goal_addr => goal_strata)
        pf_state = initialize_pf_stratified(world_model, (1, world_args...),
                                            obs_choices[1], strata, n_particles)
    else
        # Sample at random
        pf_state = initialize_particle_filter(world_model, (1, world_args...),
                                              obs_choices[1], n_particles)
    end
    # Run callback with initial state
    if callback != nothing
        trs, ws = get_traces(pf_state), lognorm(get_log_weights(pf_state))
        callback(1, obs_traj[1], trs, ws)
    end
    # Feed new observations at each timestep
    for t=2:length(obs_traj)
        if resample
            resampled = maybe_resample!(pf_state, ess_threshold=n_particles/4)
            if resampled
                @debug "Resampling..."
                if rejuvenate != nothing rejuvenate(pf_state) end
            end
        end
        particle_filter_step!(pf_state, (t, world_args...),
                              argdiffs, obs_choices[t])
        if callback != nothing
            trs, ws = get_traces(pf_state), lognorm(get_log_weights(pf_state))
            callback(t, obs_traj[t], trs, ws)
        end
    end
    # Return particles and their weights
    return get_traces(pf_state), lognorm(get_log_weights(pf_state))
end

"Rejuvenate particles by repeated application of a Metropolis-Hastings kernel."
function pf_move_mh!(pf_state::Gen.ParticleFilterState,
                     kern, n_iters::Int=3)
    # Potentially rejuvenate each trace
    for (i, trace) in enumerate(pf_state.traces)
        for k = 1:n_iters
            trace, accept = kern(trace)
            @debug "Accepted: $accept"
        end
        pf_state.new_traces[i] = trace
    end
    # Swap references
    tmp = pf_state.traces
    pf_state.traces = pf_state.new_traces
    pf_state.new_traces = tmp
end

"Rejuvenate particles via repeated move-reweight steps."
function pf_move_reweight!(pf_state::Gen.ParticleFilterState,
                           kern, n_iters::Int=3)
    # Move and reweight each trace
    for (i, trace) in enumerate(pf_state.traces)
        weight = 0
        for k = 1:n_iters
            trace, rel_weight = kern(trace)
            weight += rel_weight
        end
        pf_state.new_traces[i] = trace
        pf_state.log_weights[i] += weight
    end
    # Swap references
    tmp = pf_state.traces
    pf_state.traces = pf_state.new_traces
    pf_state.new_traces = tmp
end

"Move-reweight MCMC update (cf. Marques & Storvik, 2013)."
function move_reweight(trace, proposal::GenerativeFunction,
                       proposal_args::Tuple, involution)
    (fwd_choices, fwd_score, fwd_ret) =
        propose(proposal, (trace, proposal_args...,))
    (new_trace, bwd_choices, weight) =
        involution(trace, fwd_choices, fwd_ret, proposal_args)
    (bwd_score, bwd_ret) =
        assess(proposal, (new_trace, proposal_args...), bwd_choices)
    rel_weight = weight - fwd_score + bwd_score
    return new_trace, rel_weight
end

"Move-reweight MCMC update (cf. Marques & Storvik, 2013)."
function move_reweight(trace, proposal_new::GenerativeFunction, args_new::Tuple,
                       proposal_old::GenerativeFunction, args_old::Tuple,
                       involution)
    (fwd_choices, fwd_score, fwd_ret) =
        propose(proposal_new, (trace, args_new...,))
    (new_trace, bwd_choices, weight) =
        involution(trace, fwd_choices, fwd_ret, args_new)
    (bwd_score, bwd_ret) =
        assess(proposal_old, (new_trace, args_old...), bwd_choices)
    rel_weight = weight - fwd_score + bwd_score
    return new_trace, rel_weight
end

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
    t_diverge = findfirst(env_states .!= obs_states)
    if (t_diverge == nothing) t_diverge = t_current + 1 end
    # Decide whether to resample partial plans
    resample_prob = t_diverge > t_current ? 0.1 : 0.9
    resample ~ bernoulli(resample_prob)
    if !resample return end
    # Find earliest plan that diverges from observations
    t_plans, _ = get_planning_steps(plan_states)
    plan_idx = searchsortedfirst(t_plans, t_diverge) - 1
    # Propose timestep to resample plans from
    n_plans = length(t_plans)
    idx_probs = n_plans == 1 ? [1.0] :
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

pf_replan_move_mh!(pf_state::Gen.ParticleFilterState, n_iters::Int=3) =
    pf_move_mh!(pf_state, replan_move_mh_kernel, n_iters)

pf_replan_move_reweight!(pf_state::Gen.ParticleFilterState, n_iters::Int=3) =
    pf_move_reweight!(pf_state, replan_move_reweight, n_iters)
