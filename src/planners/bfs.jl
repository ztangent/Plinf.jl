export BFSPlanner

"Uninformed breadth-first search planner."
@kwdef struct BFSPlanner <: Planner
    max_depth::Number = Inf
end

set_max_resource(planner::BFSPlanner, val) = @set planner.max_depth = val

get_call(::BFSPlanner)::GenerativeFunction = bfs_call

"Uninformed breadth-first search for a plan."
@gen function bfs_call(planner::BFSPlanner,
                       domain::Domain, state::State, goal_spec::GoalSpec)
    @unpack goals = goal_spec
    plan, traj = Term[], State[state]
    queue = [(plan, traj)]
    while length(queue) > 0
        plan, traj = popfirst!(queue)
        # Only search up to max_depth
        step = length(plan) + 1
        if step > planner.max_depth continue end
        # Get list of available actions
        state = traj[end]
        actions = available(state, domain)
        # Iterate over actions
        for act in actions
            # Execute actions on state
            next_state = transition(domain, state, act; check=false)
            # Add action term to plan sequence
            next_plan = Term[plan; act]
            next_traj = State[traj; next_state]
            # Return plan if goals are satisfied
            sat, _ = satisfy(goals, next_state, domain)
            if sat return (next_plan, next_traj) end
            # Otherwise push to queue
            push!(queue, (next_plan, next_traj))
        end
    end
    return nothing, nothing
end
