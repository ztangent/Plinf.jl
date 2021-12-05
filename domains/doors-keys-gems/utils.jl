using DataStructures: OrderedDict

pos_to_terms(pos) = @julog([xpos == $(pos[1]), ypos == $(pos[2])])

"Manhattan distance heuristic to location of goal gem."
struct GemManhattan <: Heuristic end

function Plinf.compute(heuristic::GemManhattan,
                       domain::Domain, state::State, spec::Specification)
    goals = Plinf.get_goal_terms(spec)
    goal_objs = [g.args[1] for g in goals if g.name == :has]
    at_terms = find_matches(domain, state, @julog(at(O, X, Y)))
    locs = [[t.args[2].name, t.args[3].name]
            for t in at_terms if t.args[1] in goal_objs]
    pos = [state[pddl"xpos"], state[pddl"ypos"]]
    dists = [sum(abs.(pos - l)) for l in locs]
    min_dist = length(dists) > 0 ? minimum(dists) : 0
    return min_dist + GoalCountHeuristic()(domain, state, spec)
end

"Maze distance heuristic to location of goal gem."
struct GemMazeDist <: Heuristic end

maze_planner = AStarPlanner(heuristic=GemManhattan())

function Plinf.compute(heuristic::GemMazeDist,
                       domain::Domain, state::State, spec::Specification)
    relaxed_state = copy(state)
    for t in find_matches(domain, state, @julog(door(X, Y)))
        relaxed_state[t] = false
    end
    relaxed_plan = maze_planner(domain, relaxed_state, spec)[1]
    return length(relaxed_plan)
end

function get_goal_probs(traces, weights, goal_idxs=[])
    goal_probs = OrderedDict{Any,Float64}(g => 0.0 for g in goal_idxs)
    for (tr, w) in zip(traces, weights)
        goal_idx = tr[:init => :agent => :goal => :goal]
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
