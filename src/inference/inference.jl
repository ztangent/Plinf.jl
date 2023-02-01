export world_importance_sampler, world_particle_filter

using GenParticleFilters

include("utils.jl")
include("choicemaps.jl")
include("kernels.jl")

"Online inference over a world model using a particle filter."
function world_particle_filter(
        world_config::WorldConfig,
        obs_traj::Vector{<:State}, obs_terms::Vector{<:Term}, n_particles::Int;
        batch_size::Int=1, strata=nothing, callback=nothing,
        ess_threshold::Float64=1/4, resample=true, rejuvenate=nothing)
    # Construct choicemaps from observed trajectory
    n_obs = length(obs_traj)
    obs_choices = state_choicemap_vec(obs_traj, obs_terms; batch_size=batch_size)
    # Initialize particle filter
    argdiffs = (UnknownChange(), NoChange())
    pf_state =  initialize_pf_stratified(world_model, (0, world_config),
                                         choicemap(), strata, n_particles)
    # Compute times for each batch
    timesteps = collect(batch_size:batch_size:n_obs)
    if timesteps[end] != n_obs push!(timesteps, n_obs) end
    # Feed new observations batch-wise
    for (batch_i, t) in enumerate(timesteps)
        if resample && get_ess(pf_state) < (n_particles * ess_threshold)
            @debug "Resampling..."
            pf_residual_resample!(pf_state)
            if rejuvenate !== nothing rejuvenate(pf_state) end
        end
        pf_update!(pf_state, (t, world_config), argdiffs, obs_choices[batch_i])
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
