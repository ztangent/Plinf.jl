## Extensions to Gen's inference library ##

"Return traces for constrained to each value and random choice in `enumerands`."
function enumerate_traces(gen_fn::GenerativeFunction, args::Tuple,
                          enumerands::AbstractDict{<:Any,<:AbstractVector},
                          constraints::ChoiceMap=choicemap())
    grid = Iterators.product((collect(key => val for val in vals)
                            for (key, vals) in enumerands)...)
    tr_ws = [generate(gen_fn, args, merge(constraints, choicemap(elt...)))
             for elt in grid]
    traces, weights = unzip(tr_ws)
    return traces, weights
end

"Initialize a particle filter with stratified sampling."
function initialize_pf_stratified(model::GenerativeFunction{T,U},
                                  model_args::Tuple, observations::ChoiceMap,
                                  strata::AbstractDict{<:Any,<:AbstractVector},
                                  n_particles::Int) where {T,U}
    traces = Vector{Any}(undef, n_particles)
    log_weights = Vector{Float64}(undef, n_particles)
    n_strata = reduce(*, length(vals) for (addr, vals) in strata, init=1)
    n_repeats = n_particles ÷ n_strata
    n_remain = n_particles % n_strata
    # Repeat discrete enumeration of traces over provided strata
    for i in 1:n_repeats
        i_particle = (i-1) * n_strata + 1
        trs, ws = enumerate_traces(model, model_args, strata, observations)
        traces[i_particle:i_particle + n_strata - 1] = trs
        log_weights[i_particle:i_particle + n_strata - 1] = ws
    end
    # Select the remainder at random from the full set of enumerated traces
    if n_remain > 0
        i_particle = n_particles - n_remain + 1
        trs, ws = enumerate_traces(model, model_args, strata, observations)
        idxs = randperm(n_strata)[1:n_remain]
        traces[i_particle:end] = trs[idxs]
        log_weights[i_particle:end] = ws[idxs]
    end
    return ParticleFilterState{U}(traces, Vector{U}(undef, n_particles),
                                      log_weights, 0., collect(1:n_particles))
end

function initialize_pf_stratified(model::GenerativeFunction,
                                  model_args::Tuple, observations::ChoiceMap,
                                  strata::Nothing, n_particles::Int)
    # Initialize as usual if no strata are provided
    initialize_particle_filter(model, model_args, observations, n_particles)
end
