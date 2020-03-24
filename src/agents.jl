# Top level models for planning agents

"Model of an agent pursuing several possible goals via task planning."
@gen (static) function plan_agent(
    timesteps::Int, goals::Vector{Vector{<:Term}}, state::State, domain::Domain,
    planner, plan_args, obs_facts, obs_fluents)
    # Sample a goal uniformly at random
    goal_idx = @trace(uniform_discrete(1, length(goals)), :goal)
    goal = goals[goal_idx]
    # Sample a plan and trajectory from the planner
    ret = @trace(sample_plan(planner, goal, state, domain, plan_args), :plan)
    traj = ret[2]
    # Add observation noise
    padded_traj = pad_vector(traj, timesteps)
    obs_traj = @trace(observe_traj(padded_traj,
        fill(obs_facts, timesteps), fill(obs_fluents, timesteps)), :traj)
    # Return true state trajectory
    return traj
end

"Model of an agent pursuing several possible goals via replanning."
@gen (static) function replan_agent(
    timesteps::Int, goals::Vector{Vector{<:Term}}, state::State, domain::Domain,
    search_noise::Float64, persistence::Float64, heuristic::Function,
    observe::GenerativeFunction)
    # Sample a goal uniformly at random
    goal_idx = @trace(uniform_discrete(1, length(goals)), :goal)
    goal = goals[goal_idx]
    # Sample a trajectory via replanning and observations
    rp_init = ReplanState(1, 0, Term[], [state])
    rp_states = @trace(replan_step_unfold(timesteps, rp_init, goal, domain,
                                          search_noise, persistence,
                                          heuristic, observe), :traj)
    traj = [state; extract_traj(rp_states)]
    # Return true state trajectory
    return traj
end
