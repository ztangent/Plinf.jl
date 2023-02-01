## Belief model configurations ##

export BeliefConfig, DirectBeliefConfig

"""
    BeliefConfig

Configuration of an agent's belief model.

# Fields

$(FIELDS)
"""
struct BeliefConfig{T,U,V}
    "Initializer with arguments `(env_state, init_args...)`."
    init::T
    "Trailing arguments to initializer."
    init_args::U
    "Transition function with arguments `(t, belief_state, env_state, step_args...)`."
    step::GenerativeFunction
    "Trailing arguments to transition function."
    step_args::V
end

# Direct belief model #

"""
    DirectBeliefConfig()

Constructs a `BeliefConfig` where an agent's beliefs directly correspond
to the full environment state (and all past information or beliefs are ignored).
"""
function DirectBeliefConfig()
    return BeliefConfig(direct_belief_init, (), direct_belief_step, ())
end

"""
    direct_belief_init(env_state)

Belief initializer which directly returns the current environment state.
"""
@gen direct_belief_init(env_state) = env_state

"""
    direct_belief_step(t, belief_state, env_state)

Belief update which directly returns the current environment state.
"""
@gen direct_belief_step(t, belief_state, env_state) = env_state
