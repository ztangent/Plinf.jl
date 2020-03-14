"Pad / truncate vector to specified length."
pad_vector(v::Vector, n::Int) =
    length(v) < n ? [v; fill(v[end], n - length(v))] : v[1:n]

"Repeat arguments so they can be passed to a Map combinator."
repeat_args(args::Tuple, n::Int) = [fill(a, n) for a in obs_args]

"Convert vector of scores to probabiities."
softmax(score) =
    (exp_score = exp.(score .- maximum(score)); exp_score ./ sum(exp_score))

"Labeled categorical distribution."
@dist labeled_cat(labels, probs) = labels[categorical(probs)]
