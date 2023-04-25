import Gen: ParticleFilterState

export SequentialInversePlanSearch, SIPS
export sips_init, sips_run, sips_step!

include("utils.jl")
include("choicemaps.jl")
include("rejuvenate.jl")
include("callbacks.jl")

"""
    SequentialInversePlanSearch(
        world_config::WorldConfig;
        options...
    )

Constructs a sequential inverse plan search (SIPS) particle filtering algorithm
for the agent-environment model defined by `world_config`.

# Arguments

$(TYPEDFIELDS)
"""
@kwdef struct SequentialInversePlanSearch{W <: WorldConfig, K}
    "Configuration of world model to perform inference over."
    world_config::W
    "Trigger condition for resampling particles: `[:none, :periodic, :always, :ess]``."
    resample_cond::Symbol = :ess
    "Resampling method: `[:multinomial, :residual, :stratified]`."
    resample_method::Symbol = :multinomial
    "Trigger condition for rejuvenating particles `[:none, :periodic, :always, :ess]`."
    rejuv_cond::Symbol = :none
    "Rejuvenation kernel."
    rejuv_kernel::K = NullKernel()
    "Effective sample size threshold fraction for resampling and rejuvenation."
    ess_threshold::Float64 = 0.25
    "Period for resampling and rejuvenation."
    period::Int = 1
end

const SIPS = SequentialInversePlanSearch

SIPS(world_config; kwargs...) =SIPS(; world_config=world_config, kwargs...)

"""
    (::SIPS)(n_particles, observations, [timesteps]; kwargs...)
    (::SIPS)(n_particles, t_obs_iter; kwargs...)

Run a SIPS particle filter given a series of observation choicemaps and
timesteps, or an iterator over timestep-observation pairs. Returns the final
particle filter state.
"""
(sips::SIPS)(args...; kwargs...) = sips_run(sips, args...; kwargs...)

"Gets current model timestep from a particle filter state."
function get_model_timestep(pf_state::ParticleFilterState)
    return Gen.get_args(get_traces(pf_state)[1])[1]
end

"Decides whether to resample or rejuvenate based on trigger conditions."
function sips_trigger_cond(sips::SIPS, cond::Symbol,
                           t::Int, pf_state::ParticleFilterState)
    if cond == :always
        return true
    elseif cond == :periodic
        return mod(t, sips.period) == 0
    elseif cond == :ess
        n_particles = length(get_traces(pf_state))
        return get_ess(pf_state) < (n_particles * sips.ess_threshold)
    end
    return false
end

"SIPS particle filter initialization."
function sips_init(
    sips::SIPS, n_particles::Int;
    init_timestep::Int = 0,
    init_obs::ChoiceMap=EmptyChoiceMap(),
    init_strata=nothing,
    init_proposal=nothing,
    init_proposal_args=()
)
    args = (init_timestep, sips.world_config)
    if isnothing(init_strata)
        if isnothing(init_proposal)
            pf_state = pf_initialize(world_model, args, init_obs, n_particles)
        else
            pf_state = pf_initialize(world_model, args, init_obs,
                                     init_proposal, init_proposal_args,
                                     n_particles)
        end       
    else
        if isnothing(init_proposal)
            pf_state = pf_initialize(world_model, args, init_obs, init_strata,
                                     n_particles)
        else
            pf_state = pf_initialize(world_model, args, init_obs, init_strata,
                                     init_proposal, init_proposal_args,
                                     n_particles)
        end
    end
    return pf_state
end

"SIPS particle filter step."
function sips_step!(
    pf_state::ParticleFilterState, sips::SIPS,
    t::Int, observations::ChoiceMap=EmptyChoiceMap()
)
    # Update particle filter with new observations
    argdiffs = (UnknownChange(), NoChange())
    pf_update!(pf_state, (t, sips.world_config), argdiffs, observations)
    # Optionally resample
    if sips_trigger_cond(sips, sips.resample_cond, t, pf_state)
        pf_resample!(pf_state, sips.resample_method)
    end
    # Optionally rejuvenate
    if sips_trigger_cond(sips, sips.rejuv_cond, t, pf_state)
        pf_rejuvenate!(pf_state, sips.rejuv_kernel)
    end
    return pf_state
end

"""
    sips_run(sips, n_particles, observations, [timesteps]; kwargs...)
    sips_run(sips, n_particles, t_obs_iter; kwargs...)

Run a SIPS particle filter, given a series of observations and timesteps, or
an iterator over timestep-observation pairs. Returns the final particle filter
state.
"""
function sips_run(
    sips::SIPS, n_particles::Int, t_obs_iter;
    init_args = Dict{Symbol, Any}(),
    callback = (t, obs, pf_state) -> nothing
)
    # Extract initial observation from iterator
    if first(t_obs_iter)[1] == 0
        _, init_obs = first(t_obs_iter)
        if !(init_args isa Dict{Symbol, Any})
            init_args = Dict{Symbol, Any}(pairs(init_args))
        end
        init_args[:init_timestep] = 0
        init_args[:init_obs] = init_obs
        t_obs_iter = Iterators.drop(t_obs_iter, 1)
    end
    # Initialize particle filter
    pf_state = sips_init(sips, n_particles; init_args...)
    callback(get_model_timestep(pf_state), EmptyChoiceMap(), pf_state)
    # Iterate over timesteps and observations
    for (t::Int, obs::ChoiceMap) in t_obs_iter
        pf_state = sips_step!(pf_state, sips, t, obs)
        callback(t, obs, pf_state)
    end
    # Return final particle filter state
    return pf_state
end

function sips_run(
    sips::SIPS, n_particles::Int,
    observations::AbstractVector{<:ChoiceMap},
    timesteps=nothing;
    kwargs...
)
    if isnothing(timesteps) && !isempty(observations)
        init_obs = first(observations)
        if has_submap(init_obs, :init) && !has_submap(init_obs, :timestep)
            timesteps = 0:length(observations)-1
        else
            timesteps = 1:length(observations)
        end
    end
    return sips_run(sips, n_particles, zip(timesteps, observations); kwargs...)
end
