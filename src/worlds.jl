export WorldState, WorldInit, WorldConfig, world_step, world_model

"Represents the state of the world (agent + environment) at some time `t`."
struct WorldState
    agent_state # Agent state at time t
    env_state # Environment state at  time t
    obs_state # Observation state at time t
end

"Intializers for various states in a world model."
struct WorldInit
    agent_init
    env_init
    obs_init
end

WorldInit(agent_init::AgentInit, env_state::State) =
    WorldInit(agent_init, env_state, env_state)

"Configuration of the world's transition dynamics."
@kwdef struct WorldConfig
  domain::Domain
  agent_config::AgentConfig
  env_step::GenerativeFunction = determ_env_step
  env_args::Union{Tuple,GenerativeFunction} = ()
  obs_step::GenerativeFunction = markov_obs_step
  obs_args::Union{Tuple,GenerativeFunction} = ()
end

function WorldConfig(domain::Domain, agent_config::AgentConfig,
                     obs_params::ObserveParams; kwargs...)
    WorldConfig(domain=domain, agent_config=agent_config,
                env_step=determ_env_step, obs_args=(obs_params,), kwargs...)
end

"Environment transition function for deterministic dynamics."
"Environment transition function for deterministic dynamics."
@gen function determ_env_step(t, env_state::State, action::Term, domain::Domain)
    if action.name == Symbol("--") || !available(domain, env_state, action)
        return env_state
    else
        return transition(domain, env_state, action, check=false)
    end
end

"Observation which depends on only the current environment state."
@gen markov_obs_step(t, obs_state, env_state::State, domain::Domain, params) =
    @trace(observe_state(env_state, domain, params))

"Models transition dynamics at time `t` in a world model."
@gen function world_step(t::Int, world_state::WorldState, config::WorldConfig)
    @unpack domain, agent_config = config
    @unpack act_step, act_args = agent_config
    @unpack env_step, obs_step, env_args, obs_args = config
    @unpack agent_state, env_state, obs_state = world_state
    # Sample the agent's action in response to the previous state
    action = @trace(act_step(t, agent_state, env_state,
                             domain, act_args...), :act)
    # Transition to the current environment state from the previous one
    env_state = @trace(env_step(t, env_state, action,
                                domain, env_args...), :env)
    # Sample an observation, given the current environment state
    obs_state = @trace(obs_step(t, obs_state, env_state,
                                domain, obs_args...), :obs)
    # Advance the agent by one step
    agent_state = @trace(agent_step(t, agent_state,
                                    env_state, agent_config), :agent)
    # Pass the full state to the next step
    return WorldState(agent_state, env_state, obs_state)
end

world_unfold = Unfold(world_step)

"Intialize world state by sampling from the initializers"
@gen function init_world_model(init::WorldInit, config::WorldConfig)
    @unpack agent_init, env_init = init
    @unpack domain, agent_config = config
    @unpack env_step, obs_step, env_args, obs_args = config
    # Sample parameters from priors
    env_args = @trace(sample_fn(env_args), :env_args)
    obs_args = @trace(sample_fn(obs_args), :obs_args)
    # Initialize agent, environment, and observation
    agent_state, agent_config =
        @trace(init_agent_model(agent_init, agent_config), :agent)
    env_state = @trace(sample_fn(init.env_init), :env)
    obs_state = @trace(observe_state(env_state, domain, obs_args...), :obs)
    # Return sampled state and configuration
    state = WorldState(agent_state, env_state, obs_state)
    config = WorldConfig(domain, agent_config,
                         env_step, env_args, obs_step, obs_args)
    return state, config
end

"Models the evolution of a world with a planning agent for `n_steps`."
@gen (static) function world_model(n_steps::Int, init::WorldInit,
                                   config::WorldConfig)
    world_state, config = @trace(init_world_model(init, config), :init)
    world_traj = @trace(world_unfold(n_steps, world_state, config), :timestep)
    return world_traj
end
