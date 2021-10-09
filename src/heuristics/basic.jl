## Basic heuristics ##
export GoalCountHeuristic, ManhattanHeuristic

"Heuristic that counts the number of goals un/satisfied."
struct GoalCountHeuristic <: Heuristic
    dir::Symbol # :forward or :backward
    GoalCountHeuristic() = new(:forward)
    GoalCountHeuristic(dir) = new(dir)
end

Base.hash(::GoalCountHeuristic, h::UInt) = hash(GoalCountHeuristic, h)

function compute(heuristic::GoalCountHeuristic,
                 domain::Domain, state::State, spec::Specification)
    goals = get_goal_terms(spec)
    count = sum(!satisfy(domain, state, g) for g in goals)
    return heuristic.dir == :backward ? length(goals) - count : count
end

"Computes Manhattan distance to the goal for the specified numeric fluents."
struct ManhattanHeuristic <: Heuristic
    fluents::Vector{Term}
    goal_state::Union{State,Nothing}
    ManhattanHeuristic(fluents) = new(fluents, nothing)
    ManhattanHeuristic(fluents, goal_state) = new(fluents, goal_state)
end

Base.hash(heuristic::ManhattanHeuristic, h::UInt) =
    hash(heuristic.fluents, hash(ManhattanHeuristic, h))

function precompute(heuristic::ManhattanHeuristic,
                    domain::Domain, state::State, spec::Specification)
    goal_state = goalstate(domain, PDDL.get_objtypes(state), get_goal_terms(spec))
    fnames = collect(PDDL.get_fluent_names(goal_state))
    if !issubset(heuristic.fluents, fnames)
        error("Fluents $(join(heuristic.fluents, ", ")) not in goal.")
    end
    return @set heuristic.goal_state = goal_state
end

function precompute(heuristic::ManhattanHeuristic,
                    domain::CompiledDomain, state::State, spec::Specification)
    goal_state = goalstate(PDDL.get_source(domain), PDDL.get_objtypes(state),
                           get_goal_terms(spec))
    fnames = collect(PDDL.get_fluent_names(goal_state))
    if !issubset(heuristic.fluents, fnames)
        error("Fluents $(join(heuristic.fluents, ", ")) not in goal.")
    end
    return @set heuristic.goal_state = typeof(state)(goal_state)
end

function compute(heuristic::ManhattanHeuristic,
                 domain::Domain, state::State, spec::Specification)
    # Precompute if necessary
    if heuristic.goal_state === nothing
        heuristic = precompute(heuristic, domain, state, spec) end
    @unpack fluents, goal_state = heuristic
    goal_vals = [domain[goal_state => f] for f in fluents]
    curr_vals = [domain[state => f] for f in fluents]
    dist = sum(abs.(goal_vals - curr_vals))
    return dist
end
