pos_to_terms(pos) = @julog([xpos == $(pos[1]), ypos == $(pos[2])])

"Custom heuristic: manhattan distance to goal."
function gem_heuristic(goals, state::State, domain::Domain)
    goal_objs = [g.args[1] for g in goals if g.name == :has]
    queries = [@julog(at(:obj, X, Y)) for obj in goal_objs]
    _, subst = satisfy(Compound(:or, queries), state, domain, mode=:all)
    locs = [[s[@julog(X)].name, s[@julog(Y)].name] for s in subst]
    pos = [state[:xpos], state[:ypos]]
    dists = [sum(abs.(pos - l)) for l in locs]
    min_dist = length(dists) > 0 ? minimum(dists) : 0
    return min_dist + goal_count(goals, state, domain)
end

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
