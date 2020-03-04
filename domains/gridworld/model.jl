"Observation noise for x-y position in a gridworld."
@gen function observe_pos(state::State, fact_noise=0.05, fluent_noise=0.25)
    return @trace(observe(state, Term[], @julog[xpos, ypos],
                  fact_noise, fluent_noise))
end

"Observation noise for x-y trajectory."
observe_traj = Map(observe_pos)

"Observation choice map for x-y position in a gridworld."
function pos_choicemap(state::State)
    return obs_choicemap(state, Term[], @julog[xpos, ypos])
end

"Default model arguments."
model_args = Dict(:planner => sample_search, :plan_args => (),
                  :observe => observe_traj, :obs_args => ())

"Model of an agent pursuing several possible goals in a gridworld."
@gen function model(goals, state::State, domain::Domain, args::Dict=Dict())
    args = merge(model_args, args)
    planner, plan_args = args[:planner], args[:plan_args]
    observe, obs_args = args[:observe], args[:obs_args]
    # Sample a goal uniformly at random
    goal = goals[@trace(uniform_discrete(1, length(goals)), :goal)]
    # Sample a plan and trajectory from the planner
    plan, traj = @trace(planner(goal, state, domain, plan_args...))
    # Add observation noise
    obs_args = [fill(a, length(traj)) for a in obs_args]
    obs_traj = @trace(observe(traj, obs_args...), :traj)
    # Return observed state trajectory
    return Vector{State}(obs_traj)
end
