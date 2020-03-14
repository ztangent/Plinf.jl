"Observation noise model for PDDL states."
@gen function observe_state(state::State,
                            facts::Vector{<:Term}, fluents::Vector{<:Term},
                            fact_noise=0.05, fluent_noise=0.25)
    obs = copy(state)
    # Randomly corrupt some of the facts
    for f in facts
        prob = state[f] ? (1-fact_noise) : fact_noise
        obs_val = @trace(bernoulli(prob), f)
        obs[f] = obs_val
    end
    # Add Gaussian noise to numeric-valued fluents
    for f in fluents
        val = state[f]
        obs_val = @trace(normal(state[f], fluent_noise), f)
        obs_val = isa(val, Integer) ? typeof(val)(round(obs_val)) : obs_val
        obs[f] = obs_val
    end
    return obs
end

"Observation noise model for PDDL state trajectory."
observe_traj = Map(observe_state)

"Construct Gen choicemap from observed terms in a state."
function state_choices(state::State, terms::Vector{<:Term}, addr=nothing)
    choices = choicemap([t => state[t] for t in terms]...)
    if addr != nothing
        outer_choices = choicemap()
        set_submap!(outer_choices, addr, choices)
        choices = outer_choices
    end
    return choices
end

"Construct Gen choicemap from observed trajectory."
function traj_choices(traj::Vector{State}, terms::Vector{<:Term}, addr=nothing)
    choices = choicemap()
    for (i, state) in enumerate(traj)
        i_choices = state_choices(state, terms)
        set_submap!(choices, (addr => i), i_choices)
    end
    return choices
end
