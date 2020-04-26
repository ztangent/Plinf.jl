export GoalSpec

"Goal specification for a planning problem."
@kwdef struct GoalSpec
    goals::Vector{Term} = Term[] # Goal terms to be satisfied
    metric::Union{Term,Nothing} = nothing # Metric to be minimized
    constraints::Vector{Term} = Term[] # Trajectory constraints
    GoalSpec(goals, metric, constraints) =
        new(flatten_conjs(goals), metric, Vector{Term}(constraints))
end

GoalSpec(goals::Vector{<:Term}) = GoalSpec(goals=goals)
GoalSpec(goal::Term) = GoalSpec(goals=flatten_conjs(goal))

function GoalSpec(problem::Problem)
    goals = flatten_conjs(problem.goal)
    sign, metric = problem.metric
    if sign > 0 metric = Compound(:-, [metric]) end
    return GoalSpec(goals=goals, metric=metric)
end
