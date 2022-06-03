export PlannerHeuristic

"Computes distance to the goal based on planner solution."
@kwdef struct PlannerHeuristic{P <: Planner, DT, ST} <: Heuristic
    planner::P
    d_transform::DT = identity # Optional domain transform
    s_transform::ST = identity # Optional state transform
end

function PlannerHeuristic(
    planner::Planner;
    domain = nothing,
    state = nothing,
    d_transform = isnothing(domain) ? identity : _ -> domain,
    s_transform = isnothing(state) ? identity : _ -> state
)
    return PlannerHeuristic(;planner=planner, d_transform=d_transform,
                            s_transform=s_transform)
end

function Base.hash(heuristic::PlannerHeuristic{P}, h::UInt) where {P}
    h = hash(P, hash(PlannerHeuristic, h))
    for f in fieldnames(P)
        h = hash(getfield(heuristic.planner, f), h)
    end
    h = hash(heuristic.s_transform, hash(heuristic.d_transform, h))
    return h
end

function compute(h::PlannerHeuristic,
                 domain::Domain, state::State, spec::Specification)
    domain = h.d_transform(domain)
    state = h.s_transform(state)
    plan, traj = h.planner(domain, state, spec)
    if plan === nothing
        return Inf
    else
        plan_cost = 0.0
        for (i, act) in enumerate(plan)
            plan_cost += get_cost(spec, domain, traj[i], act, traj[i+1])
        end
        return plan_cost
    end
end
