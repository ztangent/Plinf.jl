export BFSPlanner

"Uninformed breadth-first search planner."
@kwdef struct BFSPlanner <: Planner
    max_depth::Number = Inf
end

set_max_resource(planner::BFSPlanner, val) = @set planner.max_depth = val

get_call(::BFSPlanner)::GenerativeFunction = bfs_call

"Uninformed breadth-first search for a plan."
@gen function bfs_call(planner::BFSPlanner,
                       domain::Domain, state::State, spec::Specification)
    plan, traj = Term[], State[state]
    queue = [(plan, traj)]
    while length(queue) > 0
        plan, traj = popfirst!(queue)
        # Only search up to max_depth
        step = length(plan) + 1
        if step > planner.max_depth continue end
        # Get list of available actions
        state = traj[end]
        actions = available(domain, state)
        # Iterate over actions
        for act in actions
            # Execute actions on state
            next_state = transition(domain, state, act; check=false)
            # Add action term to plan sequence
            next_plan = Term[plan; act]
            next_traj = State[traj; next_state]
            # Return plan if goals are satisfied
            if is_goal(spec, domain, next_state)
                return (next_plan, next_traj) end
            # Otherwise push to queue
            push!(queue, (next_plan, next_traj))
        end
    end
    return nothing, nothing
end
