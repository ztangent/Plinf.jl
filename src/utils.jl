export labeled_cat, labeled_unif, flip

"Unzips an array of tuples to a tuple of arrays."
unzip(a) = map(x->getfield.(a, x), fieldnames(eltype(a)))

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

"Convert from block-words PDDL state representation to RNN input representation"
function block_words_RNN_conversion(state::State)
    blocks = [term.args[1] for term in types]
    n = length(blocks)
    # on requires size porportional to square of the number of blocks,
    # ontable, clear, and holding require size proportional to number of blocks,
    # and handempty requires constant size
    dimension = n ^ 2 + 3 * n + 1
    encoding = zeros(dimension)
    facts = state.facts
    for fact in facts
        if fact.name == :on
            top, base = fact.args
            idx = (n - 1) * findfirst(isequal(top), blocks) + findfirst(isequal(base), blocks)
        elseif fact.name == :ontable
            block = fact.args[1]
            idx = n ^ 2 + findfirst(isequal(block), blocks)
        elseif fact.name == :clear
            block = fact.args[1]
            idx = n ^ 2 + n + findfirst(isequal(block), blocks)
        elseif fact.name == :holding
            block = fact.args[1]
            idx = n ^ 2 + 2 * n + findfirst(isequal(block), blocks)
        elseif fact.name == :handempty
            idx = n ^ 2 + 3 * n + 1
        end
        encoding[idx] = 1
    end
    return encoding
end

"Convert from gems, keys, doors PDDL state representation to RNN input representation"
function gems_keys_doors_RNN_conversion(state::State)
    encoding = []
    types = state.types
    facts = state.facts
    fluents = state.fluents
    return encoding
end
