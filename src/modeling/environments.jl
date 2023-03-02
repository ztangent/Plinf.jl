## Environment models ##

export EnvConfig, PDDLEnvConfig

"""
    EnvConfig

Configuration of an environment model.

# Fields

$(FIELDS)
"""
struct EnvConfig{T,U,V}
    "Initializer with arguments `(init_args...)`."
    init::T
    "Trailing arguments to initializer."
    init_args::U
    "Transition function with arguments `(t, env_state, act_state, step_args...)`."
    step::GenerativeFunction
    "Trailing arguments to transition function."
    step_args::V
end

# Static environment model #

"""
    StaticEnvConfig(init=nothing, init_args=())

Constructs a `EnvConfig` where the environment state never changes.
"""
function StaticEnvConfig(init=nothing, init_args=())
    return EnvConfig(init, init_args, static_env_step, ())
end

"""
    static_env_step(t, env_state::State, action::Term)

Static environment transition that returns previous state unmodified.
"""
@gen static_env_step(t, env_state::State, action::Term) = env_state


# PDDL environment model #

"""
    PDDLEnvConfig(domain::Domain, init_env_state::State)
    PDDLEnvConfig(domain::Domain, state_prior, state_prior_args=())

Constructs a deterministic `EnvConfig` from a PDDL domain and initial state.
A `state_prior` can also be specified instead of a `state`.
"""
function PDDLEnvConfig(domain::Domain, init, init_args::Tuple=())
    return EnvConfig(init, init_args, pddl_env_step, (domain,))
end

"""
    pddl_env_step(t, env_state::State, action::Term, domain::Domain)

PDDL environment transition function with deterministic dynamics.
"""
@gen function pddl_env_step(t, env_state::State, action::Term, domain::Domain)
    if action.name == Symbol("--") || !available(domain, env_state, action)
        return env_state
    else
        return transition(domain, env_state, action, check=false)
    end
end
