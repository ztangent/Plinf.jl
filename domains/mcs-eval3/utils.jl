using DataStructures: OrderedDict
using Distributions: Normal, cdf

pos_to_terms(pos) = @julog([xpos == $(pos[1]), ypos == $(pos[2])])

"Manhattan distance heuristic to location of goal."
struct GoalManhattan <: Heuristic end

function Plinf.compute(heuristic::GoalManhattan,
                       domain::Domain, state::State, goal_spec::GoalSpec)
    goal = goal_spec.goals[1]
    cur_loc = [state[:xpos], state[:ypos]]
    dist = 0
    # Compute subgoal location based on task
    if goal.name == :reach # Reach a certain location
        goal_loc = [goal.args[1].name, goal.args[2].name]
    elseif goal.name == :retrieve # Retrieve a certain object
        obj = goal.args[1]
        goal_loc = [state[@julog(xitem(:obj))], state[@julog(yitem(:obj))]]
    elseif goal.name == :transfer # Transfer a certain object
        obj = goal.args[1]
        if !state[@julog(has(:obj))]
            goal_loc = [state[@julog(xitem(:obj))], state[@julog(yitem(:obj))]]
            dist += sum(abs.(cur_loc - goal_loc))
            cur_loc = goal_loc
        end
        goal_loc = [goal.args[2].name, goal.args[3].name]
    else # Default to goal count heuristic
        return GoalCountHeuristic()(domain, state, goal_spec)
    end
    dist += sum(abs.(cur_loc - goal_loc))
    return dist
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

function kl_divergence(probs_1, probs_2)
    return sum(p1 * (log(p1) - log(p2)) for (p1, p2) in zip(probs_1, probs_2))
end

function total_variation(probs_1, probs_2)
    return 0.5 * sum(abs(p1-p2) for (p1, p2) in zip(probs_1, probs_2))
end

function threshold_confidence(val, threshold, std)
    z_score = (val - threshold) / std
    return cdf(Normal(), abs(z_score))
end
