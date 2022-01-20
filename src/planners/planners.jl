## Abstract interface for planners ##
export Planner
export set_max_resource, get_call, get_proposal
export sample_plan, propose_plan
export clear_action_cache!

"Abstract planner type, which defines the interface for planners."
abstract type Planner end

"Call planner without tracing internal random choices."
(planner::Planner)(domain::Domain, state::State, spec::Specification) =
    get_call(planner)(planner, domain, state, spec)

(planner::Planner)(domain::Domain, state::State, goals::Vector{<:Term}) =
    get_call(planner)(planner, domain, state, Specification(goals))

(planner::Planner)(domain::Domain, state::State, goal::Term) =
    get_call(planner)(planner, domain, state, Specification(goal))

"Clears cache of action successors."
clear_action_cache!(::Planner) = nothing

"Return copy of the planner with adjusted resource bound."
set_max_resource(planner::Planner, val) = planner

"Returns the generative function that defines the planning algorithm."
get_call(::Planner)::GenerativeFunction = planner_call

"Returns the data-driven proposal associated with the planning algorithm."
get_proposal(::Planner)::GenerativeFunction = planner_propose

"Abstract planner call template, to be implemented by concrete planners."
@gen function planner_call(planner::Planner,
                           domain::Domain, state::State, spec::Specification)
    error("Not implemented.")
    return plan, traj
end

"Default data-driven proposal to the planner's internal random choices."
@gen function planner_propose(planner::Planner,
                              domain::Domain, state::State, spec::Specification,
                              obs_states::Vector{<:Union{State,Nothing}})
    call = get_call(planner) # Default to proposing from the prior
    return @trace(call(planner, domain, state, spec))
end

"Sample a plan given a planner, domain, initial state and goal specification."
@gen function sample_plan(planner::Planner,
                          domain::Domain, state::State, spec)
    spec = isa(spec, Specification) ? spec : Specification(spec)
    call = get_call(planner)
    return @trace(call(planner, domain, state, spec))
end

"Propose a plan given a planner and a sequence of observed states."
@gen function propose_plan(planner::Planner,
                           domain::Domain, state::State, spec,
                           obs_states::Vector{<:Union{State,Nothing}})
    spec = isa(spec, Specification) ? spec : Specification(spec)
    proposal = get_proposal(planner)
    return @trace(proposal(planner, domain, state, spec, obs_states))
end

include("stepwise.jl")
include("replanners.jl")
include("common.jl")
include("astar.jl")
include("bfs.jl")
include("backward.jl")
include("rtdp.jl")
include("external.jl")
