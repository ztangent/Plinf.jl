export AgentState, AgentInit, AgentConfig, agent_step

"Represents the state of the agent at time `t`."
struct AgentState
    planner # Agent planner state
    goal_state # Environment state at  time t
    plan_state # Observation state at time t
end

"Intializers for various states in an agent model."
struct AgentInit
    planner_init
    goal_init
    plan_init
end

AgentInit(planner::Planner, goal_init) =
    AgentInit(planner, goal_init, init_plan_state(planner))

"Configuration of the agent's transition dynamics."
@kwdef struct AgentConfig
    domain::Domain
    goal_step::GenerativeFunction = static_goal_step
    goal_args::Tuple = ()
    plan_step::GenerativeFunction = replan_step
    plan_args::Tuple = ()
    act_step::GenerativeFunction = planned_act_step
    act_args::Tuple = ()
end

AgentConfig(domain::Domain; act_noise=0.0, kwargs...) =
    if act_noise == 0
        AgentConfig(domain=domain, act_step=planned_act_step, kwargs...)
    else
        AgentConfig(domain=domain, act_step=noisy_act_step,
                    act_args=(act_noise,), kwargs...)
    end

"Intialize agent_state by sampling from the initializers"
@gen function init_agent_model(init::AgentInit)
    planner = @trace(sample_fn(init.planner_init), :planner)
    goal_state = @trace(sample_fn(init.goal_init), :goal)
    plan_state = @trace(sample_fn(init.plan_init), :plan)
    return AgentState(planner, goal_state, plan_state)
end

"Models agent update at time `t`."
@gen function agent_step(t::Int, agent_state::AgentState, env_state::State,
                         config::AgentConfig)
    @unpack domain, plan_step, goal_step, plan_args, goal_args = config
    @unpack planner, goal_state, plan_state = agent_state
    # Potentially sample a new goal
    goal_state = @trace(goal_step(t, goal_state, goal_args...), :goal)
    goal_spec = get_goal(goal_state)
    # Step forward in the plan, potentially replanning from the current state
    plan_state = @trace(plan_step(t, plan_state, planner, domain, env_state,
                                  goal_spec, plan_args...), :plan)
    return AgentState(planner, goal_state, plan_state)
end

"Propose agent steps for timesteps in `t1:t2`."
@gen function agent_propose_range(t1::Int, t2::Int, agent_state::AgentState,
                                  env_state::State, config::AgentConfig,
                                  obs_states::Vector{<:Union{State,Nothing}})
   @unpack domain, goal_step, goal_args, act_step, act_args = config
   @unpack planner, goal_state, plan_state = agent_state
   step_propose = get_step_proposal(planner)
   agent_states = Vector{AgentState}()
   for t in 1:(t2-t1+1)
       # Potentially sample a new goal
       goal_state = @trace(goal_step(t, goal_state, goal_args...),
                           :timestep => t+t1-1 => :agent => :goal)
       goal_spec = get_goal(goal_state)
       # Propose new planning step
       plan_state = @trace(step_propose(t+t1-1, plan_state, planner, domain,
                                        env_state, goal_spec,
                                        obs_states[t:end], nothing),
                           :timestep => t+t1-1 => :agent => :plan)
       # Construct agent state
       agent_state = AgentState(planner, goal_state, plan_state)
       push!(agent_states, agent_state)
       # Propose next action
       if t < (t2-t1+1) && (length(obs_states) < t+1 || obs_states[t+1] === nothing)
           action = @trace(act_step(t, agent_state, env_state,
                                    domain, act_args...),
                           :timestep => t+t1 => :act)
       elseif t < (t2-t1+1)
           action = @trace(forward_act_proposal(domain, agent_state, env_state,
                                                obs_states[t+1], act_args...),
                           :timestep => t+t1 => :act)
       end
       # Transition to next environment state
       if t < (t2-t1+1)
           env_state = @trace(determ_env_step(t, env_state, action, domain),
                              :timestep => t+t1 => :env)
       end
   end
   return agent_states
end
