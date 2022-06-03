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

"Planner parameters for inference."
SEARCH_NOISE = 0.1
PERSISTENCE = (2, 0.95)

"Action noise parameter."
ACT_NOISE = 0.00 # 0.05

"Planner heuristics for each domain."
HEURISTICS = Dict{String,Any}()
HEURISTICS["block-words"] = HAdd
HEURISTICS["doors-keys-gems"] = GemMazeDist

"Observation parameters for each domain."
OBS_PARAMS = Dict{String,Any}()
OBS_PARAMS["doors-keys-gems"] = observe_params(
    (pddl"(xpos)", normal, 1.0), (pddl"(ypos)", normal, 1.0),
    (pddl"(forall (?d - door) (locked ?d))", 0.05),
    (pddl"(forall (?i - item) (has ?i))", 0.05)
)
