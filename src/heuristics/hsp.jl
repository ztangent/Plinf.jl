## HSP family of heuristics ##
export HSPHeuristic, HAdd, HMax
export HSPRHeuristic, HAddR, HMaxR

"Precomputed domain information for HSP heuristic."
struct HSPCache
    domain::Domain # Preprocessed domain
    axioms::Vector{Clause} # Preprocessed axioms
    preconds::Dict{Symbol,Vector{Vector{Term}}} # Preconditions in DNF
    additions::Dict{Symbol,Vector{Term}} # Action add lists
end

"HSP family of delete-relaxation heuristics."
struct HSPHeuristic <: Heuristic
    op::Function # Aggregator (e.g. maximum, sum) for fact costs
    cache::Union{HSPCache,Nothing} # Precomputed domain information
    HSPHeuristic(op) = new(op, nothing)
    HSPHeuristic(op, cache) = new(op, cache)
end

Base.hash(heuristic::HSPHeuristic, h::UInt) =
    hash(heuristic.op, hash(HSPHeuristic, h))

function precompute(heuristic::HSPHeuristic,
                    domain::Domain, state::State, spec::Specification)
    # Check if cache has already been computed
    if heuristic.cache !== nothing return heuristic end
    domain = domain isa CompiledDomain ? # Make a local copy of the domain
        copy(PDDL.get_source(domain)) : copy(domain)
    # Preprocess axioms
    axioms = regularize_clauses(collect(values(domain.axioms)))
    axioms = [Clause(ax.head, [t for t in ax.body if t.name != :not])
              for ax in axioms] # Remove negative literals
    empty!(domain.axioms) # Remove axioms so they do not affect execution
    # Preprocess actions
    preconds = Dict{Symbol,Vector{Vector{Term}}}()
    additions = Dict{Symbol,Vector{Term}}()
    for (act_name, act_def) in domain.actions
        # Convert preconditions to DNF without negated literals
        conds = to_dnf(PDDL.get_precond(act_def))
        conds = [Julog.get_args(c) for c in Julog.get_args(conds)]
        for c in conds filter!(t -> t.name != :not, c) end
        preconds[act_name] = conds
        # Extract additions from each effect
        diff = effect_diff(domain, state, act_def.effect)
        additions[act_name] = diff.add
    end
    cache = HSPCache(domain, axioms, preconds, additions)
    return HSPHeuristic(heuristic.op, cache)
end

function compute(heuristic::HSPHeuristic,
                 domain::Domain, state::State, spec::Specification)
    # Precompute if necessary
    if heuristic.cache === nothing
        heuristic = precompute(heuristic, domain, state, spec) end
    @unpack op, cache = heuristic
    @unpack domain = cache
    @unpack types, facts = state
    goals = get_goal_terms(spec)
    # Initialize fact costs in a GraphPlan-style graph
    fact_costs = Dict{Term,Float64}(f => 0 for f in facts)
    while true
        facts = Set(keys(fact_costs))
        state = GenericState(types, facts, Dict{Symbol,Any}())
        if satisfy(domain, state, goals)
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
        actions = available(domain, state)
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
HMax(args...) = HSPHeuristic(maximum, args...)

"HSP heuristic where a fact's cost is the summed cost of its dependencies."
HAdd(args...) = HSPHeuristic(sum, args...)

"HSPr family of delete-relaxation heuristics for regression search."
struct HSPRHeuristic <: Heuristic
    op::Function
    fact_costs::Dict{Term,Float64} # Est. cost of reaching each fact from goal
    HSPRHeuristic(op) = new(op, Dict())
    HSPRHeuristic(op, fact_costs) = new(op, fact_costs)
end

Base.hash(heuristic::HSPRHeuristic, h::UInt) =
    hash(heuristic.op, hash(HSPRHeuristic, h))

function precompute(heuristic::HSPRHeuristic,
                    domain::Domain, state::State, spec::Specification)
    @unpack op = heuristic
    @unpack types, facts = state
    goals = get_goal_terms(spec)
    # Preprocess domain and axioms
    domain = domain isa CompiledDomain ? # Make a local copy of the domain
        copy(PDDL.get_source(domain)) : copy(domain)
    axioms = regularize_clauses(collect(values(domain.axioms)))
    axioms = [Clause(ax.head, [t for t in ax.body if t.name != :not])
              for ax in axioms]
    empty!(domain.axioms)
    # Preprocess actions
    preconds = Dict{Symbol,Vector{Vector{Term}}}()
    additions = Dict{Symbol,Vector{Term}}()
    for (act_name, act_def) in domain.actions
        # Convert preconditions to DNF without negated literals
        conds = to_dnf(PDDL.get_precond(act_def))
        conds = [Julog.get_args(c) for c in Julog.get_args(conds)]
        for c in conds filter!(t -> t.name != :not, c) end
        preconds[act_name] = conds
        # Extract additions from each effect
        diff = effect_diff(domain, state, act_def.effect)
        additions[act_name] = diff.add
    end
    # Initialize fact costs in a GraphPlan-style graph
    fact_costs = Dict{Term,Float64}(f => 0 for f in PDDL.get_facts(state))
    while true
        facts = Set(keys(fact_costs))
        state = GenericState(types, facts, Dict{Symbol,Any}())
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
        actions = available(domain, state)
        for act in actions
            act_args = domain.actions[act.name].args
            subst = Subst(var => val for (var, val) in
                          zip(act_args, Julog.get_args(act)))
            # Look-up preconds and substitute vars
            conds = preconds[act.name]
            conds = [[substitute(t, subst) for t in c] for c in conds]
            # Compute cost of reaching each action
            cost = minimum([[op([0; [get(fact_costs, f, 0) for f in conj]])
                             for conj in conds]; Inf])
            # Compute cost of reaching each added fact
            added = [substitute(a, subst) for a in additions[act.name]]
            cost = cost + 1 # TODO: Handle arbitrary action costs
            for fact in added
                if cost < get(fact_costs, fact, Inf)
                    fact_costs[fact] = cost end
            end
        end
        # Terminate when there's no change to the number of facts
        if length(fact_costs) == length(facts) && keys(fact_costs) == facts
            break end
    end
    return HSPRHeuristic(op, fact_costs)
end

function compute(heuristic::HSPRHeuristic,
                 domain::Domain, state::State, spec::Specification)
    # Precompute if necessary
    if isempty(heuristic.fact_costs)
        heuristic = precompute(heuristic, domain, state, spec) end
    @unpack op, fact_costs = heuristic
    # Compute cost of achieving all facts in current state
    return op([0; [get(fact_costs, f, 0) for f in PDDL.get_facts(state)]])
end

"HSPr heuristic where a fact's cost is the maximum cost of its dependencies."
HMaxR(args...) = HSPRHeuristic(maximum, args...)

"HSPr heuristic where a fact's cost is the summed cost of its dependencies."
HAddR(args...) = HSPRHeuristic(sum, args...)
