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
@gen function model(timesteps::Int, goals, state::State, domain::Domain,
                    args::Dict=Dict())
    args = merge(model_args, args)
    planner, plan_args = args[:planner], args[:plan_args]
    observe, obs_args = args[:observe], args[:obs_args]
    # Sample a goal uniformly at random
    goal = goals[@trace(uniform_discrete(1, length(goals)), :goal)]
    # Sample a plan and trajectory from the planner
    plan, traj = @trace(planner(goal, state, domain, plan_args...))
    # Pad / truncate to number of timesteps
    if length(traj) < timesteps
        obs_traj = [traj; fill(traj[end], timesteps - length(traj))]
    else
        obs_traj = traj[1:timesteps]
    end
    # Add observation noise
    obs_args = [fill(a, timesteps) for a in obs_args]
    obs_traj = @trace(observe(obs_traj, obs_args...), :traj)
    # Return true + observed state trajectory
    return traj, Vector{State}(obs_traj)
end

function particle_filter(model, model_args, traj::Vector{State}, n_particles::Int)
    # Initialize particle filter with initial observations
    init_obs = state_choices(traj[1], @julog([xpos, ypos]), (:traj => 1))
    pf_state = initialize_particle_filter(model, (1, model_args...),
                                          init_obs, n_particles)
    # Feed new observations at each timestep
    for t=2:length(traj)
        maybe_resample!(pf_state, ess_threshold=n_particles/2)
        obs = state_choices(traj[t], @julog([xpos, ypos]), (:traj => t))
        particle_filter_step!(pf_state, (t, model_args...),
            Tuple(fill(UnknownChange(), length(model_args)+1)), obs)
    end
    # Return particles and their weights
    weights = get_log_weights(pf_state)
    weights = weights .- logsumexp(weights)
    return get_traces(pf_state), weights
end
