## Utilities for constructing choicemaps from PDDL states and actions ##

export ground_obs_terms
export state_choicemap, state_choicemap_vec, state_choicemap_pairs
export act_choicemap_vec, act_choicemap_pairs

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
    state_choicemap(state, obs_terms; addr=nothing)

Construct a Gen choicemap from observed fluent terms in a PDDL `state`, where
each  term will serve as the choice's address. If `addr` is set to `nothing`,
all addresses will be at the top-level. Otherwise, they will be nested under
`addr` as a (hierarchical) address.
"""
function state_choicemap(
    state::State, obs_terms::AbstractVector{<:Term};
    addr=nothing, domain=nothing
)
    # Ground terms if domain is provided
    if domain !== nothing
        obs_terms = ground_obs_terms(obs_terms, domain, state)
    end
    # Construct choicemap
    choices = choicemap((term => state[term] for term in obs_terms)...)
    if addr !== nothing
        outer_choices = choicemap()
        set_submap!(outer_choices, addr, choices)
        choices = outer_choices
    end
    return choices
end

"""
    state_choicemap_vec(
        states, obs_terms;
        include_init = true,
        init_addr = :init => :obs,
        addr_fn = t -> :timestep => t => :obs,
        batch_size = 1,
        split_idxs = nothing
    )

Construct a vector of Gen choicemaps from observed fluent terms in a sequence of
PDDL `states`. Each term will serve as the choice's base address.

The `init_addr` argument determines the address of the initial observation.
If `include_init` is `true`, the first element of `states` will be converted to
a choicemap for the initial observation (i.e. timestep 0), which is returned 
as the first element of the vector. Otherwise, the first element of `states`
will be treated as the observation for timestep 1. 

The function `addr_fn` will be used to construct a hierarchical address from
the index of each (non-initial) state. By default, observed terms for the `t`th
state will be under the address `:timestep => t => :obs`, where `t = 1`
corresponds to the first element of `states` if `include_init` is `false`, and
to the second element otherwise.

The `batch_size` variable determines how many (non-initial) states are
batched into a single choicemap. By default, each state has its own choicemap.
If `batch_size` is set to `:all`, all states are returned in a single choicemap.

Instead of specifying `batch_size`, a list of `split_idxs` to specify the
indices at which a state trajectory should be split into batches.
"""
function state_choicemap_vec(
    states::AbstractVector{<:State}, obs_terms::AbstractVector{<:Term};
    include_init = true, init_addr = :init => :obs,
    addr_fn = t -> :timestep => t => :obs,
    batch_size = 1, split_idxs = nothing, domain = nothing
)
    # Ground terms if domain is provided
    if domain !== nothing
        obs_terms = ground_obs_terms(obs_terms, domain, state)
    end
    # Construct initial choices
    if include_init
        init_choices = state_choicemap(states[1], obs_terms; addr=init_addr)
        states = states[2:end]
    end
    # Partition states into batches
    if split_idxs !== nothing
        batch_iter = batch_split(enumerate(states), split_idxs)
    else
        batch_size = batch_size == :all ? length(states) : batch_size
        batch_iter = Iterators.partition(enumerate(states), batch_size)
    end
    # Construct choices batch-wise
    choices_vec = map(batch_iter) do batch
        choices = choicemap()
        for (t, state) in batch
            state_choices = state_choicemap(state, obs_terms; addr=nothing)
            set_submap!(choices, addr_fn(t), state_choices)
        end
        return choices::DynamicChoiceMap
    end
    # Add initial choice map
    if include_init
        pushfirst!(choices_vec, init_choices)
    end
    return choices_vec
end

"""
    state_choicemap_pairs(
        states, obs_terms;
        include_init = true,
        init_addr = :init => :obs,
        addr_fn = t -> :timestep => t => :obs,
        batch_size = 1,
        split_idxs = nothing
    )

Construct a vector of `t => choicemap` pairs from observed fluent terms
in a sequence of PDDL `states`, where `t` is the last timestep of the batch 
of states represented by each choicemap. Each term will serve as the
choice's base address.

If `include_init` is `true`, the first element of `states` will be converted to
a choicemap for the initial observation (i.e. `t = 0`), which is returned 
as the first element of the vector. Otherwise, the first element of `states`
will be treated as the observation for `t = 1`.

See [`state_choicemap_vec`](@ref) for explanation of other arguments.
"""
function state_choicemap_pairs(
    states::AbstractVector{<:State}, obs_terms::AbstractVector{<:Term};
    include_init = true, init_addr = :init => :obs,
    addr_fn = t-> :timestep => t => :obs,
    batch_size = 1, split_idxs = nothing, domain = nothing
)
    # Ground terms if domain is provided
    if domain !== nothing
        obs_terms = ground_obs_terms(obs_terms, domain, state)
    end
    # Construct initial choices
    if include_init
        init_choices = state_choicemap(states[1], obs_terms; addr=init_addr)
        states = states[2:end]
    end
    # Partition states into batches
    if split_idxs !== nothing
        batch_iter = batch_split(enumerate(states), split_idxs)
    else
        batch_size = batch_size == :all ? length(states) : batch_size
        batch_iter = Iterators.partition(enumerate(states), batch_size)
    end
    # Construct choices batch-wise
    t_choice_pairs = map(batch_iter) do batch
        choices = choicemap()
        t_batch = 0
        for (t, state) in batch
            t_batch = t
            state_choices = state_choicemap(state, obs_terms; addr=nothing)
            set_submap!(choices, addr_fn(t), state_choices)
        end
        return (t_batch => choices)::Pair{Int, DynamicChoiceMap}
    end
    # Merge initial choice map into first choicemap
    if include_init
        pushfirst!(t_choice_pairs, 0 => init_choices)
    end
    return t_choice_pairs
end

"""
    act_choicemap_vec(
        actions;
        addr_fn = t -> :timestep => t => :act,
        batch_size = 1,
        split_idxs = nothing
    )

Construct a vector of Gen choicemaps from a series of observed actions. The
base address of the action is assumed to be `:act`.

The function `addr_fn` will be used to construct a hierarchical address from
the index of each action. By default, the `t`th action will be under the
address `:timestep => t => :act`.

See [`state_choicemap_vec`](@ref) for explanation of other arguments.
"""
function act_choicemap_vec(
    actions::AbstractVector{<:Term},;
    addr_fn =  t -> :timestep => t => :act,
    batch_size = 1, split_idxs = nothing
)
    # Partition states into batches
    if split_idxs !== nothing
        batch_iter = batch_split(enumerate(actions), split_idxs)
    else
        batch_size = batch_size == :all ? length(actions) : batch_size
        batch_iter = Iterators.partition(enumerate(actions), batch_size)
    end
    # Construct choices batch-wise
    choices_vec = map(batch_iter) do batch
        choices = choicemap()
        for (t, act) in batch
            act_choices = choicemap(:act => act)
            set_submap!(choices, addr_fn(t), act_choices)
        end
        return choices
    end
    return choices_vec
end

"""
    act_choicemap_vec(
        actions;
        addr_fn = t -> :timestep => t => :act,
        batch_size = 1,
        split_idxs = nothing
    )

Construct a vector of `(t => choicemap)` pairs from a series of observed
actions, where `t` is the last timestep of the batch of actions represented
by each choicemap.

See [`act_choicemap_vec`](@ref) for explanation of other arguments.
"""
function act_choicemap_pairs(
    actions::AbstractVector{<:Term},;
    addr_fn =  t -> :timestep => t => :act,
    batch_size = 1, split_idxs = nothing
)
    # Partition states into batches
    if split_idxs !== nothing
        batch_iter = batch_split(enumerate(actions), split_idxs)
    else
        batch_size = batch_size == :all ? length(actions) : batch_size
        batch_iter = Iterators.partition(enumerate(actions), batch_size)
    end
    # Construct choices batch-wise
    choices_vec = map(batch_iter) do batch
        choices = choicemap()
        t_batch = 0
        for (t, act) in batch
            t_batch = t
            act_choices = choicemap(:act => act)
            set_submap!(choices, addr_fn(t), act_choices)
        end
        return t_batch => choices
    end
    return choices_vec
end

"Split an iterable into segments / batches at the specified indices."
function batch_split(iter, split_idxs)
    @assert all(split_idxs .<= length(iter))
    split_idxs = [0; split_idxs]
    if split_idxs[end] != length(iter)
        push!(split_idxs, length(iter))
    end
    iter = collect(iter)
    batch_iter = [iter[split_idxs[i]+1:split_idxs[i+1]]
                  for i in 1:length(split_idxs)-1]
    return batch_iter
end
