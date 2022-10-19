## Interface for planning heuristics ##
export Heuristic, precompute, compute, clear_heuristic_cache!

"Cached heuristic values."
const heuristic_cache = Dict{Tuple{UInt,Symbol,UInt,UInt}, Real}()

"Clear cache of heuristic values."
clear_heuristic_cache!() = empty!(heuristic_cache)

"Abstract heuristic type, which defines the interface for planning heuristics."
abstract type Heuristic end

"Precomputes heuristic information given a domain, state, and goal."
precompute(h::Heuristic, domain::Domain, state::State, spec::Specification) =
    h # Return the heuristic unmodified by default

precompute(h::Heuristic, domain::Domain, state::State, spec) =
    precompute(h, domain, state, Specification(spec))

precompute(h::Heuristic, domain::Domain, state::State) =
    precompute(h, domain, state, NullGoal())

"Computes the heuristic value of state relative to a goal in a given domain."
compute(h::Heuristic, domain::Domain, state::State, spec::Specification) =
    error("Not implemented.")

compute(h::Heuristic, domain::Domain, state::State, spec) =
    compute(h, domain, state, Specification(spec))

"Computes the heuristic value of state relative to a goal in a given domain."
function (h::Heuristic)(domain::Domain, state::State, spec::Specification;
                        cache::Bool=true)
    if (cache)
        key = (hash(h), PDDL.get_name(domain), hash(state), hash(spec))
        if haskey(heuristic_cache, key) return heuristic_cache[key] end
    end
    val = compute(h, domain, state, spec)
    if (cache) heuristic_cache[key] = val end
    return val
end

(h::Heuristic)(domain::Domain, state::State, spec; cache::Bool=true) =
    h(domain, state, Specification(spec); cache=cache)

include("utils.jl")
include("basic.jl")
include("planner.jl")
include("hsp.jl")
include("ff.jl")
