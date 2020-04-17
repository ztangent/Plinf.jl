pos_to_terms(pos) = @julog([xpos == $(pos[1]), ypos == $(pos[2])])

function get_goal_probs(traces, weights, goal_idxs=[])
    goal_probs = Dict{Any,Float64}(g => 0.0 for g in goal_idxs)
    for (tr, w) in zip(traces, weights)
        prob = get(goal_probs, tr[:goal], 0.0)
        goal_probs[tr[:goal]] = prob + exp(w)
    end
    return goal_probs
end

function print_goal_probs(goal_probs)
    for (goal, prob) in sort(goal_probs)
        @printf("%.3f\t", prob)
    end
    print("\n")
end
