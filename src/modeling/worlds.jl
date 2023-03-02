export WorldState, WorldConfig
export world_init, world_step, world_model

"""
    WorldState

Represents the state the world (agent + environment) at a point in time.

# Fields

$(FIELDS)
"""
struct WorldState{A,X,E,O}
    "Agent state."
    agent_state::A
    "Action state."
    act_state::X
    "Environment state."
    env_state::E
    "Observed state."
    obs_state::O
end

"""
    WorldConfig

Configuration of a world model, including agent, environment, and observation
model configurations.

# Fields

$(FIELDS)    
"""
@kwdef struct WorldConfig{A,E,O}
  "Agent model configuration."
  agent_config::A = AgentConfig()
  "Environment model configuration."
  env_config::E = StaticEnvConfig()
  "Observation model configuration."
  obs_config::O = PerfectObsConfig()
end

"""
    world_init(config::WorldConfig)

Initialize world state by sampling from the initializers.
"""
@gen function world_init(config::WorldConfig)
    # (Optionally) sample from priors over model configurations
    @unpack agent_config, env_config, obs_config = config
    agent_config = {:agent_config} ~ maybe_sample(agent_config)
    env_config = {:env_config} ~ maybe_sample(env_config)
    obs_config = {:obs_config} ~ maybe_sample(obs_config)
    # Initialize environment, agent, and observation states
    env_state = {:env} ~ maybe_sample(env_config.init, env_config.init_args)
    obs_state = {:obs} ~ maybe_sample(obs_config.init,
                                      (env_state, obs_config.init_args...))
    agent_state = {:agent} ~ agent_init(agent_config, env_state)
    # Return sampled state and configuration
    act_state = convert(Term, PDDL.no_op)
    state = WorldState(agent_state, act_state, env_state, obs_state)
    config = WorldConfig(agent_config, env_config, obs_config)
    return state, config
end

"""
    world_step(t::Int, world_state::WorldState, config::WorldConfig)

Models transition dynamics at step `t` in a world model.
"""
@gen function world_step(t::Int, world_state::WorldState, config::WorldConfig)
    # Unpack agent state and configuration
    @unpack agent_state, env_state, obs_state = world_state
    @unpack agent_config, env_config, obs_config = config
    # Unpack sub-configurations
    @unpack act_config = agent_config
    act_step, act_step_args = act_config.step, act_config.step_args
    env_step, env_step_args = env_config.step, env_config.step_args
    obs_step, obs_step_args = obs_config.step, obs_config.step_args
    # Advance the agent by one step
    agent_state = {:agent} ~ agent_step(t, agent_state, env_state, agent_config)
    # Sample the agent's actions in response to the previous state
    act_state = {:act} ~ act_step(t, agent_state, env_state, act_step_args...)
    # Run the environment transition dynamics forward
    env_state = {:env} ~ env_step(t, env_state, act_state, env_step_args...)
    # Sample an observation, given the current environment state
    obs_state = {:obs} ~ obs_step(t, obs_state, env_state, obs_step_args...)
    # Pass the full state to the next step
    return WorldState(agent_state, act_state, env_state, obs_state)
end

"Unfold combinator applied to `world_step`."
world_unfold = Unfold(world_step)

"""
    world_model(n_steps::Int, config::WorldConfig)

Models the time-evolution of a world (agent + environment) for `n_steps`.
"""
@gen (static) function world_model(n_steps::Int, config::WorldConfig)
    world_state, config = {:init} ~ world_init(config)
    world_trajectory = {:timestep} ~ world_unfold(n_steps, world_state, config)
    return world_trajectory
end
