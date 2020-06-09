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

"Planner heuristics for each domain."
HEURISTICS = Dict{String,Any}()
HEURISTICS["doors-keys-gems"] = GemHeuristic

"Observation parameters for each domain."
OBS_PARAMS = Dict{String,Any}()
OBS_PARAMS["doors-keys-gems"] = observe_params(
    (@julog(xpos), normal, 0.25), (@julog(ypos), normal, 0.25),
    (@julog(forall(doorloc(X, Y), door(X, Y))), 0.05),
    (@julog(forall(item(Obj),has(Obj))), 0.05),
    (@julog(forall(and(item(Obj), itemloc(X, Y)), at(Obj, X, Y))), 0.05)
)
