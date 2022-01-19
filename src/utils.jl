export labeled_cat, labeled_unif, flip

"Unzips an array of tuples to a tuple of arrays."
unzip(a) = map(x->getfield.(a, x), fieldnames(eltype(a)))

"Unzips dictionaries or arrays of pairs."
unzip_pairs(ps::AbstractDict) = unzip_pairs(collect(ps))
unzip_pairs(ps::AbstractArray{<:Pair}) = first.(ps), last.(ps)

"Pad / truncate vector to specified length."
pad_vector(v::Vector, n::Int) =
    length(v) < n ? [v; fill(v[end], n - length(v))] : v[1:n]

"Repeat arguments so they can be passed to a Map combinator."
repeat_args(args::Tuple, n::Int) = [fill(a, n) for a in obs_args]

"Normalize log weights."
lognorm(w) = w .- logsumexp(w)

"Convert vector of scores to probabiities."
softmax(score) =
    (exp_score = exp.(score .- maximum(score)); exp_score ./ sum(exp_score))

"Return output type of distribution."
dist_type(d::Distribution{T}) where {T} = T

"Labeled categorical distribution."
@dist labeled_cat(labels, probs) = labels[categorical(probs)]

"Labeled uniform distribution."
@dist labeled_unif(labels) = labels[uniform_discrete(1, length(labels))]

"Boolean corruption noise."
@dist flip(val::Bool, prob::Float64) = bernoulli((1-val)*prob + val*(1-prob))

"Sample functions passed as args to a static generative function."
@gen function sample_fn(fn, args::Tuple=())
    if isa(fn, GenerativeFunction)
        return @trace(fn(args...))
    elseif isa(fn, Function)
        return fn(args...)
    else
        return fn
    end
end

"""
    simulate(domain, state, actions; kwargs...)
Returns the state trajectory that results from applying a sequence of `actions`
to an initial `state` in a given `domain`. Keyword arguments specify whether
to `check` if action preconditions hold, the `fail_mode` (`:error` or `:no_op`)
if they do not, and a `callback` function to apply after each step.
"""
function simulate(domain::Domain, state::State, actions::Vector{<:Term};
                  check::Bool=true, fail_mode::Symbol=:error,
                  callback::Function=(d,s,a)->nothing)
    trajectory = State[state]
    callback(domain, state, Const(:start))
    for act in actions
        state = transition(domain, state, act; check=check, fail_mode=fail_mode)
        push!(trajectory, state)
        callback(domain, state, act)
    end
    return trajectory
end

"Memoized version of a function `f` with a local `cache`."
struct CachedFunction{F,D} <: Function
    f::F
    cache::D
end

(cf::CachedFunction)(args...) =
    get!(() -> cf.f(args...), cf.cache, args)

Base.empty!(cf::CachedFunction) =
    empty!(cf.cache)

collected_available(domain::Domain, state::State) =
    collect(available(domain, state))

collected_available(domain::GenericDomain, state::State) =
    available(domain, state)

"Construct cached version of `available`."
cached_available() =
    CachedFunction(collected_available,
                   Dict{Tuple{Domain,State},Vector{Compound}}())
