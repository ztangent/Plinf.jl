export Heuristic, GoalCountHeuristic, ManhattanHeuristic
export HSP, HAdd, HMax, HSPR, HAddR, HMaxR
export precompute, compute, clear_heuristic_cache!

"Cached heuristic values."
const heuristic_cache = Dict{Tuple{UInt,Symbol,UInt,UInt}, Real}()

"Clear cache of heuristic values."
clear_heuristic_cache!() = empty!(heuristic_cache)

"Abstract heuristic type, which defines the interface for planners."
abstract type Heuristic end

"Precomputes heuristic information given a domain, state, and goal."
precompute(h::Heuristic, domain::Domain, state::State, goal_spec::GoalSpec) =
    h # Return the heuristic unmodified by default

precompute(h::Heuristic, domain::Domain, state::State, goal_spec) =
    precompute(h, domain, state, GoalSpec(goal_spec))

precompute(h::Heuristic, domain::Domain, state::State) =
    precompute(h, domain, state, GoalSpec(goals=Term[]))

precompute(h::Heuristic, domain::Domain) =
    precompute(h, domain, State(Term[]), GoalSpec(goals=Term[]))

"Computes the heuristic value of state relative to a goal in a given domain."
compute(h::Heuristic, domain::Domain, state::State, goal_spec::GoalSpec) =
    error("Not implemented.")

compute(h::Heuristic, domain::Domain, state::State, goal_spec) =
    compute(h, domain, state, GoalSpec(goal_spec))

function (h::Heuristic)(domain::Domain, state::State, goal_spec::GoalSpec;
                        cache::Bool=true)
    if (cache)
        key = (hash(h), domain.name, hash(state), hash(goal_spec))
        if haskey(heuristic_cache, key) return heuristic_cache[key] end
    end
    val = compute(h, domain, state, goal_spec)
    if (cache) heuristic_cache[key] = val end
    return val
end

(h::Heuristic)(domain::Domain, state::State, goal_spec; cache::Bool=true) =
    h(domain, state, GoalSpec(goal_spec); cache=cache)

"Heuristic that counts the number of goals unsatisfied in the domain."
struct GoalCountHeuristic <: Heuristic end

Base.hash(::GoalCountHeuristic, h::UInt) = hash(GoalCountHeuristic, h)

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

Base.hash(heuristic::ManhattanHeuristic, h::UInt) =
    hash(heuristic.fluents, hash(ManhattanHeuristic, h))

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

"Precomputed domain information for HSP heuristic."
struct HSPCache
    domain::Domain # Preprocessed domain
    axioms::Vector{Clause} # Preprocessed axioms
    preconds::Dict{Symbol,Vector{Vector{Term}}} # Preconditions in DNF
    additions::Dict{Symbol,Vector{Term}} # Action add lists
end

"HSP family of relaxed progression search heuristics (HAdd, HMax, etc.)."
struct HSP <: Heuristic
    op::Function # Aggregator (e.g. maximum, sum) for fact costs
    cache::HSPCache # Precomputed domain information
    HSP(op) = new(op)
    HSP(op, cache) = new(op, cache)
end

Base.hash(heuristic::HSP, h::UInt) = hash(heuristic.op, hash(HSP, h))

function precompute(heuristic::HSP,
                    domain::Domain, state::State, goal_spec::GoalSpec)
    # Check if cache has already been computed
    if isdefined(heuristic, :cache) return heuristic end
    domain = copy(domain) # Make a local copy of the domain
    # Preprocess axioms
    axioms = regularize_clauses(domain.axioms) # Regularize domain axioms
    axioms = [Clause(ax.head, [t for t in ax.body if t.name != :not])
              for ax in axioms] # Remove negative literals
    domain.axioms = Clause[] # Remove axioms so they do not affect execution
    # Preprocess actions
    preconds = Dict{Symbol,Vector{Vector{Term}}}()
    additions = Dict{Symbol,Vector{Term}}()
    for (act_name, act_def) in domain.actions
        # Convert preconditions to DNF without negated literals
        conds = get_preconditions(act_def; converter=to_dnf)
        conds = [Julog.get_args(c) for c in Julog.get_args(conds)]
        for c in conds filter!(t -> t.name != :not, c) end
        preconds[act_name] = conds
        # Extract additions from each effect
        diff = PDDL.get_diff(act_def.effect)
        additions[act_name] = diff.add
    end
    cache = HSPCache(domain, axioms, preconds, additions)
    return HSP(heuristic.op, cache)
end

function compute(heuristic::HSP,
                 domain::Domain, state::State, goal_spec::GoalSpec)
    # Precompute if necessary
    if !isdefined(heuristic, :cache)
        heuristic = precompute(heuristic, domain, state, goal_spec) end
    @unpack op, cache = heuristic
    @unpack domain = cache
    @unpack goals = goal_spec
    @unpack types, facts = state
    # Initialize fact costs in a GraphPlan-style graph
    fact_costs = Dict{Term,Float64}(f => 0 for f in facts)
    while true
        facts = Set(keys(fact_costs))
        state = State(types, facts, Dict{Symbol,Any}())
        if satisfy(goals, state, domain)[1]
            return op([0; [fact_costs[g] for g in goals]]) end
        # Compute costs of one-step derivations of domain axioms
        for ax in cache.axioms
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
            act_args = domain.actions[act.name].args
            subst = Subst(var => val for (var, val) in
                          zip(act_args, Julog.get_args(act)))
            # Look-up preconds and substitute vars
            preconds = cache.preconds[act.name]
            preconds = [[substitute(t, subst) for t in c] for c in preconds]
            # Compute cost of reaching each action
            cost = minimum([[op([0; [get(fact_costs, f, 0) for f in conj]])
                             for conj in preconds]; Inf])
            # Compute cost of reaching each added fact
            additions = [substitute(a, subst) for a in cache.additions[act.name]]
            cost = cost + 1 # TODO: Handle arbitrary action costs
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

"HSP heuristic where a fact's cost is the maximum cost of its dependencies."
HMax(args...) = HSP(maximum, args...)

"HSP heuristic where a fact's cost is the summed cost of its dependencies."
HAdd(args...) = HSP(sum, args...)

"HSPr family of relaxed regression search heuristics."
struct HSPR <: Heuristic
    op::Function
    fact_costs::Dict{Term,Float64} # Est. cost of reaching each fact from goal
    HSPR(op) = new(op)
    HSPR(op, fact_costs) = new(op, fact_costs)
end

Base.hash(heuristic::HSPR, h::UInt) = hash(heuristic.op, hash(HSPR, h))

function precompute(heuristic::HSPR,
                    domain::Domain, state::State, goal_spec::GoalSpec)
    @unpack op = heuristic
    @unpack goals = goal_spec
    @unpack types, facts = state
    # Preprocess domain and axioms
    domain = copy(domain)
    axioms = regularize_clauses(domain.axioms)
    axioms = [Clause(ax.head, [t for t in ax.body if t.name != :not])
              for ax in axioms]
    domain.axioms = Clause[]
    # Compute the set of static facts
    static_facts = reduce(vcat, [find_matches(p, state, domain) for p in
                                 get_static_predicates(domain)]; init=Term[])
    # Construct goal state from types, static facts, and goal terms
    state = State([flatten_disjs(goals); static_facts], collect(types))
    # Initialize fact costs in a GraphPlan-style graph
    fact_costs = Dict{Term,Float64}(f => 0 for f in PDDL.get_facts(state))
    while true
        facts = Set(keys(fact_costs))
        state = State(types, facts, Dict{Symbol,Any}())
        # Compute costs of axiom bodies
        for ax in axioms
            # TODO : Handle free variables in axiom body
            _, subst = resolve(ax.head, [Clause(f, []) for f in facts])
            for s in subst
                head = substitute(ax.head, s)
                body = [substitute(t, s) for t in ax.body]
                cost = get(fact_costs, head, 0)
                for term in body
                    if is_ground(term) && cost < get(fact_costs, term, Inf)
                        fact_costs[term] = cost end
                end
            end
        end
        # Compute costs of all preconditions of relevant actions
        actions = relevant(state, domain)
        for act in actions
            # Compute cost of achieving relevant additions of each action
            effect = get_effect(act, domain)
            additions = PDDL.get_diff(effect).add
            cost = op([0; [get(fact_costs, f, 0) for f in additions]])
            # Get preconditions of action
            preconds = reduce(vcat, get_preconditions(act, domain))
            filter!(t -> t.name != :not, preconds) # Ignore negated terms
            # Update cost of reaching each positive precondition
            cost = cost + 1 # TODO : Handle arbitrary action costs
            for fact in preconds
                if cost < get(fact_costs, fact, Inf)
                    fact_costs[fact] = cost end
            end
        end
        # Terminate when there's no change to the number of facts
        if length(fact_costs) == length(facts) && keys(fact_costs) == facts
            break end
    end
    return HSPR(op, fact_costs)
end

function compute(heuristic::HSPR,
                 domain::Domain, state::State, goal_spec::GoalSpec)
    # Precompute if necessary
    if !isdefined(heuristic, :fact_costs)
        heuristic = precompute(heuristic, domain, state, goal_spec) end
    @unpack op, fact_costs = heuristic
    # Compute cost of achieving all facts in current state
    return op([0; [get(fact_costs, f, 0) for f in PDDL.get_facts(state)]])
end

"HSPr heuristic where a fact's cost is the maximum cost of its dependencies."
HMaxR(args...) = HSPR(maximum, args...)

"HSPr heuristic where a fact's cost is the summed cost of its dependencies."
HAddR(args...) = HSPR(sum, args...)
