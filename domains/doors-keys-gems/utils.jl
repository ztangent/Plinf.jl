using DataStructures: OrderedDict

pos_to_terms(pos) = @julog([xpos == $(pos[1]), ypos == $(pos[2])])

function get_agent_pos(state::State; flip_y::Bool=false)
    x, y = state[pddl"(xpos)"], state[pddl"(ypos)"]
    if !flip_y
        return (x, y)
    else
        height = size(state[pddl"(walls)"])[1]
        return (x, height-y+1)
    end
end

function get_obj_loc(state::State, obj::Const; flip_y::Bool=false)
    x, y = state[Compound(:xloc, Term[obj])], state[Compound(:yloc, Term[obj])]
    if !flip_y
        return (x, y)
    else
        height = size(state[pddl"(walls)"])[1]
        return (x, height-y+1)
    end
end

"Custom relaxed distance heuristic to goal objects."
struct GemHeuristic <: Heuristic end

function Plinf.compute(heuristic::GemHeuristic,
                       domain::Domain, state::State, spec::Specification)
    goals = Plinf.get_goal_terms(spec)
    goal_objs = [g.args[1] for g in goals if g.name == :has]
    locs = [(state[Compound(:xloc, Term[o])], state[Compound(:yloc, Term[o])])
            for o in goal_objs]
    pos = (state[pddl"xpos"], state[pddl"ypos"])
    dists = [sum(abs.(pos .- l)) for l in locs]
    min_dist = length(dists) > 0 ? minimum(dists) : 0
    return min_dist + GoalCountHeuristic()(domain, state, spec)
end

"Custom relaxed distance heuristic to goal objects."
struct GemHeuristic <: Heuristic end

function Plinf.compute(heuristic::GemHeuristic,
                       domain::Domain, state::State, spec::Specification)
    goals = Plinf.get_goal_terms(spec)
    goal_objs = [g.args[1] for g in goals if g.name == :has]
    locs = [(state[Compound(:xloc, Term[o])], state[Compound(:yloc, Term[o])])
            for o in goal_objs]
    pos = (state[pddl"xpos"], state[pddl"ypos"])
    dists = [sum(abs.(pos .- l)) for l in locs]
    min_dist = length(dists) > 0 ? minimum(dists) : 0
    return min_dist + GoalCountHeuristic()(domain, state, spec)
end

"Maze distance heuristic to location of goal gem."
struct GemMazeDist <: Heuristic
    planner::Planner
end

GemMazeDist() = GemMazeDist(AStarPlanner(heuristic=GemHeuristic()))

function Plinf.compute(heuristic::GemMazeDist,
                       domain::Domain, state::State, spec::Specification)
    relaxed_state = copy(state)
    for d in PDDL.get_objects(domain, state, :door)
        relaxed_state[Compound(:locked, Term[d])] = false
    end
    relaxed_plan = heuristic.planner(domain, relaxed_state, spec)[1]
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
