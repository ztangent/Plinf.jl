export goal_pf, replan_rejuvenate

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
                 n_particles::Int; rejuvenate=nothing, callback=nothing,
                 goal_strata=nothing, goal_addr=(:goal_init => :goal))
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
        resampled = maybe_resample!(pf_state, ess_threshold=n_particles/4)
        if resampled
            @debug "Resampling..."
            if rejuvenate != nothing rejuvenate(pf_state) end
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

"Rejuvenation MCMC move for replanning agent models."
function replan_rejuvenate(pf_state::Gen.ParticleFilterState,
                           n_rejuv_steps::Int=1, rejuv_temp::Real=log(1.25))
    # Potentially rejuvenate each trace
    for (i, trace) in enumerate(pf_state.traces)
        # Get last step at which replanning occured
        world_states = get_retval(trace)
        rp_states = [ws.plan_state for ws in world_states]
        t_last_plan, _ = get_last_planning_step(rp_states)
        t_since_last_plan = length(rp_states) - t_last_plan + 1
        # Resample final plan with higher probability if it was made recently
        resample_last_plan = bernoulli(exp(-rejuv_temp * t_since_last_plan))
        if resample_last_plan
            @debug "Resampling last plan..."
            for k = 1:n_rejuv_steps
                trace, accept = mh(trace, replan_mh_proposal, (t_last_plan,))
                @debug "Accepted: $accept"
            end
            pf_state.new_traces[i] = trace
        end
    end
    # Swap references
    tmp = pf_state.traces
    pf_state.traces = pf_state.new_traces
    pf_state.new_traces = tmp
end

"Adjust trace by proposing a new replanning step from time `t`."
@gen function replan_mh_proposal(trace::Trace, t::Int)
    _, _, world_config = Gen.get_args(trace)
    world_states = get_retval(trace)
    goal_spec = trace[:goal_init]
    @unpack domain, planner = world_config
    env_state = world_states[t].env_state
    plan_state = t > 1 ? world_states[t-1].plan_state :
        initialize_state(planner, env_state)
    obs_states = [ws.obs_state for ws in world_states[t:end]]
    @trace(replan_step_propose(t, plan_state, planner, domain, env_state,
                               goal_spec, obs_states), :timestep => t => :plan)
end
