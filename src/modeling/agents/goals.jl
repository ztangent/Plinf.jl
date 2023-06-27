## Goal model configurations ##

export GoalConfig, StaticGoalConfig, ResamplingGoalConfig

"""
    GoalConfig

Goal configuration for an agent model.

# Fields

$(FIELDS)
"""
struct GoalConfig{T,U,V}
    "Initializer with arguments `(belief_state, init_args...)`."
    init::T
    "Trailing arguments to initializer."
    init_args::U
    "Transition function with arguments `(t, goal_state, belief_state, step_args...)`."
    step::GenerativeFunction
    "Trailing arguments to transition function."
    step_args::V
end

"""
    stateless_goal_init(belief_state, goal_prior, init_args)

Goal initialization wrapper for goal priors that are state-independent.
"""
@gen function stateless_goal_init(belief_state, goal_prior, init_args=())
    {*} ~ maybe_sample(goal_prior, init_args)
end

# Static goal configuration #

"""
    StaticGoalConfig(goal_prior, state_dependent=false)

Constructs a `GoalConfig` that samples a static goal from a `goal_prior`. If
`state_dependent` is `true`, then the `goal_prior` is passed the agent's 
initial belief state as an argument.
"""
function StaticGoalConfig(goal_prior, state_dependent::Bool=false, init_args=())
    init = state_dependent ? goal_prior : stateless_goal_init
    init_args = state_dependent ? init_args : (goal_prior, init_args)
    return GoalConfig(init, init_args, static_goal_step, ())
end

"""
    static_goal_step(t, goal_state, belief_state)

Goal transition for static goals. Returns `goal_state` without modification.
"""
@gen static_goal_step(t, goal_state, belief_state) = goal_state

# Static goal configuration #

"""
    ResamplingGoalConfig(goal_prior, prob_resample, state_dependent=false)

Constructs a `GoalConfig` that samples an initial goal from a `goal_prior`,
then resamples a goal from the prior at each timestep with probability
`prob_resample`.

If `state_dependent` is `true`, then the `goal_prior` is passed the agent's 
initial belief state as an argument.
"""
function ResamplingGoalConfig(
    goal_prior, prob_resample::Real, state_dependent::Bool=false
)
    init = state_dependent ? goal_prior : stateless_goal_init
    init_args = state_dependent ? () : (goal_prior,)
    step_args = (goal_prior, prob_resample, state_dependent)
    return GoalConfig(init, init_args, resampling_goal_step, step_args)
end


"""
    resampling_goal_step(t, goal_state, belief_state,
                         goal_prior, prob_resample)

Goal transition that resamples a goal from the (state-dependent) prior with 
some probability `prob_resample` at each timestep.
"""
@gen function resampling_goal_step(
    t, goal_state, belief_state,
    goal_prior, prob_resample::Float64, state_dependent::Bool
)
    resample = {:resample} ~ bernoulli(prob_resample)
    if resample
        if state_dependent
            goal_state = {*} ~ goal_prior(belief_state)
        else
            goal_state = {*} ~ goal_prior()
        end
    end
    return goal_state
end
