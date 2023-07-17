export AgentState, AgentConfig
export agent_init, agent_step

include("beliefs.jl")
include("goals.jl")
include("plans.jl")
include("actions.jl")

"""
    AgentState

Represents the state of an agent at a point in time.

# Fields

$(FIELDS)
"""
struct AgentState{B,G,P}
    "Agent's belief state."
    belief_state::B
    "Agent's goal state."
    goal_state::G
    "Agent's plan state."
    plan_state::P
end

"""
    AgentConfig

Configuration of an agent model, including goal priors, planning steps, etc.

# Fields

$(FIELDS)    
"""
@kwdef struct AgentConfig{B,G,P,A}
    "Belief model configuration."
    belief_config::B = DirectBeliefConfig()
    "Goal model configuration"
    goal_config::G = StaticGoalConfig(MinStepsGoal([]))
    "Planning model configuration."
    plan_config::P = StaticPlanConfig()
    "Action model configuration."
    act_config::A = DetermActConfig()
end

"""
    AgentConfig(domain::Domain, planner::Planner; kwargs...)

Constructs an `AgentConfig` given a `domain` and `planner`, deciding which
plan and action configurations to use based on the type of planner and the
keyword arguments specified.
"""
function AgentConfig(
    domain::Domain, planner::Planner;
    replan_args=nothing,
    act_temperature=nothing,
    act_epsilon=nothing,
    act_default=nothing,
    kwargs...
)   
    # Construct plan configuration depending on arguments
    if replan_args !== nothing
        if planner isa Union{RTDP,RTHS}
            plan_config = ReplanPolicyConfig(domain, planner; replan_args...)
        else
            plan_config = ReplanConfig(domain, planner; replan_args...)
        end
    else
        plan_config = DetermReplanConfig(domain, planner)
    end
    # Construct action configuration depending on keyword arguments
    if act_epsilon !== nothing
        act_config = act_default === nothing ? 
            EpsilonGreedyActConfig(domain, act_epsilon) : 
            EpsilonGreedyActConfig(domain, act_epsilon, act_default)
    elseif act_temperature !== nothing
        act_config = BoltzmannActConfig(act_temperature)
    else
        act_config = DetermActConfig()
    end
    # Return agent configuration
    return AgentConfig(;
        plan_config=plan_config,
        act_config=act_config,
        kwargs...
    )
end

"""
    agent_init(config::AgentConfig, env_state)

Initialize agent state by sampling from the initializers.
"""
@gen function agent_init(config::AgentConfig, env_state)
    # Initialize agent states
    @unpack init, init_args = config.belief_config
    belief_state = {:belief} ~ maybe_sample(init, (env_state, init_args...))
    @unpack init, init_args = config.goal_config
    goal_state = {:goal} ~ maybe_sample(init, (belief_state, init_args...))
    @unpack init, init_args = config.plan_config
    plan_state = {:plan} ~ maybe_sample(init, (belief_state, goal_state, init_args...))
    # Return agent state
    return AgentState(belief_state, goal_state, plan_state)
end

"""
    agent_step(t::Int, agent_state::AgentState, env_state, config::AgentConfig)

Models agent transition at step `t`, given the `agent_state` and `env_state`.
"""
@gen function agent_step(
    t::Int, agent_state::AgentState, env_state::State, config::AgentConfig
)
    # Unpack agent state and configuration
    @unpack belief_state, goal_state, plan_state = agent_state
    @unpack belief_config, goal_config, plan_config = config
    # Update the agent's beliefs
    belief_step, belief_step_args = belief_config.step, belief_config.step_args
    belief_state = {:belief} ~ belief_step(t, belief_state, env_state,
                                           belief_step_args...)
    # Update the agent's goal
    goal_step, goal_step_args = goal_config.step, goal_config.step_args
    goal_state = {:goal} ~ goal_step(t, goal_state, belief_state,
                                     goal_step_args...)
    # Update the agent's plan
    plan_step, plan_step_args = plan_config.step, plan_config.step_args
    plan_state = {:plan} ~ plan_step(t, plan_state, belief_state, goal_state,
                                     plan_step_args...)
    # Return updated agent state
    return AgentState(belief_state, goal_state, plan_state)
end
