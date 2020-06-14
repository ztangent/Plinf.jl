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

"Return the effective sample size of the particles in the filter."
function get_ess(pf_state::ParticleFilterState)
    return Gen.effective_sample_size(lognorm(pf_state.log_weights))
end

"Perform stratified resampling of the particles in the filter."
function pf_stratified_resample!(pf_state::ParticleFilterState;
                                 sort_particles::Bool=true)
    # Optionally sort particles by weight before resampling
    if sort_particles
        order = sortperm(pf_state.log_weights)
        pf_state.log_weights = pf_state.log_weights[order]
        pf_state.traces = pf_state.traces[order]
    end
    n_particles = length(pf_state.traces)
    log_total_weight, log_weights = Gen.normalize_weights(pf_state.log_weights)
    weights = exp.(log_weights)
    pf_state.log_ml_est += log_total_weight - log(n_particles)
    # Sample particles at the points [u_init:(1/n_particles):1]
    u_init = uniform(0, 1/n_particles)
    i_old, accum_weight = 0, 0.0
    for (i_new, u) in enumerate(u_init:(1/n_particles):1)
        while accum_weight < u
            accum_weight += weights[i_old+1]
            i_old += 1
        end
        pf_state.new_traces[i_new] = pf_state.traces[i_old]
        pf_state.log_weights[i_new] = 0.0
    end
    # Swap references
    tmp = pf_state.traces
    pf_state.traces = pf_state.new_traces
    pf_state.new_traces = tmp
    return pf_state
end

"Move-reweight MCMC update (cf. Marques & Storvik, 2013)."
function move_reweight(trace, proposal::GenerativeFunction,
                       proposal_args::Tuple)
    model_args = Gen.get_args(trace)
    argdiffs = map((_) -> NoChange(), model_args)
    (fwd_choices, fwd_score, fwd_ret) =
        propose(proposal, (trace, proposal_args...,))
    (new_trace, weight, _, discard) = Gen.update(trace,
        model_args, argdiffs, fwd_choices)
    (bwd_score, bwd_ret) =
        assess(proposal, (new_trace, proposal_args...), discard)
    rel_weight = weight - fwd_score + bwd_score
    return new_trace, rel_weight
end

function move_reweight(trace, proposal::GenerativeFunction,
                       proposal_args::Tuple, involution)
    (fwd_choices, fwd_score, fwd_ret) =
        propose(proposal, (trace, proposal_args...,))
    (new_trace, bwd_choices, weight) =
        involution(trace, fwd_choices, fwd_ret, proposal_args)
    (bwd_score, bwd_ret) =
        assess(proposal, (new_trace, proposal_args...), bwd_choices)
    rel_weight = weight - fwd_score + bwd_score
    return new_trace, rel_weight
end

function move_reweight(trace, proposal_new::GenerativeFunction, args_new::Tuple,
                       proposal_old::GenerativeFunction, args_old::Tuple,
                       involution)
    (fwd_choices, fwd_score, fwd_ret) =
        propose(proposal_new, (trace, args_new...,))
    (new_trace, bwd_choices, weight) =
        involution(trace, fwd_choices, fwd_ret, args_new)
    (bwd_score, bwd_ret) =
        assess(proposal_old, (new_trace, args_old...), bwd_choices)
    rel_weight = weight - fwd_score + bwd_score
    return new_trace, rel_weight
end

"Rejuvenate particles via repeated move-reweight steps."
function pf_move_reweight!(pf_state::ParticleFilterState,
                           kern, kern_args::Tuple=(), n_iters::Int=1)
    # Move and reweight each trace
    for (i, trace) in enumerate(pf_state.traces)
        weight = 0
        for k = 1:n_iters
            trace, rel_weight = kern(trace, kern_args...)
            weight += rel_weight
            @debug "Rel. Weight: $rel_weight"
        end
        pf_state.new_traces[i] = trace
        pf_state.log_weights[i] += weight
    end
    # Swap references
    tmp = pf_state.traces
    pf_state.traces = pf_state.new_traces
    pf_state.new_traces = tmp
end

"Rejuvenate particles by repeated application of a Metropolis-Hastings kernel."
function pf_move_accept!(pf_state::ParticleFilterState,
                         kern, kern_args::Tuple=(), n_iters::Int=1)
    # Potentially rejuvenate each trace
    for (i, trace) in enumerate(pf_state.traces)
        for k = 1:n_iters
            trace, accept = kern(trace, kern_args...)
            @debug "Accepted: $accept"
        end
        pf_state.new_traces[i] = trace
    end
    # Swap references
    tmp = pf_state.traces
    pf_state.traces = pf_state.new_traces
    pf_state.new_traces = tmp
end
