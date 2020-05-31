export Replanner

## Plan states for replanning agents ##

"State for a replanning step."
struct ReplanState <: AbstractPlanState
    rel_step::Int
    part_plan::Vector{Term}
    part_traj::Vector{State}
    plan_done::Bool
end

function extract_plan(rp_states::AbstractArray{ReplanState})
    plan = Term[rp.part_plan[rp.rel_step] for rp in rp_states if
                length(rp.part_plan) > 0 && !rp.plan_done]
    rp_end = rp_states[end]
    if length(rp_end.part_plan) > rp_end.rel_step
        tail = rp_end.part_plan[rp_end.rel_step+1:end]
        append!(plan, tail)
    end
    return plan
end

function extract_traj(rp_states::AbstractArray{ReplanState})
    traj = State[rp.part_traj[rp.rel_step] for rp in rp_states if
                 length(rp.part_plan) > 0]
    rp_end = rp_states[end]
    if length(rp_end.part_traj) > rp_end.rel_step && !rp_end.plan_done
        tail = rp_end.part_traj[rp_end.rel_step+1:end]
        append!(traj, tail)
    end
    return traj
end

"Find all timesteps where replanning occurred."
function get_planning_steps(rp_states::AbstractArray{ReplanState})
    unzip([(t, rp) for (t, rp) in enumerate(rp_states) if rp.rel_step == 1])
end

"Find the most recent timestep at which replanning occured."
function get_last_planning_step(rp_states::AbstractArray{ReplanState})
    for (t, rp) in enumerate(reverse(rp_states))
        if (rp.rel_step == 1 && !rp.plan_done)
            return (length(rp_states) - t + 1, rp) end
    end
end

## Implements resource-bounded replanning search, given a base planner ##

"Wraps any planner in a replanning algorithm."
@kwdef struct Replanner <: Planner
    planner::Planner
    persistence::Tuple{Real,Real} = (2, 0.95)
    max_plans::Real = 100
end

set_max_resource(planner::Replanner, val) = @set planner.max_plans = val

get_call(::Replanner)::GenerativeFunction = replan_call

get_step(::Replanner)::GenerativeFunction = replan_step

get_step_proposal(::Replanner)::GenerativeFunction = replan_propose_step

initialize_state(::Replanner, env_state::State)::AbstractPlanState =
    ReplanState(0, Term[], [env_state], false)

get_action(rp::ReplanState)::Term =
    rp.rel_step == 0 ? Const(PDDL.no_op.name) : rp.part_plan[rp.rel_step]

"Checks whether a plan already reaches a timestep t, and extends it if not."
@gen function replan_step(t::Int, rp::ReplanState, replanner::Replanner,
                          domain::Domain, state::State, goal_spec::GoalSpec)
    @unpack planner, persistence = replanner
    plan_done = rp.plan_done
    rel_step = rp.rel_step + 1 # Compute relative step for current timestep
    state = rp.part_traj[rel_step] # Get expected current state
    if plan_done || satisfy(goal_spec.goals, state, domain)[1]
        # Return no-op if plan is done
        part_plan, part_traj = Term[Const(PDDL.no_op.name)], [state, state]
        return ReplanState(1, part_plan, part_traj, true)
    elseif rel_step < length(rp.part_traj)
        # Step forward if the end of the planned trajectory is not reached
        return ReplanState(rel_step, rp.part_plan, rp.part_traj, plan_done)
    end
    # Otherwise, make a new partial plan from the current state
    n_attempts, p_continue = persistence  # Sample a planner resource bound
    max_resource = @trace(neg_binom(n_attempts, 1-p_continue), :max_resource)
    planner = set_max_resource(planner, max_resource)
    # Plan to achieve the goals until the maximum node budget
    part_plan, part_traj =
        @trace(sample_plan(planner, domain, state, goal_spec), :subplan)
    if part_plan == nothing || length(part_plan) == 0
        # Return no-op if goal cannot be reached, or plan is of zero-length
        plan_done |= (part_plan == nothing) # Terminate if goal is unreachable
        part_plan, part_traj = Term[Const(PDDL.no_op.name)], [state, state]
    end
    return ReplanState(1, part_plan, part_traj, plan_done)
end

"Propose a likely replanning step, given the observed trajectory from `t`."
@gen function replan_propose_step(t::Int, rp::ReplanState,
                                  replanner::Replanner, domain::Domain,
                                  state::State, goal_spec::GoalSpec,
                                  obs_states::Vector{<:Union{State,Nothing}},
                                  proposal_args::Union{Tuple,Nothing})
    @unpack planner, persistence = replanner
    max_resource = proposal_args == nothing ? nothing : proposal_args[1]
    plan_done = rp.plan_done
    rel_step = rp.rel_step + 1 # Compute relative step for current timestep
    state = rp.part_traj[rel_step] # Get expected current state
    if plan_done || satisfy(goal_spec.goals, state, domain)[1]
        # Return no-op if plan is done
        part_plan, part_traj = Term[Const(PDDL.no_op.name)], [state, state]
        return ReplanState(1, part_plan, part_traj, true)
    elseif rel_step < length(rp.part_traj)
        # Step forward if the end of the planned trajectory is not reached
        return ReplanState(rel_step, rp.part_plan, rp.part_traj, plan_done)
    end
    # Otherwise, make a new partial plan from the current state
    if max_resource == nothing
        n_attempts, p_cont = persistence  # Sample a planner resource bound
        max_resource = @trace(neg_binom(n_attempts, 1-p_cont), :max_resource)
    else
        @trace(uniform_discrete(max_resource, max_resource), :max_resource)
    end
    planner = set_max_resource(planner, max_resource)
    # Plan to achieve the goals until the maximum node budget
    part_plan, part_traj = @trace(propose_plan(planner, domain, state,
                                               goal_spec, obs_states), :subplan)
    if part_plan == nothing || length(part_plan) == 0
        # Return no-op if goal cannot be reached, or plan is of zero-length
        plan_done |= (part_plan == nothing) # Terminate if goal is unreachable
        part_plan, part_traj = Term[Const(PDDL.no_op.name)], [state, state]
    end
    return ReplanState(1, part_plan, part_traj, plan_done)
end

"Plan to achieve a goal by repeated planning calls"
@gen function replan_call(replanner::Replanner,
                          domain::Domain, state::State, goal_spec::GoalSpec)
    # Intialize state for replan step
    rp_states = [ReplanState(0, Term[], [state], false)]
    plan_count, success = 0, false
    while true
        # Take a replanning step
        t = length(rp_states)
        rp = @trace(replan_step(t, rp_states[end], replanner,
                                domain, state, goal_spec),
                    :timestep => t => :plan)
        push!(rp_states, rp)
        # Compute next state (assuming environment determinism)
        state = rp.part_traj[min(rp.rel_step + 1, length(rp.part_traj))]
        plan_count += rp.rel_step == 1 ? 1 : 0
        # Break if plan is done, or plan count exceeds max plans
        if rp.plan_done || plan_count >= replanner.max_plans
            break
        end
    end
    plan = extract_plan(rp_states)
    traj = extract_traj(rp_states)
    return plan, traj
end
