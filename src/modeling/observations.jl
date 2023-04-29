## Observation models ##

export ObsConfig, PerfectObsConfig, MarkovObsConfig
export ObsNoiseParams, ground_obs_params
export observe_state

"""
    ObsConfig

Configuration of an observation model.

# Fields

$(FIELDS)
"""
struct ObsConfig{T,U,V}
    "Initializer with arguments `(env_state, init_args...)`."
    init::T
    "Trailing arguments to initializer."
    init_args::U
    "Transition function with arguments `(t, obs_state, env_state, step_args...)`."
    step::GenerativeFunction
    "Trailing arguments to transition function."
    step_args::V
end

# Perfect observation model #

"""
    PerfectObsConfig()

Constructs an `ObsConfig` with no observation noise (perfect observability).
"""
function PerfectObsConfig()
    return ObsConfig(perfect_obs_init, (), perfect_obs_step, ())
end

"""
    perfect_obs_init(env_state)

Observation initializer which directly returns the current environment state.
"""
@gen perfect_obs_init(env_state) = env_state

"""
    perfect_obs_step(t, obs_state, env_state)

Observation step which directly returns the current environment state.
"""
@gen perfect_obs_step(t, obs_state, env_state) = env_state

# Markov observation model #

"""
    MarkovObsConfig(domain::Domain, obs_params::ObsNoiseParams)

Constructs an `ObsConfig` where the observation noise distribution only depends
on the current environment state.
"""
function MarkovObsConfig(domain::Domain, obs_params)
    args = (domain, obs_params)
    return ObsConfig(markov_obs_init, args, markov_obs_step, args)
end

"""
    markov_obs_init(env_state, domain, obs_params)

Observation initializer which depends on only the current environment state.
"""
@gen function markov_obs_init(env_state, domain, obs_params)
    env_state = convert(State, env_state) # Convert to PDDL state to be safe
    obs_state = {*} ~ observe_state(domain, env_state, obs_params)
    return obs_state
end

"""
    markov_obs_step(t, obs_state, env_state, obs_params)

Observation step which depends on only the current environment state.
"""
@gen function markov_obs_step(t, obs_state, env_state, domain, obs_params)
    env_state = convert(State, env_state) # Convert to PDDL state to be safe
    obs_state = {*} ~ observe_state(domain, env_state, obs_params)
    return obs_state
end

"""
    ObsNoiseParams

Observation noise parameters for noisy observation of a PDDL state.
"""
struct ObsNoiseParams
    entries::Dict{Term,Tuple{Distribution, Tuple}}
    is_ground::Bool
end

Base.keys(params::ObsNoiseParams) = keys(params.entries)
Base.values(params::ObsNoiseParams) = values(params.entries)

"""
    ObsNoiseParams(entries)

Constructs noise parameters from a dictionary that maps observed fluent `Term`s
to `Distribution`s and arguments. 
"""
function ObsNoiseParams(entries::Dict)
    is_ground = all(PDDL.is_ground(term) for term in keys(entries))
    return ObsNoiseParams(entries, is_ground)
end

"""
    ObsNoiseParams(entries::Tuple...)

Constructs noise parameters from a series of tuple arguments of the form
`(term, dist, dist_args...)`, where `term` is an observed fluent `Term`, `dist`
is a  `Distribution`, and `dist_args` are all distribution arguments trailing
the first argument (which is reserved for the true value of the term).

If `dist_args` are not specified, a default value of `0.05` is assumed for 
distributions over `Boolean` arguments, a default of `0.25` is assumed for
`Normal` distributions.
"""
function ObsNoiseParams(args::Tuple...; domain=nothing, state=nothing)
    entries = obs_params_entry.(args)
    params = ObsNoiseParams(Dict{Term,Tuple{Distribution, Tuple}}(entries...))
    # Ground parameters if domain and state are provided
    if !params.is_ground && !isnothing(domain) && !isnothing(state)
        params = ground_obs_params(params, domain, state)
    end
    return params
end

"""
    ObsNoiseParams(domain, [state]; pred_noise=0.05, func_noise=0.25)

Automatically constructs noise parameters for all predicates and numeric fluents
in a `domain`, grounding the terms if an initial `state` is provided.
"""
function ObsNoiseParams(domain::Domain, state::Union{State,Nothing}=nothing;
                        pred_noise=0.05, func_noise=0.25)
    entries = Dict{Term,Tuple{Distribution, Tuple}}()
    static_fluents = infer_static_fluents(domain)
    # Add Boolean corruption noise to all Boolean predicates
    for (name, pred) in pairs(PDDL.get_predicates(domain))
        name in static_fluents && continue # Skip static predicates
        if isempty(pred.args)
            term = convert(Term, pred)
        else # Quantify over all variables in compound terms
            typeconds = Term[Compound(ty, [var]) for (ty, var)
                             in zip(pred.argtypes, pred.args)]
            typeconds = Compound(:and, typeconds)
            term = Compound(:forall, [typeconds, convert(Term, pred)])
        end
        entries[term] = (flip, (pred_noise,))
    end
    # Add Gaussian noise to all numeric fluents
    for (name, func) in pairs(PDDL.get_functions(domain))
        name == Symbol("total-cost")  && continue # Skip total cost fluent
        name in static_fluents && continue # Skip static fluents
        func.type != :numeric && continue # Skip non-numeric fluents
        if PDDL.arity(func) == 0
            term = convert(Term, func)
        else # Quantify over all variables in compound terms
            typeconds = Term[Compound(ty, [var]) for (ty, var)
                             in zip(func.argtypes, func.args)]
            typeconds = Compound(:and, typeconds)
            term = Compound(:forall, [typeconds, convert(Term, func)])
        end
        entries[term] = (normal, (func_noise,))
    end
    params = ObsNoiseParams(entries)
    # Ground parameters if state is provided
    if state !== nothing
        params = ground_obs_params(params, domain, state)
    end
    return params
end

"Convert tuple arguments to observation parameter pairs."
obs_params_entry(entry::Tuple{Term, Distribution, Tuple}) =
    entry[1] => (entry[2], entry[3])
obs_params_entry(entry::Tuple{Term, Distribution, Real}) =
    entry[1] => (entry[2], (entry[3],))
obs_params_entry(entry::Tuple{Term, Distribution{Bool}}) =
    entry[1] => (entry[2], (0.05,))
obs_params_entry(entry::Tuple{Term, Gen.Normal}) =
    entry[1] => (entry[2], (0.25,))
obs_params_entry(entry::Tuple{Term, Real}) =
    entry[1] => (flip, (entry[2],))

"Ground observation parameters with respect to a domain and state."
function ground_obs_params(params::ObsNoiseParams, domain::Domain, state::State)
    entries = Dict{Term,Tuple{Distribution, Tuple}}()
    for (term, (dist, args)) in params.entries
        if PDDL.is_ground(term)
            terms = Term[term]
        elseif term.name == :forall # Handle foralls
            cond, body = term.args
            subst = satisfiers(domain, state, cond)
            terms = Term[PDDL.substitute(body, s) for s in subst]
        else
            subst = satisfiers(domain, state, term)
            terms = Term[PDDL.substitute(term, s) for s in subst]
        end
        for t in terms
            entries[t] = (dist, args)
        end
    end
    return ObsNoiseParams(entries, true)
end

"""
    observe_state(domain::Domain, state::State, params)

Observation noise model for PDDL states.
"""
@gen function observe_state(domain::Domain, state::State,
                            params::ObsNoiseParams)
    obs_state = copy(state)
    if params.is_ground # Specialized code if all observed terms are ground
        for (term, (dist, args)) in params.entries
            obs_val = {term} ~ dist(state[term], args...)
            if (obs_val isa AbstractFloat &&
                PDDL.get_fluents(domain)[term.name].type == :integer)
                obs_val = round(Int, obs_val)
            end
            obs_state[term] = obs_val
        end
    else # Handle potentially ungrounded terms
        for (term, (dist, args)) in params.entries
            # Ground terms if necessary
            if PDDL.is_ground(term)
                terms = Term[term]
            elseif term.name == :forall # Handle foralls
                cond, body = term.args
                subst = satisfiers(domain, state, cond)
                terms = Term[substitute(body, s) for s in subst]
            else
                subst = satisfiers(domain, state, term)
                terms = Term[substitute(term, s) for s in subst]
            end
            # Add noise to each observed term
            for t in terms
                obs_val = {t} ~ dist(state[t], args...)
                if PDDL.get_fluents(domain)[t.name].type == :integer
                    obs_val = round(Int, obs_val)
                end
                obs_state[t] = obs_val
            end
        end
    end
    return obs_state
end
