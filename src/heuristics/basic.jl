## Basic heuristics ##
export GoalCountHeuristic, ManhattanHeuristic

"Heuristic that counts the number of goals unsatisfied in the domain."
struct GoalCountHeuristic <: Heuristic end

Base.hash(::GoalCountHeuristic, h::UInt) = hash(GoalCountHeuristic, h)

function compute(heuristic::GoalCountHeuristic,
                 domain::Domain, state::State, goal_spec::GoalSpec)
    return sum([!state[domain, g] for g in goal_spec.goals])
end

"Computes Manhattan distance to the goal for the specified numeric fluents."
struct ManhattanHeuristic <: Heuristic
    fluents::Vector{Term}
    goal_state::State
    ManhattanHeuristic(fluents) = new(fluents)
    ManhattanHeuristic(fluents, goal_state) = new(fluents, goal_state)
end

Base.hash(heuristic::ManhattanHeuristic, h::UInt) =
    hash(heuristic.fluents, hash(ManhattanHeuristic, h))

function precompute(heuristic::ManhattanHeuristic,
                    domain::Domain, state::State, goal_spec::GoalSpec)
    goal_state = State(goal_spec.goals)
    return @set heuristic.goal_state = goal_state
end

function compute(heuristic::ManhattanHeuristic,
                 domain::Domain, state::State, goal_spec::GoalSpec)
    @unpack fluents, goal_state = heuristic
    goal_vals = [goal_state[domain, f] for f in fluents]
    curr_vals = [state[domain, f] for f in fluents]
    dist = sum(abs.(goal_vals - curr_vals))
    return dist
end
