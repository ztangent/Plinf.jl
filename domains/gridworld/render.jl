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
        next = traj[end] + get(dirs, act.name, [0, 0])
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
        if goal_colors == nothing goal_colors = cgrad(:plasma)[1:3:30] end
        for (g, col) in zip(goals, goal_colors)
            annotate!(g[1], g[2], Plots.text("goal", 16, col, :center))
        end
    end
    # Plot trace of plan
    if (plan != nothing && start != nothing) render!(plan, start, plt) end
    # Plot current position
    if show_pos render_pos!(state, plt) end
    # Resize limits
    xlims!(plt, 0.5, size(array)[1]+0.5)
    ylims!(plt, 0.5, size(array)[2]+0.5)
    return plt
end

function render_pos!(state::State, plt::Union{Plots.Plot,Nothing}=nothing;
                     radius=0.25, color=:black, args...)
    plt = (plt == nothing) ? plot!() : plt
    x, y = state[:xpos], state[:ypos]
    circ = make_circle(x, y, radius)
    plot!(plt, circ, color=color, alpha=1, legend=false)
end

function render(state::State; kwargs...)
    # Create new plot and render to it
    return render!(state, plot(size=(600,600), framestyle=:box); kwargs...)
end

function render!(plan::Vector{Term}, start::Tuple{Int,Int},
                 plt::Union{Plots.Plot,Nothing}=nothing;
                 alpha::Float64=0.50, color=:red, radius=0.1)
     # Get last plot if not provided
     plt = (plt == nothing) ? plot!() : plt
     traj = plan_to_traj(plan, start)
     for (x, y) in traj
         dot = make_circle(x, y, radius)
         plot!(plt, dot, color=color, linealpha=0, alpha=alpha, legend=false)
     end
     return plt
end

function render!(traj::Vector{State}, plt::Union{Plots.Plot,Nothing}=nothing;
                 alpha::Float64=0.50, color=:red, radius=0.1)
     # Get last plot if not provided
     plt = (plt == nothing) ? plot!() : plt
     for state in traj
         x, y = state[:xpos], state[:ypos]
         dot = make_circle(x, y, radius)
         plot!(plt, dot, color=color, linealpha=0, alpha=alpha, legend=false)
     end
     return plt
end

"Render trajectories for each (weighted) trace"
function render_traces!(traces, weights=nothing, plt=nothing;
                        goal_colors=cgrad(:plasma)[1:3:30], max_alpha=0.75,
                        args...)
    weights = weights == nothing ? lognorm(get_score.(traces)) : weights
    for (tr, w) in zip(traces, weights)
        traj = get_retval(tr)
        color = goal_colors[tr[:goal]]
        render!(traj; alpha=max_alpha*exp(w), color=color, radius=0.175)
    end
end

"Callback render function for particle filter."
function render_pf!(t::Int, state, traces, weights;
                    plt=nothing, animation=nothing, show=true, plot_probs=false,
                    pos_args=Dict(), tr_args=Dict(), probs_args=Dict(),
                    shared_args...)
    # Get last plot if not provided
    plt = deepcopy((plt == nothing) ? plot!() : plt)
    # Render agent's current position
    render_pos!(state, plt; pos_args..., shared_args...)
    # Render predicted trajectories
    render_traces!(traces, weights, plt; tr_args..., shared_args...)
    if plot_probs # Graph goal probabilities
        goal_names = get(probs_args, :goal_names,
                         get(shared_args, :goal_names, []))
        goal_idxs = collect(1:length(goal_names))
        goal_probs = get_goal_probs(traces, weights, goal_idxs)
        probs_plt = plot_goal_probs!(goal_probs; t=t,
                                     probs_args..., shared_args...)
        full_plt = plot(plt, probs_plt, layout=(1, 2),
                        size=(1200, 600), margin=10*Plots.mm)
    end
    title!(full_plt, "t = $t") # Display current timestep
    if show display(full_plt) end
    if animation != nothing frame(animation) end # Save frame to animation
end

"Plot goal probabilities."
function plot_goal_probs!(goal_probs; plt=nothing, style=:bar, t=0,
                          goal_names=nothing, goal_colors=cgrad(:plasma)[1:3:30])
    if isa(goal_probs, Dict)
        goal_probs = sort(goal_probs)
        if goal_names == nothing goal_names = collect(keys(goal_probs)) end
        goal_probs = collect(values(goal_probs))
    else
        if goal_names == nothing goal_names = collect(1:length(goal_probs)) end
    end
    plt = (plt == nothing) ?
        plot(size=(600,600), framestyle=:grid, margin=4*Plots.mm) : plt
    goal_colors = goal_colors[1:length(goal_probs)]
    if style == :bar
        plt = bar!(plt, goal_names, goal_probs; legend=false,
                   color=goal_colors, xlabel="Goals", ylabel="Probability",
                   guidefontsize=16, tickfontsize=14)
        ylims!(plt, (0.0, 1.0))
    end
    return plt
end
