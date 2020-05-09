using DataStructures: OrderedDict

function word_to_terms(word::String)
    top = Symbol(word[1])
    bottom = Symbol(word[end])
    terms = @julog Term[clear($top), ontable($bottom)]
    for (c1, c2) in zip(word[1:end-1], word[2:end])
        c1, c2 = Symbol(c1), Symbol(c2)
        push!(terms, @julog(on($c1, $c2)))
    end
    return terms
end

function get_goal_probs(traces, weights, goal_idxs=[])
    goal_probs = OrderedDict{Any,Float64}(g => 0.0 for g in goal_idxs)
    for (tr, w) in zip(traces, weights)
        goal_idx = tr[:goal_init => :goal]
        prob = get(goal_probs, goal_idx, 0.0)
        goal_probs[goal_idx] = prob + exp(w)
    end
    return goal_probs
end

function print_goal_probs(goal_probs)
    for (goal, prob) in sort(goal_probs)
        @printf("%.3f\t", prob)
    end
    print("\n")
end
