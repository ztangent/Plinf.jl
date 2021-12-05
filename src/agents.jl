export AgentState, AgentInit, AgentConfig, BoltzmannAgentConfig, agent_step

"Represents the state of the agent at time `t`."
struct AgentState
    goal_state # Environment state at  time t
    plan_state # Observation state at time t
end

"Intializers for various states in an agent model."
struct AgentInit
    goal_init
    plan_init
end

AgentInit(planner::Planner, goal_init) =
    AgentInit(goal_init, init_plan_state(planner))

"Configuration of the agent's transition dynamics."
@kwdef struct AgentConfig
    domain::Domain
    planner::Union{Planner,GenerativeFunction}
    goal_step::GenerativeFunction = static_goal_step
    goal_args::Union{Tuple,GenerativeFunction} = ()
    plan_step::GenerativeFunction = get_step(planner)
    plan_args::Union{Tuple,GenerativeFunction} = ()
    act_step::GenerativeFunction = planned_act_step
    act_args::Union{Tuple,GenerativeFunction} = ()
end

function AgentConfig(domain::Domain, planner::Union{Planner,GenerativeFunction};
                     act_noise=0.0, include_noop=true, kwargs...)
    if act_noise == 0
        AgentConfig(;domain=domain, planner=planner,
                    act_step=planned_act_step, kwargs...)
    else
        act_args = (act_noise, include_noop)
        AgentConfig(;domain=domain, planner=planner,
                    act_step=noisy_act_step, act_args=act_args, kwargs...)
    end
end

function BoltzmannAgentConfig(domain, planner; act_noise=nothing, kwargs...)
    if !haskey(kwargs, :act_args)
        act_args = (act_noise,)
        AgentConfig(;domain=domain, planner=planner, plan_step=rtdp_step,
                    act_step=boltzmann_act_step, act_args=act_args, kwargs...)
    else
        AgentConfig(;domain=domain, planner=planner,
                    plan_step=rtdp_step, act_step=boltzmann_act_step, kwargs...)
    end
end

"Intialize agent_state by sampling from the initializers"
@gen function init_agent_model(init::AgentInit, config::AgentConfig)
    @unpack domain, planner, goal_args, plan_args, act_args = config
    @unpack goal_step, plan_step, act_step = config
    # Sample parameters from priors
    planner = @trace(sample_fn(planner), :planner)
    goal_args = @trace(sample_fn(goal_args), :goal_args)
    plan_args = @trace(sample_fn(plan_args), :plan_args)
    act_args = @trace(sample_fn(act_args), :act_args)
    # Initialize agent states
    goal_state = @trace(sample_fn(init.goal_init), :goal)
    plan_state = @trace(sample_fn(init.plan_init, (goal_state,)), :plan)
    # Return sampled state and configuration
    state = AgentState(goal_state, plan_state)
    config = AgentConfig(domain, planner, goal_step, goal_args,
                         plan_step, plan_args, act_step, act_args)
    return state, config
end

"Models agent update at time `t`."
@gen function agent_step(t::Int, agent_state::AgentState, env_state::State,
                         config::AgentConfig)
    @unpack domain, planner, plan_step, goal_step, plan_args, goal_args = config
    @unpack goal_state, plan_state = agent_state
    # Potentially sample a new goal
    goal_state = @trace(goal_step(t, goal_state, goal_args...), :goal)
    goal_spec = get_goal(goal_state)
    # Step forward in the plan, potentially replanning from the current state
    plan_state = @trace(plan_step(t, plan_state, planner, domain, env_state,
                                  goal_spec, plan_args...), :plan)
    return AgentState(goal_state, plan_state)
end

"Propose agent steps for timesteps in `t1:t2`."
@gen function agent_propose_range(t1::Int, t2::Int, agent_state::AgentState,
                                  env_state::State, config::AgentConfig,
                                  obs_states::Vector{<:Union{State,Nothing}})
    @unpack domain, planner, goal_step, goal_args, act_step, act_args = config
    @unpack goal_state, plan_state = agent_state
    step_propose = get_step_proposal(planner)
    agent_states = Vector{AgentState}()
    for t in 1:(t2-t1+1)
        # Potentially sample a new goal
        goal_state = @trace(goal_step(t+t1-1, goal_state, goal_args...),
                            :timestep => t+t1-1 => :agent => :goal)
        goal_spec = get_goal(goal_state)
        # Propose new planning step
        plan_state = @trace(step_propose(t+t1-1, plan_state, planner, domain,
                                         env_state, goal_spec,
                                         obs_states[t:end], nothing),
                            :timestep => t+t1-1 => :agent => :plan)
        # Construct agent state
        agent_state = AgentState(goal_state, plan_state)
        push!(agent_states, agent_state)
        # Propose next action
        if (t < (t2-t1+1) &&
            (length(obs_states) < t+1 || obs_states[t+1] === nothing))
            action = @trace(act_step(t+t1, agent_state, env_state,
                                     domain, act_args...),
                            :timestep => t+t1 => :act)
        elseif t < (t2-t1+1)
            action = @trace(forward_act_proposal(t+t1, domain, agent_state, env_state,
                                                 obs_states[t+1], act_args...),
                            :timestep => t+t1 => :act)
        end
        # Transition to next environment state
        if t < (t2-t1+1)
            env_state = @trace(determ_env_step(t+t1, env_state, action, domain),
                               :timestep => t+t1 => :env)
        end
    end
    return agent_states
end
