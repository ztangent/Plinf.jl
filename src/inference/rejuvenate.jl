export RejuvenationKernel
export NullKernel, SequentialKernel, MixtureKernel
export ReplanKernel, ConsecutiveReplanKernel
export InitGoalKernel, RecentGoalKernel, ConsecutiveGoalKernel

"Abstract type for MCMC rejuvenation kernels."
abstract type RejuvenationKernel end

"""
    NullKernel()

Null rejuvenation kernel that always returns original trace.
"""
struct NullKernel <: RejuvenationKernel end

(kernel::NullKernel)(trace::Trace) = trace, false

"""
    SequentialKernel(subkernels...)

Composite kernel that applies each subkernel in sequential order.
"""
struct SequentialKernel{Ks <: Tuple} <: RejuvenationKernel
    subkernels::Ks
end

SequentialKernel(subkernel::Union{Function,RejuvenationKernel}) =
    SequentialKernel((subkernel,))
SequentialKernel(subkernel, subkernels...) =
    SequentialKernel((subkernel, subkernels...))


function (kernel::SequentialKernel)(trace::Trace)
    accept = false
    for k in kernel.subkernels
        trace, accept = k(trace)
    end
    return trace, accept       
end

"""
    MixtureKernel(probs::Vector{Float64}, subkernels::Tuple)

Composite kernel that applies each subkernel with a certain probability.
"""
struct MixtureKernel{Ks <: Tuple} <: RejuvenationKernel
    probs::Vector{Float64}
    subkernels::Ks
    function MixtureKernel(probs, subkernels::Ks) where {Ks <: Tuple}
        @assert length(probs) == length(subkernels)
        @assert sum(probs) ≈ 1.0
        return new{Ks}(probs, subkernels)
    end
end

MixtureKernel(probs, subkernels) =
    MixtureKernel(probs, Tuple(collect(subkernels)))
MixtureKernel(probs, k::Union{Function,RejuvenationKernel}, ks...) =
    MixtureKernel(probs, (k, ks...))

function (kernel::MixtureKernel)(trace::Trace)
    idx = categorical(kernel.probs)
    return kernel.subkernels[idx](trace)
end

"""
    ReplanKernel(n::Int=1)

Performs a single Metropolis-Hastings resimulation move on the agent's planning
steps for the past `n` steps.
"""
struct ReplanKernel <: RejuvenationKernel
    n::Int
end

ReplanKernel() = ReplanKernel(1)

function (kernel::ReplanKernel)(trace::Trace)
    n_steps = Gen.get_args(trace)[1]
    start = max(n_steps-kernel.n+1, 1)
    sel = select((:timestep => t => :agent => :plan for t in start:n_steps)...)
    return mh(trace, sel)
end

"""
    ConsecutiveReplanKernel(n::Int, order::Symbol=:forward)

Performs `n` consecutive Metropolis-Hastings resimulation moves on the agent's
planning steps. The `order` argument determines whether the moves are performed
in `:forward` (earliest first) or `:backward` order (most recent first).
"""
function ConsecutiveReplanKernel(n::Int, order::Symbol=:forward)
    @assert order in (:forward, :backward)
    if order == :forward
        subkernels = ntuple(i -> ReplanKernel(n-i+1), n)
    else
        subkernels = ntuple(i -> ReplanKernel(i), n)
    end
    return SequentialKernel(subkernels)
end

"""
    InitGoalKernel()

Perform a Metropolis-Hastings resimulation move on the agent's initial goal.
"""
struct InitGoalKernel <: RejuvenationKernel end

function (kernel::InitGoalKernel)(trace::Trace)
    # Rejuvenate goal and all downstream agent choices
    n_steps = Gen.get_args(trace)[1]
    goal_addrs = (:timestep => t => :agent => :goal for t in 1:n_steps)
    plan_addrs = (:timestep => t => :agent => :plan for t in 1:n_steps)
    sel = select(:init => :agent => :goal, goal_addrs..., plan_addrs...)
    return mh(trace, sel)
end

"""
    RecentGoalKernel(n::Int=1)

Performs Metropolis-Hastings resimulation moves on the agent's goals for the
past `n` steps.
"""
struct RecentGoalKernel <: RejuvenationKernel
    n::Int
end

RecentGoalKernel() = RecentGoalKernel(1)

function (kernel::RecentGoalKernel)(trace::Trace)
    n_steps = Gen.get_args(trace)[1]
    start = max(n_steps-kernel.n+1, 1)
    goal_addrs = (:timestep => t => :agent => :goal for t in start:n_steps)
    plan_addrs = (:timestep => t => :agent => :plan for t in start:n_steps)
    sel = select(goal_addrs..., plan_addrs...)
    return mh(trace, sel)
end

"""
    ConsecutiveGoalKernel(n::Int, order::Symbol=:forward)

Performs `n` consecutive Metropolis-Hastings resimulation moves on the agent's
goals. The `order` argument determines whether the moves are performed in
`:forward` (earliest first) or `:backward` order (most recent first).
"""
function ConsecutiveGoalKernel(n::Int, order::Symbol=:forward)
    @assert order in (:forward, :backward)
    if order == :forward
        subkernels = ntuple(i -> RecentGoalKernel(n-i+1), n)
    else
        subkernels = ntuple(i -> RecentGoalKernel(i), n)
    end
    return SequentialKernel(subkernels)
end
