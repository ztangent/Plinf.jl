pos_to_terms(pos) = @julog([xpos == $(pos[1]), ypos == $(pos[2])])

function get_goal_probs(traces, weights)
    goal_probs = Dict{Any,Float64}()
    for (tr, w) in zip(traces, weights)
        prob = get(goal_probs, tr[:goal], 0.0)
        goal_probs[tr[:goal]] = prob + exp(w)
    end
    return goal_probs
end

function print_goal_probs(goals, goal_probs)
    for g in goals
        @printf("%.3f\t", get(goal_probs, g, 0.0))
    end
    print("\n")
end
