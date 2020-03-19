using Julog, PDDL
using Plots

"Convert PDDL state to array of wall locations."
function state_to_array(state::State)
    width, height = state[:width], state[:height]
    array = zeros(Int64, (width, height))
    for x=1:width, y=1:height
        if state[:(wall($x, $y))] array[y, x] = 2
        elseif state[:(door($x, $y))] array[y, x] = 1 end
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
function make_circle(x::Real, y::Real, r::Real)
    pts = Plots.partialcircle(0, 2*pi, 100, r)
    xs, ys = Plots.unzip(pts)
    xs, ys = xs .+ x, ys .+ y
    return Shape(xs, ys)
end

"Make a gem using Plots.jl shapes."
function make_gem(x::Real, y::Real, scale::Real)
    inner = Shape(:hexagon)
    inner = Plots.scale!(Plots.translate!(inner, x, y), scale*0.45, scale*0.6)
    outer = Shape(:hexagon)
    outer = Plots.scale!(Plots.translate!(outer, x, y), scale*0.75, scale)
    return [outer, inner]
end

"Make a key using Plots.jl shapes."
function make_key(x::Real, y::Real, scale::Real)
    handle = Plots.translate!(Plots.scale!(Shape(:circle), 0.4, 0.4), -0.6, 0)
    blade = Plots.scale!(Shape(:rect), 1.0, 0.2)
    tooth1 = Plots.translate!(Plots.scale!(Shape(:rect), 0.1, 0.2), 0.35, -0.2)
    tooth2 = Plots.translate!(Plots.scale!(Shape(:rect), 0.1, 0.2), 0.55, -0.2)
    return [Plots.translate!(Plots.scale!(s, scale, scale, (0, 0)), x, y)
            for s in [handle, blade, tooth1, tooth2]]
end

"Plot agent's current location."
function render_pos!(state::State, plt::Union{Plots.Plot,Nothing}=nothing;
                     radius=0.25, color=:black)
    plt = (plt == nothing) ? plot!() : plt
    x, y = state[:xpos], state[:ypos]
    circ = make_circle(x, y, radius)
    plot!(plt, circ, color=color, alpha=1, legend=false)
end

"Plot a gem with the given position, scale and color."
function render_gem!(x::Real, y::Real, scale::Real, color,
                     plt::Union{Plots.Plot,Nothing}=nothing)
    plt = (plt == nothing) ? plot!() : plt
    outer, inner = make_gem(x, y, scale)
    color = isa(color, Symbol) ? HSV(Colors.parse(Colorant, color)) : HSV(color)
    inner_col = HSV(color.h, 0.6*color.s, min(1.5*color.v, 1))
    plot!(plt, [outer, inner], color=[color, inner_col],
          alpha=1, linealpha=[1, 0], legend=false)
end

"Plot a key with the given position and scale."
function render_key!(x::Real, y::Real, scale::Real,
                     plt::Union{Plots.Plot,Nothing}=nothing)
    plt = (plt == nothing) ? plot!() : plt
    key = make_key(x, y, scale)
    shadow = make_key(x+0.05*scale, y-0.05*scale, scale)
    plot!(plt, [shadow; key], alpha=1, linealpha=0, legend=false,
          color=[fill(:black, 4); fill(:goldenrod1, 4)])
end


"Render gridworld state, optionally with start, goal, and the trace of a plan."
function render!(state::State, plt::Union{Plots.Plot,Nothing}=nothing;
                 show_pos=false, start=nothing, plan=nothing,
                 gem_colors=cgrad(:plasma)[1:3:30])
    # Get last plot if not provided
    plt = (plt == nothing) ? plot!() : plt
    # Plot base grid
    array, (w, h) = state_to_array(state)
    plot!(plt, xticks=(collect(0:size(array)[1]+1) .- 0.5, []),
               yticks=(collect(0:size(array)[2]+1) .- 0.5, []))
    xgrid!(plt, :on, :black, 2, :dashdot, 0.75)
    ygrid!(plt, :on, :black, 2, :dashdot, 0.75)
    cmap = cgrad([RGBA(1,1,1,0), RGBA(0.5,0.5,0.5,1), RGBA(0,0,0,1)])
    heatmap!(plt, array, aspect_ratio=1, color=cmap, colorbar_entry=false)
    # Plot start position
    if isa(start, Tuple{Int,Int})
        annotate!(start[1], start[2], Plots.text("start", 16, :red, :center))
    end
    # Plot gems
    _, gem_subst = satisfy(@julog([at(G, X, Y), gem(G)]), state; mode=:all)
    gem_locs = [(s[@julog(X)].name, s[@julog(Y)].name) for s in gem_subst]
    for (g, col) in zip(gem_locs, gem_colors)
        render_gem!(g[1], g[2], 0.3, col, plt)
    end
    # Plot keys
    _, key_subst = satisfy(@julog([at(K, X, Y), key(K)]), state; mode=:all)
    key_locs = [(s[@julog(X)].name, s[@julog(Y)].name) for s in key_subst]
    for k in key_locs
        render_key!(k[1], k[2], 0.4, plt)
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
function render_traces!(traces, weights=nothing,
                        plt::Union{Plots.Plot,Nothing}=nothing;
                        goal_colors=cgrad(:plasma)[1:3:30], max_alpha=0.75)
    weights = weights == nothing ? lognorm(get_score.(traces)) : weights
    for (tr, w) in zip(traces, weights)
        traj = get_retval(tr)
        color = goal_colors[tr[:goal]]
        render!(traj; alpha=max_alpha*exp(w), color=color, radius=0.175)
    end
end

"Callback render function for particle filter."
function render_pf!(t::Int, state, traces, weights;
                    plt=nothing, animation=nothing, show=true,
                    pos_args=Dict(), tr_args=Dict())
    plt = deepcopy((plt == nothing) ? plot!() : plt) # Get last plot if not provided
    render_pos!(state, plt; pos_args...) # Render agent's current position
    render_traces!(traces, weights, plt; tr_args...) # Render predicted trajectories
    title!("t = $t") # Display current timestep
    if show display(plt) end
    if animation != nothing frame(animation) end # Save frame to animation
end
