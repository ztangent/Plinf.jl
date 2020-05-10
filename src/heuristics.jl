export Heuristic, GoalCountHeuristic, ManhattanHeuristic
export HSP, HAdd, HMax
export precompute, compute

"Abstract heuristic type, which defines the interface for planners."
abstract type Heuristic end

"Precomputes heuristic information given a domain, state, and goal."
precompute(h::Heuristic, domain::Domain, state::State, goal_spec::GoalSpec) =
    h # Return the heuristic unmodified by default

precompute(h::Heuristic, domain::Domain, state::State, goal_spec) =
    precompute(heuristic, domain, state, GoalSpec(goal_spec))

"Computes the heuristic value of state relative to a goal in a given domain."
compute(h::Heuristic, domain::Domain, state::State, goal_spec::GoalSpec) =
    error("Not implemented.")

compute(h::Heuristic, domain::Domain, state::State, goal_spec) =
    compute(heuristic, domain, state, GoalSpec(goal_spec))

(heuristic::Heuristic)(domain::Domain, state::State, goal_spec::GoalSpec) =
    compute(heuristic, domain, state, goal_spec)

(heuristic::Heuristic)(domain::Domain, state::State, goal_spec) =
    compute(heuristic, domain, state, GoalSpec(goal_spec))

"Heuristic that counts the number of goals unsatisfied in the domain."
struct GoalCountHeuristic <: Heuristic end

function compute(heuristic::GoalCountHeuristic,
                 domain::Domain, state::State, goal_spec::GoalSpec)
    return sum([!state[domain, g] for g in goal_spec.goals])
end

"Computes Manhattan distance to the goal for the specified numeric fluents."
struct ManhattanHeuristic <: Heuristic
    fluents::Vector{Term}
    goal_state::State
    ManhattanHeuristic(fluents) = new(fluents)
    ManhattanHeuristic(fluents, goal_state) = new(fluents, goal_state)
end

function precompute(heuristic::ManhattanHeuristic,
                    domain::Domain, state::State, goal_spec::GoalSpec)
    goal_state = State(goal_spec.goals)
    return @set heuristic.goal_state = goal_state
end

function compute(heuristic::ManhattanHeuristic,
                 domain::Domain, state::State, goal_spec::GoalSpec)
    @unpack fluents, goal_state = heuristic
    goal_vals = [goal_state[domain, f] for f in fluents]
    curr_vals = [state[domain, f] for f in fluents]
    dist = sum(abs.(goal_vals - curr_vals))
    return dist
end

"HSP family of relaxed progression search heuristics (HAdd, HMax, etc.)."
struct HSP <: Heuristic
    op::Function
    domain::Domain # Preprocessed domain
    axioms::Vector{Clause} # Preprocessed axioms
    HSP(op) = new(op)
    HSP(op, domain, axioms) = new(op, domain, axioms)
end

function precompute(heuristic::HSP,
                    domain::Domain, state::State, goal_spec::GoalSpec)
    domain = copy(domain) # Make a local copy of the domain
    axioms = regularize_clauses(domain.axioms) # Regularize domain axioms
    axioms = [Clause(ax.head, [t for t in ax.body if t.name != :not])
              for ax in axioms] # Remove negative literals
    domain.axioms = Clause[] # Remove axioms so they do not affect execution
    return HSP(heuristic.op, domain, axioms)
end

function compute(heuristic::HSP,
                 domain::Domain, state::State, goal_spec::GoalSpec)
    # Precompute if necessary
    if !isdefined(heuristic, :domain)
        heuristic = precompute(heuristic, domain, state, goal_spec) end
    @unpack op, domain, axioms = heuristic
    @unpack goals = goal_spec
    @unpack types, facts = state
    # Initialize fact costs in a GraphPlan-style graph
    fact_costs = Dict{Term,Float64}(f => 0 for f in facts)
    while true
        facts = Set(keys(fact_costs))
        state = State(types, facts, Dict{Symbol,Any}())
        if satisfy(goals, state, domain)[1]
            return op(fact_costs[g] for g in goals) end
        # Compute costs of one-step derivations of domain axioms
        for ax in axioms
            _, subst = resolve(ax.body, [Clause(f, []) for f in facts])
            for s in subst
                body = [substitute(t, s) for t in ax.body]
                cost = op([0; [get(fact_costs, f, 0) for f in body]])
                derived = substitute(ax.head, s)
                if cost < get(fact_costs, derived, Inf)
                    fact_costs[derived] = cost end
            end
        end
        # Compute costs of all effects of available actions
        actions = available(state, domain)
        for act in actions
            # Get preconditions as a disjunct of conjuctions
            preconds = get_preconditions(act, domain)
            for conj in preconds
                filter!(t -> t.name != :not, conj) # Ignore negated terms
            end
            # Compute cost of reaching each action
            cost = minimum(op(get(fact_costs, f, 0) for f in conj)
                           for conj in preconds)
            effect = get_effect(act, domain)
            additions = PDDL.get_diff(effect, state, domain).add
            # Compute cost of reaching each added fact
            cost = cost + 1
            for fact in additions
                if cost < get(fact_costs, fact, Inf)
                    fact_costs[fact] = cost end
            end
        end
        # Terminate if there's no change to the number of facts
        if length(fact_costs) == length(facts) && keys(fact_costs) == facts
            return Inf end
    end
end

"HSP heuristic where a goal's cost is the maximum cost of its dependencies."
HMax(args...) = HSP(maximum, args...)

"HSP heuristic where a goal's cost is the summed cost of its dependencies."
HAdd(args...) = HSP(sum, args...)
