export labeled_cat, labeled_unif, flip, sym_binom, shifted_neg_binom

"Labeled categorical distribution."
@dist labeled_cat(labels, probs) = labels[categorical(probs)]

"Labeled uniform distribution."
@dist labeled_unif(labels) = labels[uniform_discrete(1, length(labels))]

"Boolean corruption noise."
@dist flip(val::Bool, prob::Float64) = bernoulli((1-val)*prob + val*(1-prob))

"Symmetric Binomial distribution."
@dist sym_binom(mean::Int, scale::Int) = binom(2*scale, 0.5) - scale + mean

"Shifted negative binomial distribution."
@dist shifted_neg_binom(r::Real, p::Real, shift::Int) = neg_binom(r, p) + shift

"""
    maybe_sample(fn, [args])

If `fn` is a `GenerativeFunction`, sample from `fn(args...)`. If `fn` is a
`Function`, call `fn(args)`. Otherwise, return `fn`.
"""
@gen function maybe_sample(fn, args::Tuple=())
    if isa(fn, GenerativeFunction)
        return @trace(fn(args...))
    elseif isa(fn, Function)
        return fn(args...)
    else
        return fn
    end
end
