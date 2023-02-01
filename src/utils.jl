"Unzips an array of tuples to a tuple of arrays."
unzip(a) = map(x->getfield.(a, x), fieldnames(eltype(a)))

"Unzips dictionaries or arrays of pairs."
unzip_pairs(ps::AbstractDict) = unzip_pairs(collect(ps))
unzip_pairs(ps::AbstractArray{<:Pair}) = first.(ps), last.(ps)

"Normalize log weights."
lognorm(w) = w .- logsumexp(w)

"Convert vector of scores to probabiities."
softmax(score) =
    (exp_score = exp.(score .- maximum(score)); exp_score ./ sum(exp_score))

"Return output type of distribution."
disttype(d::Distribution{T}) where {T} = T
