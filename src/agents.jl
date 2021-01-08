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

"Goal transition function for static goals."
@gen static_goal_step(t, goal_state) =
    goal_state

"Deterministic action selection from current plan."
@gen planned_act_step(t, agent_state, env_state, domain) =
    get_action(agent_state.plan_state)

"ϵ-noisy action selection from current plan."
@gen function noisy_act_step(t, agent_state, env_state, domain, eps)
    intended = get_action(agent_state.plan_state)
    actions = available(env_state, domain)
    weights = [act == intended ? (1. - eps) / eps : 1. for act in actions]
    probs = weights ./ sum(weights)
    act = @trace(labeled_cat(actions, probs), :act)
end

"Accessor for goal states."
get_goal(goal_state)::GoalSpec = error("Not implemented.")
get_goal(goal_state::GoalSpec)::GoalSpec = goal_state

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
