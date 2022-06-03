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

# "Custom relaxed distance heuristic for the taxi domain."
# struct TaxiHeuristic <: Heuristic end
#
# function Plinf.compute(heuristic::TaxiHeuristic,
#                        domain::Domain, state::State, goal_spec::GoalSpec)
#     # Extract (sub)goal location
#     goal = goal_spec.goals[1]
#     dist = 0
#     cur_loc_x, cur_loc_y = state[:xpos], state[:ypos]
#     if !state[pddl"(passenger-at intaxi)"]
#         goal_locname = find_matches(pddl"(passenger-at ?loc)", state)[1].args[1]
#         loc_term = Compound(Symbol("pasloc-at-loc"), [goal_locname, @julog(L)])
#         goal_loc = find_matches(loc_term, state)[1].args[2].name
#         goal_loc_idx = parse(Int, string(goal_loc)[4:end])
#         # Compute Manhattan distance to passenger location
#         goal_loc_x, goal_loc_y = goal_loc_idx % 5, goal_loc_idx ÷ 5
#         dist += abs(cur_loc_x - goal_loc_x) + abs(cur_loc_y - goal_loc_y)
#         cur_loc_x, cur_loc_y = goal_loc_x, goal_loc_y
#     end
#     goal_locname = goal.args[1]
#     loc_term = Compound(Symbol("pasloc-at-loc"), [goal_locname, @julog(L)])
#     goal_loc = find_matches(loc_term, state)[1].args[2].name
#     goal_loc_idx = parse(Int, string(goal_loc)[4:end])
#     # Compute Manhattan distance to goal location
#     goal_loc_x, goal_loc_y = goal_loc_idx % 5, goal_loc_idx ÷ 5
#     dist += abs(cur_loc_x - goal_loc_x) + abs(cur_loc_y - goal_loc_y)
#     return dist
# end

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
