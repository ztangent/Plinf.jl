export SIPSCallback, CombinedCallback
export PrintStatsCallback, DataLoggerCallback

import DataStructures: OrderedDict

"""
    SIPSCallback

Abstract type for callbacks to be used with the SIPS particle filter.

Callbacks are functions that are called at each timestep of the SIPS algorithm
with the signature:

    callback(t::Int, obs::ChoiceMap, pf_state::ParticleFilterState)

They can be used to perform actions such as logging, visualization, or saving
intermediate results.
"""
abstract type SIPSCallback <: Function end


"""
    CombinedCallback(callbacks::Function...; sleep=0.0)
    CombinedCallback(; name=callback, ..., sleep=0.0)

Callback that combines multiple callbacks into a single callback. Each 
constituent callback is called in order.

A `sleep` duration can be specified, in which case the callback will sleep for
up to that many seconds. If the callback takes longer than `sleep` seconds to
execute, the sleep duration is skipped.
"""
struct CombinedCallback{T <: Union{NamedTuple,Tuple}} <: SIPSCallback
    callbacks::T
    sleep::Float64
end 

function CombinedCallback(callbacks::Function...; sleep::Real = 0.0)
    return CombinedCallback(callbacks, Float64(sleep))
end

function CombinedCallback(; sleep::Real = 0.0, kwargs...)
    return CombinedCallback(values(kwargs), Float64(sleep))
end

function (cb::CombinedCallback)(t::Int, obs, pf_state)
    t_start = time()
    for callback in cb.callbacks
        callback(t, obs, pf_state)
    end
    t_elapsed = time() - t_start
    if cb.sleep > 0 && t_elapsed < cb.sleep
        sleep(cb.sleep - t_elapsed)
    end
end

Base.getindex(cb::CombinedCallback, i::Int) = cb.callbacks[i]
Base.length(cb::CombinedCallback) = length(cb.callbacks)

function Base.getproperty(cb::CombinedCallback, name::Symbol)
    if name == :callbacks
        return getfield(cb, :callbacks)
    elseif name == :sleep
        return getfield(cb, :sleep)
    elseif haskey(getfield(cb, :callbacks), name)
        return getfield(cb, :callbacks)[name]
    else
        error("Callback $name not found")
    end
end

"""
    PrintStatsCallback((addr, support)...; kwargs...)

Callback that prints statistical summaries of the distribution over values 
at each specificed address. For each address specified, the corresponding
support can be provided as a list of values, as `:discrete` (in which case
the support is inferred from the particle filter state), or as `:continuous`.

For discrete values, the callback prints the probability of each value in the
support. For continuous values, the callback prints the mean and variance of
the distribution over the address.

# Keyword Arguments

- `io::IO`: IO stream to print to. Defaults to `stdout`.
- `header::String`: Header to print before the first timestep. Defaults to
    `nothing`, in which case no header is printed.
"""
@kwdef struct PrintStatsCallback <: SIPSCallback
    io::IO = stdout
    addrs::Vector{Any} = []
    supports::Vector{Any} = fill(:discrete, length(addrs))
    header::Union{String, Nothing} = nothing
end

function PrintStatsCallback(args::Tuple{Any, Any}...; kwargs...)
    addrs = first.(collect(args))
    supports = last.(collect(args))
    return PrintStatsCallback(addrs=addrs, supports=supports; kwargs...)
end

function (cb::PrintStatsCallback)(t::Int, obs, pf_state)
    if cb.header !== nothing && t == 0
        println(cb.io, cb.header)
    end
    @printf(cb.io, "t = %d\t", t)
    for (addr, support) in zip(cb.addrs, cb.supports)
        if addr isa Function
            addr = addr(t, pf_state)
        end
        if support == :discrete || support isa AbstractVector
            # Print probabilities of each discrete value
            if support == :discrete
                probs = probvec(pf_state, addr)
            else
                probs = probvec(pf_state, addr, support)
            end
            for p in probs
                @printf(cb.io, "%0.3f\t", p)
            end
        elseif support == :continuous
            # Print mean and variance of continuous valued address
            val_mean = mean(pf_state, addr)
            val_var = var(pf_state, addr)
            @printf(cb.io, "%.3g\t%.3g", val_mean, val_var)
        end
    end
    println(cb.io)
end

"""
    DataLoggerCallback(loggers::AbstractDict; kwargs...)
    DataLoggerCallback(; name=logger..., kwargs...)

Callback that logs data from the particle filter state at each timestep, given
a dictionary mapping names to `logger` functions that extract data. Logging
functions can be defined for any of the following signatures:

    logger(t::Int, obs::ChoiceMap, pf_state::ParticleFilterState)
    logger(t::Int, pf_state::ParticleFilterState)
    logger(pf_state::ParticleFilterState)

The callback stores the data in a dictionary `cb.data` with keys given by the
names of the loggers.

# Keyword Arguments

- `verbose=false`: If `true`, print the logged data to `io` at each timestep.
- `io::IO`: IO stream to print to. Defaults to `stdout`.
"""
struct DataLoggerCallback <: SIPSCallback
    loggers::OrderedDict{Symbol, Any}
    data::Dict{Symbol, Any}
    verbose::Bool
    io::IO
end

function DataLoggerCallback(loggers::AbstractDict; verbose = false, io = stdout)
    loggers = OrderedDict{Symbol, Any}(loggers)
    # Initialize data store for each logger
    data = Dict{Symbol, Any}()
    for (name, logger) in loggers
        T = Union{Base.return_types(logger)...}
        data[name] = Vector{T}()
    end
    return DataLoggerCallback(loggers, data, verbose, io)
end

function DataLoggerCallback(;verbose = false, io = stdout, loggers...)
    loggers = OrderedDict{Symbol, Any}(pairs(loggers))
    return DataLoggerCallback(loggers; verbose=verbose, io=io)
end

function (cb::DataLoggerCallback)(t::Int, obs, pf_state)
    if cb.verbose && t == 0
        # Print header
        for (name, logger) in cb.loggers
            print(cb.io, "$name\t")
        end
        println(cb.io)
        println(cb.io)
    end
    for (name, logger) in cb.loggers
        # Log data from particle filter state
        if applicable(logger, t, obs, pf_state)
            val = logger(t, obs, pf_state)
        elseif applicable(logger, t, pf_state)
            val = logger(t, pf_state)
        elseif applicable(logger, pf_state)
            val = logger(pf_state)
        else
            error("Logger $name not applicable to arguments")
        end
        # Append data to history
        history = get!(Vector{typeof(val)}, cb.data, name)
        if eltype(history) == typeof(val)
            push!(history, val)
        else
            new_type = promote_type(eltype(history), typeof(val))
            history = collect(new_type, history)
            push!(history, val)
            cb.data[name] = history
        end
        # Print values in a single row if verbose
        if cb.verbose
            if val isa AbstractVector
                for v in val
                    if v isa Integer
                        @printf(cb.io, "%4d\t", v)
                    elseif v isa Real
                        @printf(cb.io, "%1.3f\t", v)
                    elseif v isa String
                        @printf(cb.io, "%s\t", v)
                    else
                        print(cb.io, "(object)\t")
                    end
                end
            elseif val isa Integer
                @printf(cb.io, "%4d\t", val)
            elseif val isa Real
                @printf(cb.io, "%1.3f\t", val)
            elseif val isa String
                @printf(cb.io, "%s\t", val)
            else
                print(cb.io, "(object)\t")
            end
        end
    end
    if cb.verbose
        println(cb.io)
    end
end

function Base.empty!(cb::DataLoggerCallback)
    for v in values(cb.data)
        empty!(v)
    end
    return cb
end
