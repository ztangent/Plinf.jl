using DataStructures: OrderedDict
using Gen: ParticleFilterState

pos_to_terms(pos) = @julog([xpos == $(pos[1]), ypos == $(pos[2])])
goal_to_pos(term) = (term.args[1].args[2].name, term.args[2].args[2].name)

function get_goal_probs(traces, weights, goal_idxs=[])
    goal_probs = OrderedDict{Any,Float64}(g => 0.0 for g in goal_idxs)
    for (tr, w) in zip(traces, weights)
        goal_idx = tr[:init => :agent => :goal => :goal]
        prob = get(goal_probs, goal_idx, 0.0)
        goal_probs[goal_idx] = prob + exp(w)
    end
    return goal_probs
end

function get_goal_probs(pf_state::ParticleFilterState, goal_idxs=[])
    goal_probs = proportionmap(pf_state, :init => :agent => :goal => :goal)
    goal_probs = OrderedDict(goal_probs)
    for idx in goal_idxs
        goal_probs[idx] = 0.0
    end
    return goal_probs
end

function print_goal_probs(goal_probs)
    for (goal, prob) in sort(goal_probs)
        @printf("%.3f\t", prob)
    end
    print("\n")
end
