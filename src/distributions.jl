"Convert vector of scores to probabiities."
function softmax(score)
    exp_score = exp.(score .- maximum(score))
    return exp_score ./ sum(exp_score)
end

"Labeled categorical distribution."
@dist labeled_cat(labels, probs) = labels[categorical(probs)]
