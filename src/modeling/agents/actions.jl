## Action distributions and model configurations ##

export ActConfig, DetermActConfig, EpsilonGreedyActConfig, BoltzmannActConfig
export CommunicativeActConfig, CommunicativeActState
export policy_dist

"""
    ActConfig

Configuration of an agent's action model.

# Fields

$(FIELDS)
"""
struct ActConfig{V}
    "Transition function with arguments `(t, agent_state, env_state, step_args...)`."
    step::GenerativeFunction
    "Trailing arguments to transition function."
    step_args::V
end

# Deterministic action selection #

"""
    DetermActConfig()

Constructs an `ActConfig` which deterministically selects the planned best
action for the current state, give the current plan or policy.
"""
function DetermActConfig()
    return ActConfig(determ_act_step, ())
end

"""
    determ_act_step(t, agent_state, env_state)

Deterministic action selection from the current plan or policy. Returns
a no-op action if the goal has been achieved.
"""
@gen function determ_act_step(t, agent_state, env_state)
    # Planning solution is assumed to be a deterministic plan or policy
    plan_state = agent_state.plan_state::PlanState
    act = {:act} ~ policy_dist(plan_state.sol, env_state)
    return act
end

# Epsilon greedy action selection #

"""
    EpsilonGreedyActConfig(domain::Domain, epsilon::Real)

Constructs an `ActConfig` which selects a random action `epsilon` of the time
and otherwise selects the best/planned action.
"""
function EpsilonGreedyActConfig(domain::Domain, epsilon::Real)
    return ActConfig(eps_greedy_act_step, (domain, epsilon))
end

"""
    eps_greedy_act_step(t, agent_state, env_state, domain, epsilon)

Samples an available action uniformly at random `epsilon` of the time, otherwise
selects the best action.
"""
@gen function eps_greedy_act_step(t, agent_state, env_state,
                                  domain::Domain, epsilon::Real)
    plan_state = agent_state.plan_state::PlanState
    policy = EpsilonGreedyPolicy(domain, plan_state.sol, epsilon)
    act = {:act} ~ policy_dist(policy, env_state)
    return act
end

# Boltzmann action selection #

"""
    BoltzmannActConfig(temperature::Real)

Constructs an `ActConfig` which samples actions according to the Boltzmann
distribution over action Q-values with a specified `temperature`.
"""
function BoltzmannActConfig(temperature::Real)
    return ActConfig(boltzmann_act_step, (temperature,))
end

"""
    boltzmann_act_step(t, agent_state, env_state, temperature)

Samples actions according to the Boltzmann distribution over action values with
a specified `temperature`
"""
@gen function boltzmann_act_step(t, agent_state, env_state, temperature::Real)
    plan_state = agent_state.plan_state::PlanState
    policy = BoltzmannPolicy(plan_state.sol, temperature)
    act = {:act} ~ policy_dist(policy, env_state)
    return act
end

# Joint communication / action model #

"""
    CommunicativeActState

State of a communicative action model, containing an `action` term and
`utterance` string.
"""
struct CommunicativeActState
    action::Term
    utterance::String
end

convert(::Type{Term}, state::CommunicativeActState) = state.action

"""
    CommunicativeActConfig(
        act_config::ActConfig,
        utterance_model::GenerativeFunction
    )

Constructs an `ActConfig` which samples an action and utterance jointly,
combined of an existing (non-communicative) `act_config` and an utterance model
with arguments `(t, agent_state, env_state, act)`.
"""
function CommunicativeActConfig(
    act_config::ActConfig, utterance_model::GenerativeFunction
)
    act_step = act_config.step
    act_step_args = act_config.step_args
    return ActConfig(communicative_act_step,
                     (act_step, act_step_args, utterance_model))
end

@gen function communicative_act_step(t, agent_state, env_state,
                                     act_step, act_step_args, utterance_model)
    # Sample action
    act = {*} ~ act_step(t, agent_state, env_state, act_step_args...)
    # Sample utterance
    utterance = {*} ~ utterance_model(t, agent_state, env_state, act)
    return CommunicativeActState(act, utterance)
end

# Policy distribution #

struct PolicyDistribution <: Gen.Distribution{Term} end

"""
    policy_dist(policy, state)

Gen `Distribution` that samples an action from a SymbolicPlanners `policy`
given the current `state`.
"""
const policy_dist = PolicyDistribution()

(d::PolicyDistribution)(args...) = Gen.random(d, args...)

@inline Gen.random(::PolicyDistribution, policy, state) =
    SymbolicPlanners.rand_action(policy, state)
@inline Gen.logpdf(::PolicyDistribution, act::Term, policy, state) =
    log(SymbolicPlanners.get_action_prob(policy, state, act))

# Always return no-op for null solutions
@inline Gen.random(::PolicyDistribution, ::NullSolution, state) =
    convert(Term, PDDL.no_op)
@inline Gen.logpdf(::PolicyDistribution, act::Term, ::NullSolution, state) =
    act.name == PDDL.get_name(PDDL.no_op) ? 0.0 : -Inf

Gen.logpdf_grad(::PolicyDistribution, act::Term, policy, state) =
    (nothing, nothing, nothing)
Gen.has_output_grad(::PolicyDistribution) =
    false
Gen.has_argument_grads(::PolicyDistribution) =
    (false, false)
