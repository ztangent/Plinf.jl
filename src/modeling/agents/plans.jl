## Planning states and configurations ##

export PlanState
export PlanConfig, DetermReplanConfig, ReplanConfig, ReplanPolicyConfig

import SymbolicPlanners: NullSpecification, NullGoal

"""
    PlanState

Represents the plan or policy of an agent at a point in time.

# Fields

$(FIELDS)
"""
struct PlanState
    "Initial timestep of the current plan."
    init_step::Int
    "Solution returned by the planner."
    sol::Solution
    "Specification that the solution is intended to satisfy."
    spec::Specification
end

PlanState() = PlanState(0, NullSolution(), NullGoal())

"Returns whether an action is planned for step `t` at a `belief_state`."
has_action(plan_state::PlanState, t::Int, belief_state) =
    has_action(plan_state.sol, t - plan_state.init_step + 1, belief_state)

has_action(sol::NullSolution, t::Int, state::State) =
    false
has_action(sol::NullPolicy, t::Int, state::State) =
    false
has_action(sol::PolicySolution, t::Int, state::State) =
    !ismissing(SymbolicPlanners.get_action(sol, state))
has_action(sol::OrderedSolution, t::Int, state::State) =
    ((0 < t <= length(sol) && sol[t] == state) ||
     !isnothing(findfirst(==(state), sol)))
has_action(sol::PathSearchSolution, t::Int, state::State) =
    !ismissing(SymbolicPlanners.get_action(sol, state))

"""
    PlanConfig

Planning configuration for an agent model.

# Fields

$(FIELDS)
"""
struct PlanConfig{T,U,V}
    "Initializer with arguments `(belief_state, goal_state, init_args...)`."
    init::T
    "Trailing arguments to initializer."
    init_args::U
    "Transition function with arguments `(t, plan_state, belief_state, goal_state, step_args...)`."
    step::GenerativeFunction
    "Trailing arguments to transition function."
    step_args::V
end

"""
    default_plan_init(belief_state, goal_state)

Default plan initialization, which returns a `PlanState` with a `NullSolution`
and the initial goal specification (i.e. no planning is done on the zeroth
timestep).
"""
function default_plan_init(belief_state, goal_state)
    return PlanState(0, NullSolution(), convert(Specification, goal_state))
end

"""
    step_plan_init(belief_state, goal_state, plan_step, step_args...)

Reuses the `plan_step` function to initialize the plan at the zeroth timestep.
An initial plan state is constructed with a `NullSolution` and the initial
goal specification, and then `plan_step` is called with this initial plan state.
"""
@gen function step_plan_init(belief_state, goal_state, plan_step, step_args)
    plan_state = PlanState(0, NullSolution(), convert(Specification, goal_state))
    plan_state = {*} ~ plan_step(0, plan_state, belief_state,
                                 goal_state, step_args...)
    return plan_state
end

"""
    StaticPlanConfig(init=PlanState(), init_args=())

Constructs a `PlanConfig` that never updates the initial plan.
"""
function StaticPlanConfig(init=default_plan_init, init_args=())
    return PlanConfig(init, init_args, static_plan_step, ())
end

"""
    static_plan_step(t, plan_state, belief_state, goal_state)

Plan transition that returns the previous plan state without modification.
"""
@gen static_plan_step(t::Int, plan_state, belief_state, goal_state) = plan_state

# Deterministic (re)planning configuration #

"""
    DetermReplanConfig(domain::Domain, planner::Planner; plan_at_init=false)

Constructs a `PlanConfig` that deterministically replans only when necessary.
If `plan_at_init` is true, then the initial plan is computed at timestep zero.
"""
function DetermReplanConfig(domain::Domain, planner::Planner;
                            plan_at_init::Bool = false)
    if plan_at_init
        init = step_plan_init
        init_args = (determ_replan_step, (domain, planner))
    else
        init = default_plan_init
        init_args = ()
    end
    return PlanConfig(init, init_args, determ_replan_step, (domain, planner))
end

"""
    determ_replan_step(t, plan_state, belief_state, goal_state, domain, planner)

Deterministic replanning step, which only replans when an unexpected state
is encountered. Replanning is either a full horizon search or goes on until
a fixed budget.
"""
@gen function determ_replan_step(
    t::Int, plan_state::PlanState, belief_state::State, goal_state,
    domain::Domain, planner::Planner
)   
    spec = convert(Specification, goal_state)
    # Return original plan if an action is already computed
    if (has_action(plan_state, t, belief_state) &&
        (plan_state.spec === spec || plan_state.spec == spec))
        return plan_state
    else # Otherwise replan from the current belief state
        sol = planner(domain, belief_state, spec)
        return PlanState(t, sol, spec)
    end
end

# Stochastic (re)planning configuration #

"""
    ReplanConfig(
        domain::Domain, planner::Planner;
        plan_at_init::Bool = false,
        prob_replan::Real=0.1,
        rand_budget::Bool = true,
        budget_var::Symbol = default_budget_var(planner),
        budget_dist::Distribution = shifted_neg_binom,
        budget_dist_args::Tuple = (2, 0.05, 1)
    )

Constructs a `PlanConfig` that may stochastically replan at each timestep.
If `plan_at_init` is true, then the initial plan is computed at timestep zero.
"""
function ReplanConfig(
    domain::Domain, planner::Planner;
    plan_at_init::Bool = false,
    prob_replan::Real = 0.1,
    rand_budget::Bool = true,
    budget_var::Symbol = default_budget_var(planner),
    budget_dist::Distribution = shifted_neg_binom,
    budget_dist_args::Tuple = (2, 0.05, 1)
)
    step_args = (domain, planner, prob_replan, rand_budget,
                 budget_var, budget_dist, budget_dist_args)
    if plan_at_init
        init = step_plan_init
        init_args = (replan_step, step_args)
    else
        init = default_plan_init
        init_args = ()
    end
    return PlanConfig(init, init_args, replan_step, step_args)
end

default_budget_var(::Planner) = :max_time
default_budget_var(::ForwardPlanner) = :max_nodes

"""
    replan_step(t, plan_state, belief_state, goal_state, domain, planner,
                prob_replan=0.1, budget_var=:max_nodes,
                budget_dist=shifted_neg_binom, budget_dist_args=(2, 0.95, 1))

Replanning step for ordered planners. At each timestep, a decision is made 
whether to replan, and replanning uses a randomly sampled resource budget.
"""
@gen function replan_step(
    t::Int, plan_state::PlanState, belief_state::State, goal_state,
    domain::Domain, planner::Planner,
    prob_replan::Real=0.1,
    rand_budget::Bool=true,
    budget_var::Symbol=:max_nodes,
    budget_dist::Distribution=shifted_neg_binom,
    budget_dist_args::Tuple=(2, 0.05, 1)
)   
    spec = convert(Specification, goal_state)
    # Replan with certainty if action is unplanned or goal changes
    if (!has_action(plan_state, t, belief_state) ||
        (plan_state.spec !== spec && plan_state.spec != spec))
        prob_replan = 1.0
    end
    # Sample whether to replan
    replan = {:replan} ~ bernoulli(prob_replan)
    if rand_budget # Sample planning resource budget
        budget = {:budget} ~ budget_dist(budget_dist_args...)
    end
    # Decide whether to replan
    if !replan # Return original plan
        return plan_state
    else # Otherwise replan from the current belief state
        if rand_budget # Set new resource budget
            planner = copy(planner)
            setproperty!(planner, budget_var, budget)
        end
        # Compute and return new plan
        sol = planner(domain, belief_state, spec)
        return PlanState(t, sol, spec)
    end
end

"""
    ReplanPolicyConfig(
        domain::Domain, planner::Planner;
        plan_at_init::Bool = false,
        prob_replan::Real = 0.05,
        prob_refine::Real = 0.2,
        rand_budget::Bool = true,
        budget_var::Symbol = default_budget_var(planner),
        budget_dist::Distribution = shifted_neg_binom,
        budget_dist_args::Tuple = (2, 0.05, 1)
    )

Constructs a `PlanConfig` that may stochastically recompute or refine a policy
at each timestep. If `plan_at_init` is true, then the initial plan is computed
at timestep zero.
"""
function ReplanPolicyConfig(
    domain::Domain, planner::Planner;
    plan_at_init::Bool = false,
    prob_replan::Real = 0.05,
    prob_refine::Real = 0.2,
    rand_budget::Bool = true,
    budget_var::Symbol = default_budget_var(planner),
    budget_dist::Distribution = shifted_neg_binom,
    budget_dist_args::Tuple = (2, 0.05, 1)
)
    step_args = (domain, planner, prob_replan, prob_refine,
                 rand_budget, budget_var, budget_dist, budget_dist_args)
    if plan_at_init
        init = step_plan_init
        init_args = (policy_step, step_args)
    else
        init = default_plan_init
        init_args = ()
    end
    return PlanConfig(init, init_args, policy_step, step_args)
end

default_budget_var(::RealTimeDynamicPlanner) = :max_depth
default_budget_var(::RealTimeHeuristicSearch) = :max_nodes

"""
    policy_step(t, plan_state, belief_state, goal_state, domain, planner,
                prob_replan=0.05, prob_refine=0.2, rand_budget=true,
                budget_var=:max_depth, budget_dist=shifted_neg_binom,
                budget_dist_args=(2, 0.95, 1))

Replanning step for policy-based planners. At each timestep, a decision is made 
whether to refine the existing policy or replan from scratch. If `rand_budget`
is true, policy computation or refinement is performed up to randomly sampled
maximum resource budget.
"""
@gen function policy_step(
    t::Int, plan_state::PlanState, belief_state::State, goal_state,
    domain::Domain, planner::Planner,
    prob_replan::Real=0.05,
    prob_refine::Real=0.2,
    rand_budget::Bool=true,
    budget_var::Symbol=:max_depth,
    budget_dist::Distribution=shifted_neg_binom,
    budget_dist_args::Tuple=(2, 0.05, 1)
)
    spec = convert(Specification, goal_state)
    # Replan with certainty if action is unplanned or goal changes
    if (!has_action(plan_state, t, belief_state) ||
        plan_state.sol isa NullPolicy ||
        (plan_state.spec !== spec && plan_state.spec != spec))
        prob_replan = 1.0
        prob_refine = 0.0
    end
    # Sample whether to replan or refine
    probs = [1-(prob_replan+prob_refine), prob_replan, prob_refine]
    replan = {:replan} ~ categorical(probs)
    if rand_budget # Sample planning resource budget
        budget = {:budget} ~ budget_dist(budget_dist_args...)
    end
    # Decide whether to replan or refine
    if replan == 1 # Return original plan
        return plan_state
    elseif replan == 2 # Replan from the current belief state
        if rand_budget # Set new resource budget
            planner = copy(planner)
            setproperty!(planner, budget_var, budget)
        end
        # Compute and return new plan
        sol = planner(domain, belief_state, spec)
        return PlanState(t, sol, spec)
    elseif replan == 3 # Refine existing solution
        if rand_budget # Set new resource budget
            planner = copy(planner)
            setproperty!(planner, budget_var, budget)
        end
        # Refine existing solution
        sol = copy(plan_state.sol)
        refine!(sol, planner, domain, belief_state, spec)
        return PlanState(plan_state.init_step, sol, spec)
    end
end
