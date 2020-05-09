export Heuristic, GoalCountHeuristic, ManhattanHeuristic
export HSP, HAdd, HMax
export precompute, compute

"Abstract heuristic type, which defines the interface for planners."
abstract type Heuristic end

"Precomputes heuristic information given a domain, state, and goal."
precompute(h::Heuristic, domain::Domain, state::State, goal_spec::GoalSpec) =
    h # Return the heuristic unmodified by default

"Computes the heuristic value of state relative to a goal in a given domain."
compute(h::Heuristic, domain::Domain, state::State, goal_spec::GoalSpec) =
    error("Not implemented.")

(heuristic::Heuristic)(domain::Domain, state::State, goal_spec::GoalSpec) =
    compute(heuristic, domain, state, goal_spec)

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

"HSP family of delete-relaxation heuristics (HAdd, HMax, etc.)."
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
    @unpack op, domain, axioms = heuristic
    @unpack goals = goal_spec
    # Initialize fact/action levels/costs in a GraphPlan-style graph
    fact_costs = Dict{Term,Tuple{Int,Float64}}(f => (1, 0) for f in state.facts)
    act_costs = Dict{Term,Tuple{Int,Float64}}()
    level = 1
    while true
        facts = Set(keys(fact_costs))
        state = State(facts, Dict{Symbol,Any}())
        if satisfy(goals, state, domain)[1]
            return op([fact_costs[g][2] for g in goals])
        end
        # Compute costs of one-step derivations of domain axioms
        for ax in axioms
            _, subst = resolve(ax.body, [Clause(f, []) for f in facts])
            for s in subst
                body = [substitute(t, s) for t in ax.body]
                cost = op([0; [get(fact_costs, f, (0, 0))[2] for f in body]])
                derived = substitute(ax.head, s)
                if cost < get(fact_costs, derived, (0, Inf))[2]
                    fact_costs[derived] = (level+1, cost)
                end
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
            cost = minimum(op([get(fact_costs, f, (0, 0))[2] for f in conj])
                           for conj in preconds)
            act_costs[act] = (level, cost)
            effect = get_effect(act, domain)
            additions = PDDL.get_diff(effect, state, domain).add
            # Compute cost of reaching each added fact
            cost = cost + 1
            for fact in additions
                if cost < get(fact_costs, fact, (0, Inf))[2]
                    fact_costs[fact] = (level+1, cost)
                end
            end
        end
        level += 1
        if length(fact_costs) == length(facts) && keys(fact_costs) == facts
            # Terminate if there's no change to the number of facts
            return Inf
        end
    end
end

"HSP heuristic where a goal's cost is the maximum cost of its dependencies."
HMax(args...) = HSP(maximum, args...)

"HSP heuristic where a goal's cost is the summed cost of its dependencies."
HAdd(args...) = HSP(sum, args...)
