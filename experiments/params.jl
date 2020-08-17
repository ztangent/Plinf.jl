"Custom relaxed distance heuristic to goal objects."
struct GemHeuristic <: Heuristic end

function Plinf.compute(heuristic::GemHeuristic,
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
    relaxed_plan = maze_planner(domain, relaxed_state, goal_spec)[1]
    return length(relaxed_plan)
end

"Custom relaxed distance heuristic for the taxi domain."
struct TaxiHeuristic <: Heuristic end

function Plinf.compute(heuristic::TaxiHeuristic,
                       domain::Domain, state::State, goal_spec::GoalSpec)
    # Extract (sub)goal location
    goal = goal_spec.goals[1]
    dist = 0
    cur_loc_x, cur_loc_y = state[:xpos], state[:ypos]
    if !state[pddl"(passenger-at intaxi)"]
        goal_locname = find_matches(pddl"(passenger-at ?loc)", state)[1].args[1]
        loc_term = Compound(Symbol("pasloc-at-loc"), [goal_locname, @julog(L)])
        goal_loc = find_matches(loc_term, state)[1].args[2].name
        goal_loc_idx = parse(Int, string(goal_loc)[4:end])
        # Compute Manhattan distance to passenger location
        goal_loc_x, goal_loc_y = goal_loc_idx % 5, goal_loc_idx ÷ 5
        dist += abs(cur_loc_x - goal_loc_x) + abs(cur_loc_y - goal_loc_y)
        cur_loc_x, cur_loc_y = goal_loc_x, goal_loc_y
    end
    goal_locname = goal.args[1]
    loc_term = Compound(Symbol("pasloc-at-loc"), [goal_locname, @julog(L)])
    goal_loc = find_matches(loc_term, state)[1].args[2].name
    goal_loc_idx = parse(Int, string(goal_loc)[4:end])
    # Compute Manhattan distance to goal location
    goal_loc_x, goal_loc_y = goal_loc_idx % 5, goal_loc_idx ÷ 5
    dist += abs(cur_loc_x - goal_loc_x) + abs(cur_loc_y - goal_loc_y)
    return dist
end

"Planner parameters for inference."
SEARCH_NOISE = 0.1
PERSISTENCE = (2, 0.95)

"Planner heuristics for each domain."
HEURISTICS = Dict{String,Any}()
HEURISTICS["doors-keys-gems"] = GemMazeDist
HEURISTICS["taxi"] = TaxiHeuristic

"Observation parameters for each domain."
OBS_PARAMS = Dict{String,Any}()
OBS_PARAMS["doors-keys-gems"] = observe_params(
    (@julog(xpos), normal, 0.25), (@julog(ypos), normal, 0.25),
    (@julog(forall(doorloc(X, Y), door(X, Y))), 0.05),
    (@julog(forall(item(Obj),has(Obj))), 0.05),
    (@julog(forall(and(item(Obj), itemloc(X, Y)), at(Obj, X, Y))), 0.05)
)
OBS_PARAMS["taxi"] = observe_params(
    (pddl"(xpos)", normal, 0.25), (pddl"(ypos)", normal, 0.25),
    (pddl"(forall (?l - pasloc) (passenger-at ?l))", 0.05)
)
