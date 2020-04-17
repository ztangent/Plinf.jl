export observe_params, observe_state, observe_traj, state_choices, traj_choices

"Parameters of observation noise model."
ObserveParams = Dict{Term,Tuple{Distribution, Tuple}}

"Construct a dictionary of observation noise parameters."
function observe_params(args...)
    entries = observe_params_entry.(args)
    return Dict{Term,Tuple{Distribution, Tuple}}(entries...)
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

"Observation noise model for PDDL states."
@gen function observe_state(state::State, domain::Domain, params::ObserveParams)
    obs = copy(state)
    for (term, (dist, args)) in params
        # Ground terms if necessary
        if is_ground(term)
            terms = Term[term]
        elseif term.name == :forall # Handle foralls
            cond, body = term.args
            _, subst = satisfy(@julog(and(:cond, :body)), state; mode=:all)
            terms = Term[substitute(body, s) for s in subst]
        else
            _, subst = satisfy(term, state; mode=:all)
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
function state_choices(state::State, domain::Union{Domain,Nothing},
                       terms::Vector{<:Term}, addr=nothing)
    ground_terms = Term[]
    # Ground terms if necessary
    for t in terms
        if is_ground(t)
            push!(ground_terms, t)
        elseif t.name == :forall # Handle foralls
            cond, body = t.args
            t = @julog(and(:cond, :body))
            _, subst = satisfy(t, state, domain; mode=:all)
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

state_choices(state::State, terms::Vector{<:Term}, addr=nothing) =
    state_choices(state, nothing, terms, addr)

"Construct Gen choicemap from observed trajectory."
function traj_choices(traj::Vector{State}, domain::Union{Domain,Nothing},
                      terms::Vector{<:Term}, addr=nothing)
    choices = choicemap()
    for (i, state) in enumerate(traj)
        i_choices = state_choices(state, domain, terms)
        set_submap!(choices, (addr => i), i_choices)
    end
    return choices
end

traj_choices(traj::Vector{State}, terms::Vector{<:Term}, addr=nothing) =
    traj_choices(traj, nothing, terms, addr)
