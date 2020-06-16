using DataStructures: OrderedDict

pos_to_terms(pos) = @julog([xpos == $(pos[1]), ypos == $(pos[2])])

"Manhattan distance heuristic to location of goal gem."
struct GemManhattan <: Heuristic end

function Plinf.compute(heuristic::GemManhattan,
                       domain::Domain, state::State, goal_spec::GoalSpec)
    goals = goal_spec.goals
    goal_objs = [g.args[1] for g in goals if g.name == :has]
    at_terms = find_matches(@julog(at(O, X, Y)), state)
    locs = [[t.args[2].name, t.args[3].name]
            for t in at_terms if t.args[1] in goal_objs]
    pos = [state[:xpos], state[:ypos]]
    dists = [sum(abs.(pos - l)) for l in locs]
    min_dist = length(dists) > 0 ? minimum(dists) : 0
    return min_dist + GoalCountHeuristic()(domain, state, goal_spec)
end

"Maze distance heuristic to location of goal gem."
struct GemMazeDist <: Heuristic end

maze_planner =
    AStarPlanner(heuristic=ManhattanHeuristic(@julog([xpos, ypos])))

function Plinf.compute(heuristic::GemMazeDist,
                       domain::Domain, state::State, goal_spec::GoalSpec)
    relaxed_state = copy(state)
    for t in find_matches(@julog(door(X, Y)), state)
        relaxed_state[t] = false
    end
    relaxed_plan = relaxed_planner(domain, relaxed_state, goal_spec)[1]
    return length(relaxed_plan)
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
