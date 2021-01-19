export world_importance_sampler, world_particle_filter

using GenParticleFilters

include("utils.jl")
include("kernels.jl")

"Generate weighted importance samples over a world model."
function world_importance_sampler(
        world_init::WorldInit, world_config::WorldConfig,
        obs_traj::Vector{State}, obs_terms::Vector{<:Term}, n_samples::Int;
        use_proposal=true, strata=nothing, callback=nothing)
    @unpack domain = world_config
    # Construct choicemaps from observed trajectory
    n_obs = length(obs_traj)
    obs_choices = traj_choicemaps(obs_traj, domain, obs_terms;
                                  as_choicemap=true)
    # Initialize traces of world model
    init_traces, _ = strata == nothing ?
        unzip(generate(init_world_model, (world_init, world_config))
              for i in 1:n_samples) :
        enumerate_traces(init_world_model, (world_init, world_config), strata)
    # Compute importance sample for each initial trace
    traces = Vector{Trace}(undef, n_samples)
    weights = Vector{Float64}(undef, n_samples)
    for i in 1:n_samples
        init_idx = mod(i-1, length(init_traces)) + 1
        world_state = get_retval(init_traces[init_idx])
        init_choices = choicemap()
        set_submap!(init_choices, :init, get_choices(init_traces[init_idx]))
        @unpack agent_config = world_config
        env_state = init_traces[init_idx][:env]
        agent_state, _ = init_traces[init_idx][:agent]
        # Set-up data-driven proposal associated with the planner
        prop_args = (1, n_obs, agent_state, env_state,
                     agent_config, obs_traj)
        # Propose choices
        prop_choices, prop_weight, _ = use_proposal ?
            propose(agent_propose_range, prop_args) : (choicemap(), 0.0, 0.0)
        constraints = merge(obs_choices, init_choices, prop_choices)
        # Sample from model given constraints
        model_args = (n_obs, world_init, world_config)
        traces[i], model_weight = generate(world_model, model_args, constraints)
        weights[i] = model_weight - prop_weight
    end
    # Normalize weights
    lml_est = logsumexp(weights) - log(n_samples)
    weights = lognorm(weights)
    # Run callback on sampled traces
    if callback != nothing
        callback(n_obs, obs_traj[end], traces, weights)
    end
    # Return traces and their weights
    return traces, weights, lml_est
end

"Online inference over a world model using a particle filter."
function world_particle_filter(
        world_init::WorldInit, world_config::WorldConfig,
        obs_traj::Vector{State}, obs_terms::Vector{<:Term}, n_particles::Int;
        batch_size::Int=1, strata=nothing, callback=nothing,
        act_proposal=nothing, act_proposal_args=(),
        ess_threshold::Float64=1/4, resample=true, rejuvenate=nothing)
    # Construct choicemaps from observed trajectory
    @unpack domain = world_config
    n_obs = length(obs_traj)
    obs_choices = traj_choicemaps(obs_traj, domain, obs_terms;
                                  batch_size=batch_size)
    # Initialize particle filter
    world_args = (world_init, world_config)
    argdiffs = (UnknownChange(), NoChange(), NoChange())
    pf_state =  initialize_pf_stratified(world_model, (0, world_args...),
                                         choicemap(), strata, n_particles)
    # Compute times for each batch
    timesteps = collect(batch_size:batch_size:n_obs)
    if timesteps[end] != n_obs push!(timesteps, n_obs) end
    # Feed new observations batch-wise
    for (batch_i, t) in enumerate(timesteps)
        if resample && get_ess(pf_state) < (n_particles * ess_threshold)
            @debug "Resampling..."
            pf_residual_resample!(pf_state)
            if rejuvenate != nothing rejuvenate(pf_state) end
        end
        if act_proposal == nothing
            pf_update!(pf_state, (t, world_args...),
                       argdiffs, obs_choices[batch_i])
        else
            pf_update!(pf_state, (t, world_args...), argdiffs,
                       obs_choices[batch_i], propose_act,
                       (obs_traj[t], act_proposal, act_proposal_args))
        end
        if callback != nothing # Run callback on current traces
            trs, ws = get_traces(pf_state), lognorm(get_log_weights(pf_state))
            callback(t, obs_traj[t], trs, ws)
        end
    end
    # Return particles and their weights
    traces, weights = get_traces(pf_state), lognorm(get_log_weights(pf_state))
    lml_est = logsumexp(get_log_weights(pf_state)) - log(n_particles)
    return traces, weights, lml_est
end
