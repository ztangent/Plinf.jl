# Top level models for planning agents
export plan_agent, replan_agent

"Model of an agent pursuing several possible goals via task planning."
@gen (static) function plan_agent(n_steps::Int, planner::AbstractPlanner,
                                  domain::Domain, state::State, goals::Vector,
                                  obs_params::ObserveParams)
    # Sample a goal uniformly at random
    goal_idx = @trace(uniform_discrete(1, length(goals)), :goal)
    goal = goals[goal_idx]
    # Sample a plan and trajectory from the planner
    plan, traj = @trace(sample_plan(planner, domain, state, goal), :plan)
    # Add observation noise
    padded_traj = pad_vector(traj, n_steps)
    @trace(observe_traj(padded_traj, fill(obs_params, n_steps)), :traj)
    # Return true state trajectory
    return traj
end

"Model of an agent pursuing several possible goals via replanning."
@gen (static) function replan_agent(n_steps::Int, replanner::Replanner,
                                    domain::Domain, state::State, goals::Vector,
                                    observe_fn::GenerativeFunction)
    # Sample a goal uniformly at random
    goal_idx = @trace(uniform_discrete(1, length(goals)), :goal)
    goal = goals[goal_idx]
    # Sample a trajectory via replanning and observations
    rp_init = ReplanState(1, 0, Term[], [state], false)
    rp_states = @trace(replan_unfold(n_steps, rp_init, replanner,
                                     domain, goal, observe_fn), :traj)
    traj = [state; extract_traj(rp_states)]
    # Return true state trajectory
    return traj
end
