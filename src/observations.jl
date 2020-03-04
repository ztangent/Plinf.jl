"Observation noise model for PDDL states."
@gen function observe(state::State, facts::Vector{Term}, fluents::Vector{Term},
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

"Construct Gen choicemap from observed facts/fluents in a state."
function obs_choicemap(state::State, facts::Vector{<:Term}, fluents::Vector{<:Term})
    choices = choicemap()
    for f in facts
        choices[f] = state[f]
    end
    for f in fluents
        choices[f] = state[f]
    end
    return choices
end
