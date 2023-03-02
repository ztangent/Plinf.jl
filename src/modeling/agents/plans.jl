## Planning states and configurations ##

export PlanState
export PlanConfig, DetermReplanConfig, ReplanConfig, ReplanPolicyConfig

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
end

PlanState() = PlanState(0, NullSolution())

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

# Static planning configuration #

"""
    StaticPlanConfig(init=PlanState(), init_args=())

Constructs a `PlanConfig` that never updates the initial plan.
"""
function StaticPlanConfig(init=PlanState(), init_args=())
    return PlanConfig(init, init_args, static_plan_step, ())
end

"""
    static_plan_step(t, plan_state, belief_state, goal_state)

Plan transition that returns the previous plan state without modification.
"""
@gen static_plan_step(t::Int, plan_state, belief_state, goal_state) = plan_state

# Deterministic (re)planning configuration #

"""
    DetermReplanConfig(domain::Domain, planner::Planner)

Constructs a `PlanConfig` that deterministically replans only when necessary.
"""
function DetermReplanConfig(domain::Domain, planner::Planner)
    init = PlanState(0, NullSolution())
    return PlanConfig(init, (), determ_replan_step, (domain, planner))
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
    # Return original plan if an action is already computed
    if has_action(plan_state, t, belief_state)
        return plan_state
    else # Otherwise replan from the current belief state
        spec = convert(Specification, goal_state)
        sol = planner(domain, belief_state, spec)
        return PlanState(t, sol)
    end
end

# Stochastic (re)planning configuration #

"""
    ReplanConfig(
        domain::Domain, planner::Planner;
        prob_replan::Real=0.1,
        budget_var::Symbol = default_budget_var(planner),
        budget_dist::Distribution = shifted_neg_binom,
        budget_dist_args::Tuple = (2, 0.05, 1)
    )

Constructs a `PlanConfig` that may stochastically replan at each timestep.
"""
function ReplanConfig(
    domain::Domain, planner::Planner;
    prob_replan::Real = 0.1,
    budget_var::Symbol = default_budget_var(planner),
    budget_dist::Distribution = shifted_neg_binom,
    budget_dist_args::Tuple = (2, 0.05, 1)
)
    init = PlanState(0, NullSolution())
    step_args = (domain, planner, prob_replan,
                 budget_var, budget_dist, budget_dist_args)
    return PlanConfig(init, (), replan_step, step_args)
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
    budget_var::Symbol=:max_nodes,
    budget_dist::Distribution=shifted_neg_binom,
    budget_dist_args::Tuple=(2, 0.05, 1)
)   
    # Replan with certainty if existing action does not cover current state
    prob_replan = has_action(plan_state, t, belief_state) ? prob_replan : 1.0
    # Sample whether to replan
    replan = {:replan} ~ bernoulli(prob_replan)
    # Sample planning resource budget
    budget = {:budget} ~ budget_dist(budget_dist_args...)
    # Decide whether to replan
    if !replan # Return original plan
        return plan_state
    else # Otherwise replan from the current belief state
        # Set new resource budget
        planner = copy(planner)
        setproperty!(planner, budget_var, budget)
        # Compute and return new plan
        spec = convert(Specification, goal_state)
        sol = planner(domain, belief_state, spec)
        return PlanState(t, sol)
    end
end

"""
    ReplanPolicyConfig(
        domain::Domain, planner::Planner;
        prob_replan::Real = 0.05,
        prob_refine::Real = 0.2,
        budget_var::Symbol = default_budget_var(planner),
        budget_dist::Distribution = shifted_neg_binom,
        budget_dist_args::Tuple = (2, 0.05, 1)
    )

Constructs a `PlanConfig` that may stochastically recompute or refine a policy
at each timestep.
"""
function ReplanPolicyConfig(
    domain::Domain, planner::Planner;
    prob_replan::Real = 0.05,
    prob_refine::Real = 0.2,
    budget_var::Symbol = default_budget_var(planner),
    budget_dist::Distribution = shifted_neg_binom,
    budget_dist_args::Tuple = (2, 0.05, 1)
)
    init = PlanState(0, NullPolicy())
    step_args = (domain, planner, prob_replan, prob_refine,
                 budget_var, budget_dist, budget_dist_args)
    return PlanConfig(init, (), policy_step, step_args)
end

default_budget_var(::RealTimeDynamicPlanner) = :max_depth
default_budget_var(::RealTimeHeuristicSearch) = :max_nodes

"""
    policy_step(t, plan_state, belief_state, goal_state, domain, planner,
                prob_replan=0.05, prob_refine=0.2,
                budget_var=:max_depth, budget_dist=shifted_neg_binom,
                budget_dist_args=(2, 0.95, 1))

Replanning step for policy-based planners. At each timestep, a decision is made 
whether to refine the existing policy or replan from scratch. Policy computation
or refinement is performed up to randomly sampled maximum resource budget.
"""
@gen function policy_step(
    t::Int, plan_state::PlanState, belief_state::State, goal_state,
    domain::Domain, planner::Planner,
    prob_replan::Real=0.05,
    prob_refine::Real=0.2,
    budget_var::Symbol=:max_depth,
    budget_dist::Distribution=shifted_neg_binom,
    budget_dist_args::Tuple=(2, 0.05, 1)
)
    # Replan with certainty if existing action does not cover current state
    if !has_action(plan_state, t, belief_state) || plan_state.sol isa NullPolicy
        prob_replan = 1.0
        prob_refine = 0.0
    end
    # Sample whether to replan or refine
    probs = [1-(prob_replan+prob_refine), prob_replan, prob_refine]
    replan = {:replan} ~ categorical(probs)
    # Sample planning resource budget
    budget = {:budget} ~ budget_dist(budget_dist_args...)
    # Decide whether to replan or refine
    if replan == 1 # Return original plan
        return plan_state
    elseif replan == 2 # Replan from the current belief state
        # Set new resource budget
        planner = copy(planner)
        setproperty!(planner, budget_var, budget)
        # Compute and return new plan
        spec = convert(Specification, goal_state)
        sol = planner(domain, belief_state, spec)
        return PlanState(t, sol)
    elseif replan == 3 # Refine existing solution
        # Set new resource budget
        planner = copy(planner)
        setproperty!(planner, budget_var, budget)
        # Refine existing solution
        spec = convert(Specification, goal_state)
        sol = copy(plan_state.sol)
        refine!(sol, planner, domain, belief_state, spec)
        return PlanState(plan_state.init_step, sol)
    end
end
