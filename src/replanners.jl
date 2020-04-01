export Replanner
using Parameters: @with_kw

"Wraps any planner in a replanning algorithm."
@kwdef struct Replanner <: AbstractPlanner
    planner::AbstractPlanner
    persistence::Float64 = 0.95
    max_plans::Real = 100
end

set_max_resource(planner::Replanner, val) = @set planner.max_plans = val

get_call(::Replanner)::GenerativeFunction = replan_call

"Unfold combinator state for a replanning step."
struct ReplanState
    rel_step::Int
    traj_length::Int
    part_plan::Vector{Term}
    part_traj::Vector{State}
    plan_done::Bool
end

"Extract plan from a collection of ReplanStates."
function extract_plan(rp_states)
    plan = Term[rp.part_plan[rp.rel_step] for rp in rp_states if
                length(rp.part_plan) > 0]
    if length(rp_states[end].part_plan) > rp_states[end].rel_step
        tail = rp_states[end].part_plan[rp_states[end].rel_step+1:end]
        append!(plan, tail)
    end
    return plan
end

"Extract trajectory from a collection of ReplanStates."
function extract_traj(rp_states)
    traj = State[rp.part_traj[rp.rel_step] for rp in rp_states if
                length(rp.part_plan) > 0]
    if length(rp_states[end].part_traj) > rp_states[end].rel_step
        tail = rp_states[end].part_traj[rp_states[end].rel_step+1:end]
        append!(traj, tail)
    end
    return traj
end

"Checks whether a plan already reaches a timestep t, and extends it if not."
@gen function replan_step(t::Int, rp::ReplanState, replanner::Replanner,
                          domain::Domain, goal_spec, observe_fn=nothing)
    @unpack planner, persistence = replanner
    plan_done = false
    # Get most recent world state
    state = rp.part_traj[rp.rel_step]
    # If plan has already reached this time step, do nothing
    if t <= rp.traj_length
        if observe_fn != nothing @trace(observe_fn(state)) end
        rel_step = t < rp.traj_length ? rp.rel_step + 1 : rp.rel_step
        return ReplanState(rel_step, rp.traj_length,
                           rp.part_plan, rp.part_traj, plan_done)
    end
    # Sample a resource bound for the planner
    max_resource = @trace(geometric(1-persistence), :max_resource)
    planner = set_max_resource(planner, max_resource)
    # Plan to achieve the goals until the maximum node budget
    part_plan, part_traj =
        @trace(sample_plan(planner, domain, state, goal_spec), :plan)
    if part_plan == nothing || length(part_plan) == 0
        # Return no-op if goal is reached or no satisfying plan can be found
        part_plan, part_traj = Term[Compound(Symbol("--"), [])], State[state]
        plan_done = true
    else
        # Don't double count initial state
        part_traj = part_traj[2:end]
    end
    if observe_fn != nothing @trace(observe_fn(part_traj[1])) end
    traj_length = rp.traj_length + length(part_plan)
    return ReplanState(1, traj_length, part_plan, part_traj, plan_done)
end

replan_unfold = Unfold(replan_step)

"Plan to achieve a goal by repeated planning calls"
@gen function replan_call(replanner::Replanner,
                          domain::Domain, state::State, goal_spec)
    # TODO : Handle states differing from planned trajectory
    # This will occur in stochastic domains
    # Intialize state for replan step
    rp_states = [ReplanState(1, 1, Term[], [state], false)]
    plan_count, success = 0, false
    while true
        # Take a replanning step
        t = length(rp_states)
        rp = @trace(replan_step(t, rp_states[end], replanner,
                                domain, goal_spec), t)
        push!(rp_states, rp)
        plan_count += rp.rel_step == 1 ? 1 : 0
        # Break if plan is done, or plan count exceeds max plans
        if rp.plan_done || plan_count >= replanner.max_plans
            break
        end
    end
    plan = extract_plan(rp_states)
    traj = [state; extract_traj(rp_states)]
    if plan[end].name == Symbol("--")
        plan, traj = plan[1:end-1], traj[1:end-1]
    end
    return plan, traj
end
