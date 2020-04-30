export observe_params, observe_state, observe_traj
export state_choicemap, traj_choicemaps

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
function state_choicemap(state::State, domain::Union{Domain,Nothing},
                         terms::Vector{<:Term}, addr=:obs)
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

function state_choicemap(state::State, terms::Vector{<:Term}, addr=:obs)
    state_choicemap(state, nothing, terms, addr)
end

"Construct array of Gen choicemaps from observed trajectory."
function traj_choicemaps(traj::Vector{State}, domain::Union{Domain,Nothing},
                         terms::Vector{<:Term}, traj_addr=:timestep,
                         obs_addr=:obs; as_choicemap::Bool=false)
    traj_choices = as_choicemap ? choicemap() : ChoiceMap[]
    for (t, state) in enumerate(traj)
        addr = as_choicemap ? obs_addr : (traj_addr => t => obs_addr)
        state_choices = state_choicemap(state, domain, terms, addr)
        if as_choicemap
            set_submap!(traj_choices, (traj_addr => t), state_choices)
        else
            push!(traj_choices, state_choices)
        end
    end
    return traj_choices
end

function traj_choicemaps(traj::Vector{State}, terms::Vector{<:Term},
                         traj_addr=:timestep, obs_addr=:obs; kwargs...)
    traj_choicemaps(traj, nothing, terms, traj_addr, obs_addr; kwargs...)
end
