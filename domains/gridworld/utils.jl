using DataStructures: OrderedDict

pos_to_terms(pos) = @julog([xpos == $(pos[1]), ypos == $(pos[2])])
goal_to_pos(term) = (s = State(term.args); (s[:xpos], s[:ypos]))

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
