using Julog, PDDL
using Plots

"Convert gridworld PDDL state to array for plotting."
function state_to_array(state::State)
    width, height = state[:width], state[:height]
    array = zeros(Int64, (width, height))
    for x=1:width, y=1:height
        if state[:(wall($x, $y))] array[y, x] = 1 end
    end
    return array, (width, height)
end

"Convert PDDL plan to trajectory in a gridworld."
function plan_to_traj(plan::Vector{Term}, start::Tuple{Int,Int})
    traj = [collect(start)]
    dirs = Dict(:up => [0, 1], :down => [0, -1],
                :left => [-1, 0], :right => [1, 0])
    for act in plan
        next = traj[end] + dirs[act.name]
        push!(traj, next)
    end
    return traj
end

"Make a circle as a Plots.jl shape."
function make_circle(x::Number, y::Number, r::Number)
    pts = Plots.partialcircle(0, 2*pi, 100, r)
    xs, ys = Plots.unzip(pts)
    xs, ys = xs .+ x, ys .+ y
    return Shape(xs, ys)
end

"Render gridworld state, optionally with start, goal, and the trace of a plan."
function render!(state::State, plt::Union{Plots.Plot,Nothing}=nothing;
                 show_pos=false, start=nothing, goals=nothing, plan=nothing,
                 goal_colors=nothing)
    # Get last plot if not provided
    plt = (plt == nothing) ? plot!() : plt
    # Plot base grid
    array, (w, h) = state_to_array(state)
    plot!(plt, xticks=(collect(0:size(array)[1]+1) .- 0.5, []),
               yticks=(collect(0:size(array)[2]+1) .- 0.5, []))
    xgrid!(plt, :on, :black, 2, :dashdot, 0.75)
    ygrid!(plt, :on, :black, 2, :dashdot, 0.75)
    cmap = cgrad([RGBA(1,1,1,0), RGBA(0,0,0,1)])
    heatmap!(plt, array, aspect_ratio=1, color=cmap, colorbar_entry=false)
    # Plot start and goal positions
    if isa(start, Tuple{Int,Int})
        annotate!(start[1], start[2], Plots.text("start", 16, :red, :center))
    end
    if goals != nothing
        if isa(goals, Tuple{Int,Int}) goals = [goals] end
        if goal_colors == nothing goal_colors = fill(:blue, length(goals)) end
        for (g, col) in zip(goals, goal_colors)
            annotate!(g[1], g[2], Plots.text("goal", 16, col, :center))
        end
    end
    # Plot trace of plan
    if plan != nothing && start != nothing
        render!(plan, start, plt)
    end
    # Plot current position
    if show_pos
        x, y = state[:xpos], state[:ypos]
        circ = make_circle(x, y, 0.25)
        plot!(plt, circ, color=:black, alpha=1, legend=false)
    end
    xlims!(plt, 0.5, size(array)[1]+0.5)
    ylims!(plt, 0.5, size(array)[2]+0.5)
    return plt
end

function render(state::State; kwargs...)
    # Create new plot and render to it
    return render!(state, plot(size=(600,600), framestyle=:box); kwargs...)
end

function render!(plan::Vector{Term}, start::Tuple{Int,Int},
                 plt::Union{Plots.Plot,Nothing}=nothing;
                 alpha::Float64=0.25, color=:red, radius=0.1)
     # Get last plot if not provided
     plt = (plt == nothing) ? plot!() : plt
     traj = plan_to_traj(plan, start)
     for (x, y) in traj
         dot = make_circle(x, y, radius)
         plot!(plt, dot, color=color, alpha=alpha, legend=false)
     end
     return plt
end

function render!(traj::Vector{State}, plt::Union{Plots.Plot,Nothing}=nothing;
                 alpha::Float64=0.25, color=:red, radius=0.1)
     # Get last plot if not provided
     plt = (plt == nothing) ? plot!() : plt
     for state in traj
         x, y = state[:xpos], state[:ypos]
         dot = make_circle(x, y, radius)
         plot!(plt, dot, color=color, alpha=alpha, legend=false)
     end
     return plt
end
