export GoalSpec

"Goal specification for a planning problem."
@kwdef struct GoalSpec
    goals::Vector{Term} = Term[] # Goal terms to be satisfied
    metric::Union{Term,Nothing} = nothing # Metric to be minimized
    constraints::Vector{Term} = Term[] # Trajectory constraints
    obs_acts::Vector{Term} = Term[] # Action observations to (approx.) match
    obs_states::Vector{State} = State[] # State observations to (approx.) match
    GoalSpec(goals, metric, constaints, obs_acts, obs_states) =
        new(flatten_conjs(goals), metric, constaints, obs_acts, obs_states)
end

GoalSpec(goals::Vector{<:Term}) = GoalSpec(goals=goals)
GoalSpec(goal::Term) = GoalSpec(goals=flatten_conjs(goal))

function GoalSpec(problem::Problem)
    goals = flatten_conjs(problem.goal)
    sign, metric = problem.metric
    if sign > 0 metric = Compound(:-, [metric]) end
    return GoalSpec(goals=goals, metric=metric)
end
