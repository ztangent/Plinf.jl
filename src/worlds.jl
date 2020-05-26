export WorldState, WorldInit, WorldConfig, world_step, world_model

"Represents the state of the world (agent + environment) at some time `t`."
struct WorldState
    goal_state # Goal state at time t
    plan_state # Plan state at time t
    env_state # Environment state at  time t
    obs_state # Observation state at time t
end

"Intiializers for various states in a world model."
struct WorldInit
    goal_init
    plan_init
    env_init
    obs_init
end

WorldInit(planner::Planner, goal_init, env_state::State) =
    WorldInit(goal_init, initialize_state(planner, env_state),
              env_state, env_state)

WorldInit(planner::Planner, goal_init, env_state::State, obs_init) =
    WorldInit(goal_init, initialize_state(planner, env_state),
              env_state, obs_init)

@kwdef struct WorldConfig
  domain::Domain
  planner::Planner
  plan_args::Tuple = ()
  goal_step::GenerativeFunction = static_goal_step
  goal_args::Tuple = ()
  env_step::GenerativeFunction = determ_env_step
  env_args::Tuple = ()
  obs_step::GenerativeFunction = markov_obs_step
  obs_args::Tuple = ()
end

function WorldConfig(domain::Domain, planner::Planner,
                     obs_params::ObserveParams; kwargs...)
    WorldConfig(domain=domain, planner=planner, env_step=determ_env_step,
                obs_args=(obs_params,), kwargs...)
end

"Goal transition function for static goals."
@gen static_goal_step(t, goal_state) =
    goal_state

"Environment transition function for deterministic dynamics."
@gen determ_env_step(t, env_state::State, action::Term, domain::Domain) =
    transition(domain, env_state, action; fail_mode=:no_op)

"Observation which depends on only the current environment state."
@gen markov_obs_step(t, obs_state, env_state::State, domain::Domain, params) =
    @trace(observe_state(env_state, domain, params))

"Accessor for goal states."
get_goal(goal_state)::GoalSpec = error("Not implemented.")
get_goal(goal_state::GoalSpec)::GoalSpec = goal_state

"Models transition dynamics at time `t` in a world model."
@gen function world_step(t::Int, world_state::WorldState, config::WorldConfig)
    # Unpack arguments
    @unpack domain, planner = config
    @unpack goal_step, env_step, obs_step = config
    @unpack goal_args, plan_args, env_args, obs_args = config
    @unpack goal_state, plan_state, env_state, obs_state = world_state
    # Transition to the current environment state from the previous one
    action = get_action(plan_state)
    env_state = @trace(env_step(t, env_state, action,
                                domain, env_args...), :env)
    # Sample an observation, given the current environment state
    obs_state = @trace(obs_step(t, obs_state, env_state,
                                domain, obs_args...), :obs)
    # Potentially sample a new goal
    goal_state = @trace(goal_step(t, goal_state, goal_args...), :goal)
    goal_spec = get_goal(goal_state)
    # Step forward in the plan, potentially replanning from the current state
    plan_step = get_step(planner)
    plan_state = @trace(plan_step(t, plan_state, planner, domain, env_state,
                                  goal_spec, plan_args...), :plan)
    # Pass the full state to the next step
    return WorldState(goal_state, plan_state, env_state, obs_state)
end

world_unfold = Unfold(world_step)

"Intialize world state by sampling from the initializers"
@gen function init_world_model(init::WorldInit)
    goal_state = @trace(sample_fn(init.goal_init), :goal_init)
    plan_state = @trace(sample_fn(init.plan_init), :plan_init)
    env_state = @trace(sample_fn(init.env_init), :env_init)
    obs_state = @trace(sample_fn(init.obs_init), :obs_init)
    return WorldState(goal_state, plan_state, env_state, obs_state)
end

"Models the evolution of a world with a planning agent for `n_steps`."
@gen (static) function world_model(n_steps::Int, init::WorldInit,
                                   config::WorldConfig)
    # Intialize world state by sampling from the initializers
    goal_state = @trace(sample_fn(init.goal_init), :goal_init)
    plan_state = @trace(sample_fn(init.plan_init), :plan_init)
    env_state = @trace(sample_fn(init.env_init), :env_init)
    obs_state = @trace(sample_fn(init.obs_init), :obs_init)
    world_state = WorldState(goal_state, plan_state, env_state, obs_state)
    world_traj = @trace(world_unfold(n_steps, world_state, config), :timestep)
    return world_traj
end
