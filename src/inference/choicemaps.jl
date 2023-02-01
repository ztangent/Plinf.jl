## Utilities for constructing choicemaps from PDDL states and actions ##

export ground_obs_terms
export state_choicemap, state_choicemap_vec

"""
    ground_obs_terms(terms, domain, state)

Grounds a list of observed terms in a `domain` and `state`.
"""
function ground_obs_terms(terms::AbstractVector{<:Term},
                          domain::Domain, state::State)
    ground_terms = Term[]
    # Ground terms if necessary
    for t in terms
        if is_ground(t)
            push!(ground_terms, t)
        elseif t.name == :forall # Handle foralls
            cond, body = t.args
            subst = satisfiers(domain, state, cond)
            append!(ground_terms, Term[substitute(body, s) for s in subst])
        else
            subst = satisfiers(domain, state, t)
            append!(ground_terms, Term[substitute(t, s) for s in subst])
        end
    end
    return ground_terms
end

"""
    state_choicemap(state, obs_terms; addr=:obs)

Construct a Gen choicemap from observed fluent terms in a PDDL `state`, where
each  term will serve as the choice's address. If `addr` is set to `nothing`,
all addresses will be at the top-level. Otherwise, they will be nested under
`addr` as a (hierarchical) address.
"""
function state_choicemap(
    state::State, obs_terms::AbstractVector{<:Term};
    addr=:obs, domain=nothing
)
    # Ground terms if domain is provided
    if domain !== nothing
        obs_terms = ground_obs_terms(obs_terms, domain, state)
    end
    # Construct choicemap
    choices = choicemap((t => state[t] for t in obs_terms)...)
    if addr !== nothing
        outer_choices = choicemap()
        set_submap!(outer_choices, addr, choices)
        choices = outer_choices
    end
    return choices
end

"""
    state_choicemap_vec(states, obs_terms;
                        addr_fn = t -> :timestep => t => :obs,
                        batch_size = 1)

Construct a vector of Gen choicemaps from observed fluent terms in a sequence of
PDDL `states`. Each term will serve as the choice's base address.

The function `addr_fn` will be usedd to construct a hierarchical address from
the index of each state. By default, observed terms for the `t`th state will be
under the address `:timestep => t => :obs`.

The `batch_size` variable determines how many states are batched into a single
choicemap. By default, each state has its own choicemap. If `batch_size` is set
to `:all`, all states are returned in a single choicemap.
"""
function state_choicemap_vec(
    states::AbstractVector{<:State}, obs_terms::AbstractVector{<:Term};
    addr_fn =  t-> :timestep => t => :obs, batch_size = 1, domain = nothing
)
    # Ground terms if domain is provided
    if domain !== nothing
        obs_terms = ground_obs_terms(obs_terms, domain, state)
    end
    # Accumate choices batch-wise
    batch_size = batch_size == :all ? length(states) : batch_size
    choices_vec = DynamicChoiceMap[]
    choices = choicemap()
    for (t, state) in enumerate(states)
        state_choices = state_choicemap(state, obs_terms; addr=nothing)
        set_submap!(choices, addr_fn(t), state_choices)
        if mod(t, batch_size) == 0
            push!(choices_vec, choices)
            choices = choicemap()
        end
    end
    # Add any remaining choicemaps
    if mod(length(states), batch_size) > 0
        push!(choices_vec, choices)
    end
    return choices_vec
end
