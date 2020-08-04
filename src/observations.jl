export observe_params, ground_obs_params
export observe_state, observe_traj
export state_choicemap, traj_choicemaps

"Parameters of observation noise model."
ObserveParams = Dict{Term,Tuple{Distribution, Tuple}}

"Construct a dictionary of observation noise parameters."
function observe_params(args...; state=nothing, domain=nothing)
    entries = observe_params_entry.(args)
    params = Dict{Term,Tuple{Distribution, Tuple}}(entries...)
    # Ground parameters if state is provided
    if state != nothing params = ground_obs_params(params, state, domain) end
    return params
end

observe_params_entry(entry::Tuple{Term, Distribution, Tuple}) =
    entry[1] => (entry[2], entry[3])
observe_params_entry(entry::Tuple{Term, Distribution, Real}) =
    entry[1] => (entry[2], (entry[3],))
observe_params_entry(entry::Tuple{Term, Distribution{Bool}}) =
    entry[1] => (entry[2], (0.05,))
observe_params_entry(entry::Tuple{Term, Gen.Normal}) =
    entry[1] => (entry[2], (0.25,))
observe_params_entry(entry::Tuple{Term, Real}) =
    entry[1] => (flip, (entry[2],))

"Construct default observation noise parameters for a PDDL domain."
function observe_params(domain::Domain; state=nothing,
                        pred_noise=0.05, func_noise=0.25)
    params = Dict{Term,Tuple{Distribution, Tuple}}()
    # Add Boolean corruption noise to all Boolean predicates
    static_preds = get_static_predicates(domain)
    for (name, pred) in domain.predicates
        if pred in static_preds continue end # Ignore static predicates
        if isempty(PDDL.get_args(pred))
            term = pred
        else # Quantify over all variables in compound terms
            types = domain.predtypes[name]
            typeconds = Term[@julog($t(:v)) for (t, v) in zip(types, pred.args)]
            term = Compound(:forall, [Compound(:and, typeconds), pred])
        end
        params[term] = (flip, (pred_noise,))
    end
    # Add Gaussian noise to all numeric fluents / functions
    static_funcs = get_static_functions(domain)
    for (name, func) in domain.functions
        if name == Symbol("total-cost") continue end # Ignore total cost
        if func in static_funcs continue end # Ignore static fluents
        if isempty(PDDL.get_args(func))
            term = func
        else # Quantify over all variables in compound terms
            types = domain.functypes[name]
            typeconds = Term[@julog($t(:v)) for (t, v) in zip(types, func.args)]
            term = Compound(:forall, [Compound(:and, typeconds), func])
        end
        params[term] = (normal, (func_noise,))
    end
    # Ground parameters if state is provided
    if state != nothing params = ground_obs_params(params, state, domain) end
    return params
end

"Ground observation parameters with respect to a domain and state."
function ground_obs_params(params::ObserveParams, state::State,
                           domain::Union{Domain,Nothing}=nothing)
    ground_params = Dict{Term,Tuple{Distribution, Tuple}}()
    for (term, (dist, args)) in params
        if is_ground(term)
            terms = Term[term]
        elseif term.name == :forall # Handle foralls
            cond, body = term.args
            _, subst = satisfy(cond, state, domain; mode=:all)
            terms = Term[substitute(body, s) for s in subst]
        else
            _, subst = satisfy(term, state, domain; mode=:all)
            terms = Term[substitute(term, s) for s in subst]
        end
        for t in terms
            ground_params[t] = (dist, args)
        end
    end
    return ground_params
end

"Observation noise model for PDDL states."
@gen function observe_state(state::State, domain::Domain, params::ObserveParams)
    obs = copy(state)
    for (term, (dist, args)) in params
        # Ground terms if necessary
        if is_ground(term)
            terms = Term[term]
        elseif term.name == :forall # Handle foralls
            cond, body = term.args
            _, subst = satisfy(cond, state, domain; mode=:all)
            terms = Term[substitute(body, s) for s in subst]
        else
            _, subst = satisfy(term, state, domain; mode=:all)
            terms = Term[substitute(term, s) for s in subst]
        end
        for t in terms
            # Add noise to each observed term
            obs[t] = @trace(dist(state[t], args...), t)
        end
    end
    return obs
end

"Observation noise model for PDDL state trajectory."
observe_traj = Map(observe_state)

"Construct Gen choicemap from observed terms in a state."
function state_choicemap(state::State, domain::Union{Domain,Nothing},
                         terms::Vector{<:Term}, addr=:obs)
    ground_terms = Term[]
    # Ground terms if necessary
    for t in terms
        if is_ground(t)
            push!(ground_terms, t)
        elseif t.name == :forall # Handle foralls
            cond, body = t.args
            _, subst = satisfy(cond, state, domain; mode=:all)
            append!(ground_terms, Term[substitute(body, s) for s in subst])
        else
            _, subst = satisfy(t, state, domain; mode=:all)
            append!(ground_terms, Term[substitute(t, s) for s in subst])
        end
    end
    choices = choicemap([t => state[t] for t in ground_terms]...)
    if addr != nothing
        outer_choices = choicemap()
        set_submap!(outer_choices, addr, choices)
        choices = outer_choices
    end
    return choices
end

function state_choicemap(state::State, terms::Vector{<:Term}, addr=:obs)
    state_choicemap(state, nothing, terms, addr)
end

"Construct array of Gen choicemaps from observed trajectory."
function traj_choicemaps(traj::Vector{State}, domain::Union{Domain,Nothing},
                         terms::Vector{<:Term}, traj_addr=:timestep,
                         obs_addr=:obs; as_choicemap::Bool=false,
                         batch_size::Int=1, offset::Int=0)
    traj_choices = ChoiceMap[]
    batch_choices = choicemap()
    if as_choicemap batch_size = length(traj) end
    for (t, state) in enumerate(traj)
        state_choices = state_choicemap(state, domain, terms, obs_addr)
        set_submap!(batch_choices, (traj_addr => t), state_choices)
        if t > offset && mod(t-offset, batch_size) == 0
            push!(traj_choices, batch_choices)
            batch_choices = choicemap()
        end
    end
    if batch_choices != choicemap() push!(traj_choices, batch_choices) end
    return as_choicemap ? traj_choices[1] : traj_choices
end

function traj_choicemaps(traj::Vector{State}, terms::Vector{<:Term},
                         traj_addr=:timestep, obs_addr=:obs; kwargs...)
    traj_choicemaps(traj, nothing, terms, traj_addr, obs_addr; kwargs...)
end
