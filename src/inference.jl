export agent_pf, replan_rejuvenate

"Online goal inference for a task planning agent using a particle filter."
function agent_pf(agent_model::GenerativeFunction, agent_args::Tuple,
                  obs_traj::Vector{State}, obs_terms::Vector{<:Term},
                  domain::Domain, n_particles::Int;
                  rejuvenate=nothing, callback=nothing)
    # Initialize particle filter with initial observations
    init_obs = state_choices(obs_traj[1], obs_terms, (:traj => 1))
    pf_state = initialize_particle_filter(agent_model, (1, agent_args...),
                                          init_obs, n_particles)
    agent_argdiffs = fill(NoChange(), length(agent_args))
    # Run callback with initial state
    if callback != nothing
        trs, ws = get_traces(pf_state), lognorm(get_log_weights(pf_state))
        callback(1, obs_traj[1], trs, ws)
    end
    # Feed new observations at each timestep
    for t=2:length(obs_traj)
        resampled = maybe_resample!(pf_state, ess_threshold=n_particles/4)
        if resampled
            if rejuvenate != nothing rejuvenate(pf_state) end
        end
        obs = state_choices(obs_traj[t], domain, obs_terms, (:traj => t));
        particle_filter_step!(pf_state, (t, agent_args...),
            (UnknownChange(), agent_argdiffs...), obs)
        if callback != nothing
            trs, ws = get_traces(pf_state), lognorm(get_log_weights(pf_state))
            callback(t, obs_traj[t], trs, ws)
        end
    end
    # Return particles and their weights
    return get_traces(pf_state), lognorm(get_log_weights(pf_state))
end

"Rejuvenation MCMC move for replanning agent models."
function replan_rejuvenate(pf_state::Gen.ParticleFilterState,
                           n_rejuv_steps::Int=1, rejuv_temp::Real=log(1.25))
    # Potentially rejuvenate each trace
    for (i, trace) in enumerate(pf_state.traces)
        # Resample everything with some low probability
        if bernoulli(0.1)
            for k = 1:n_rejuv_steps
                trace, _ = mh(trace, select(:goal, :traj))
            end
            pf_state.new_traces[i] = trace
            continue
        end
        # Get last step at which replanning occurred
        rp_states = trace[:traj]
        t, _ = get_last_plan_step(rp_states)
        last_plan_length = length(rp_states) - t + 1
        # Resample final plan with probability decreasing in plan length
        resample_last_plan = bernoulli(exp(-rejuv_temp * last_plan_length))
        if resample_last_plan
            selection = select(:traj => t => :max_resource, :traj => t => :plan)
            for k = 1:n_rejuv_steps
                trace, _ = mh(trace, selection)
            end
            pf_state.new_traces[i] = trace
        end
    end
    # Swap references
    tmp = pf_state.traces
    pf_state.traces = pf_state.new_traces
    pf_state.new_traces = tmp
end
