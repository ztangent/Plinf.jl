using Julog, PDDL, Plots
using DataStructures: OrderedDict

## Utility functions ##

"Convert PDDL state to array of wall locations."
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

## Object rendering functions ##

"Make a circle as a Plots.jl shape."
function make_circle(x::Real, y::Real, r::Real)
    pts = Plots.partialcircle(0, 2*pi, 100, r)
    xs, ys = Plots.unzip(pts)
    xs, ys = xs .+ x, ys .+ y
    return Shape(xs, ys)
end

"Make a circle as a Plots.jl shape."
function make_triangle(x::Real, y::Real, r::Real, dir::Symbol)
    trimap = Dict(:up => :utriangle, :down => :dtriangle,
                  :right => :rtriangle, :left => :ltriangle)
    triangle = Shape(trimap[dir])
    triangle = Plots.translate!(Plots.scale!(triangle, r, r), x, y)
    return triangle
end

"Make a door using Plots.jl shapes."
function make_door(x::Real, y::Real, scale::Real)
    bg = Plots.scale!(Shape(:rect), 1.0, 1.0)
    fg = Plots.scale!(Shape(:rect), 0.85, 0.85)
    hole1 = Plots.translate!(Plots.scale!(Shape(:circle), 0.13, 0.13), 0, 0.15)
    hole2 = Plots.translate!(Plots.scale!(Shape(:utriangle), 0.15, 0.3), 0, -0.1)
    return [Plots.translate!(Plots.scale!(s, scale, scale, (0, 0)), x, y)
            for s in [bg, fg, hole1, hole2]]
end

"Plot a door with the given position and scale."
function render_door!(x::Real, y::Real, scale::Real; color=:gray, alpha=1,
                      plt=nothing)
    plt = (plt == nothing) ? plot!() : plt
    color = isa(color, Symbol) ? HSV(Colors.parse(Colorant, color)) : HSV(color)
    inner_col = HSV(color.h, 0.8*color.s, min(1.25*color.v, 1))
    door = make_door(x, y, scale)
    plot!(plt, door, alpha=alpha, linealpha=[0, 1, 0, 0], legend=false,
          color=[color, inner_col, :black, :black])
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

"Plot a key with the given position and scale."
function render_key!(x::Real, y::Real, scale::Real; color=:goldenrod1, alpha=1,
                     plt=nothing)
    plt = (plt == nothing) ? plot!() : plt
    key = make_key(x, y, scale)
    shadow = make_key(x+0.05*scale, y-0.05*scale, scale)
    plot!(plt, [shadow; key], alpha=alpha, linealpha=0, legend=false,
          color=[fill(:black, 4); fill(color, 4)])
end

"Make a gem using Plots.jl shapes."
function make_gem(x::Real, y::Real, scale::Real)
    inner = Shape(:hexagon)
    inner = Plots.scale!(Plots.translate!(inner, x, y), scale*0.45, scale*0.6)
    outer = Shape(:hexagon)
    outer = Plots.scale!(Plots.translate!(outer, x, y), scale*0.75, scale)
    return [outer, inner]
end

"Plot a gem with the given position, scale and color."
function render_gem!(x::Real, y::Real, scale::Real; color=:magenta, alpha=1,
                     plt=nothing)
    plt = (plt == nothing) ? plot!() : plt
    outer, inner = make_gem(x, y, scale)
    color = isa(color, Symbol) ? HSV(Colors.parse(Colorant, color)) : HSV(color)
    inner_col = HSV(color.h, 0.6*color.s, min(1.5*color.v, 1))
    plot!(plt, [outer, inner], color=[color, inner_col],
          alpha=alpha, linealpha=[1, 0], legend=false)
end

## Gridworld rendering functions ##

"Plot agent's current location."
function render_pos!(state::State, plt=nothing;
                     radius=0.25, color=:red, alpha=1, dir=nothing, kwargs...)
    plt = (plt == nothing) ? plot!() : plt
    x, y = state[:xpos], state[:ypos]
    if dir in [:up, :down, :right, :left]
        marker = make_triangle(x, y, radius*1.5, dir)
        xscale, yscale = (dir in [:up, :down]) ? (0.8, 1.0) : (1.0, 0.8)
        Plots.scale!(marker, xscale, yscale)
    else
        marker = make_circle(x, y, radius)
    end
    plot!(plt, marker, color=color, alpha=alpha, linealpha=0, legend=false)
end

"Render doors, keys and gems present in the given state."
function render_objects!(state::State, plt=nothing;
                         gem_colors=cgrad(:plasma)[1:3:30], kwargs...)
    obj_queries =
        @julog [door(X, Y), and(key(O), at(O, X, Y)), and(gem(O), at(O, X, Y))]
    obj_colors = [:gray, :goldenrod1, gem_colors]
    obj_renderers = [
        (l, c) -> render_door!(l[1], l[2], 0.7, plt=plt),
        (l, c) -> render_key!(l[1], l[2], 0.4, plt=plt),
        (l, c) -> render_gem!(l[1], l[2], 0.3, color=c, plt=plt)
    ]
    for (query, colors, rndr!) in zip(obj_queries, obj_colors, obj_renderers)
        _, subst = satisfy(query, state; mode=:all)
        sort!(subst, by=s->get(s, @julog(O), Const(0)).name)
        locs = [(s[@julog(X)].name, s[@julog(Y)].name) for s in subst]
        if isa(colors, AbstractDict)
            obj_terms = [s[@julog(O)] for s in subst]
            colors = [colors[o] for o in obj_terms]
        elseif !isa(colors, AbstractArray)
            colors = fill(colors, length(locs))
        end
        for (loc, col) in zip(locs, colors) rndr!(loc, col) end
    end
    return plt
end

"Render agent inventory as a bar below the gridworld."
function render_inventory!(state::State, plt=nothing;
                           gem_colors=cgrad(:plasma)[1:3:30], kwargs...)
    if (plt == nothing)
        plt = plot(size=(600,100), framestyle=:box, aspect_ratio=1, grid=true,
                   margin=0*Plots.mm, top_margin=2*Plots.mm)
    end
    obj_queries = @julog [and(key(O), has(O)), and(gem(O), has(O))]
    obj_colors = [:goldenrod1, gem_colors]
    obj_renderers = [
        (l, c) -> render_key!(l[1], l[2], 0.4, plt=plt),
        (l, c) -> render_gem!(l[1], l[2], 0.3, color=c, plt=plt)
    ]
    for (query, colors, rndr!) in zip(obj_queries, obj_colors, obj_renderers)
        _, subst = satisfy(query, state; mode=:all)
        sort!(subst, by=s->get(s, @julog(O), Const(0)).name)
        if isa(colors, AbstractDict)
            obj_terms = [s[@julog(O)] for s in subst]
            colors = [colors[o] for o in obj_terms]
        elseif !isa(colors, AbstractArray)
            colors = fill(colors, length(subst))
        end
        for (i, col) in enumerate(colors) rndr!((i, 0.5), col) end
    end
    plot!(plt, xticks=(collect(0:state[:width]+1) .- 0.5, []),
               yticks=([0, 1.0], []))
    xgrid!(plt, :on, :black, 1, :dash, 0.75)
    annotate!(0.5, 1.25, Plots.text("Inventory", 12, :black, :left))
    xlims!(plt, 0.5, state[:width]+0.5)
    ylims!(plt, 0, 1)
    return plt
end

"Render state, optionally with start position and the trace of a plan."
function render!(state::State, plt=nothing; start=nothing, plan=nothing,
                 show_pos=false, show_objs=true, show_inventory=false,
                 gem_colors=cgrad(:plasma)[1:3:30], kwargs...)
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
    # Plot start position
    if isa(start, Tuple{Int,Int})
        annotate!(start[1], start[2], Plots.text("start", 16, :red, :center))
    end
    # Plot objects
    if show_objs render_objects!(state, plt; gem_colors=gem_colors) end
    # Plot trace of plan
    if (plan != nothing && start != nothing) render!(plan, start, plt) end
    # Plot current position
    if show_pos render_pos!(state, plt) end
    # Resize limits
    xlims!(plt, 0.5, size(array)[1]+0.5)
    ylims!(plt, 0.5, size(array)[2]+0.5)
    if show_inventory
        i_plt = render_inventory!(state; gem_colors=gem_colors)
        sz = [plt[:size][1], plt[:size][2] + i_plt[:size][2]]
        plt = plot(plt, i_plt; size=sz, layout=grid(2,1, heights=[0.9, 0.1]))
    end
    return plt
end

function render(state::State; kwargs...)
    # Create new plot and render to it
    return render!(state, plot(size=(600,600), framestyle=:box); kwargs...)
end

function render!(plan::Vector{Term}, start::Tuple{Int,Int}, plt=nothing;
                 alpha::Float64=1.0, color=:red, radius=0.1,
                 fade=false, trunc=nothing, kwargs...)
    # Get last plot if not provided
    plt = (plt == nothing) ? plot!() : plt
    traj = plan_to_traj(plan, start)
    if trunc != nothing && length(plan) >= trunc
        plan, traj = plan[end-trunc+1:end], traj[end-trunc:end-1] end
    i_alpha = fade ? 0.0 : alpha
    for (act, (x, y)) in zip(plan, traj)
        if fade i_alpha += alpha / length(plan) end
        if (act.name in [:up, :down, :right, :left])
            marker = make_triangle(x, y, radius*1.5, act.name)
        else
            marker = make_circle(x, y, radius)
        end
        plot!(plt, marker, color=color, la=0, alpha=i_alpha, legend=false)
    end
    return plt
end

function render!(traj::Vector{State}, plt=nothing;
                 alpha::Float64=0.50, color=:red, radius=0.1, kwargs...)
     # Get last plot if not provided
     plt = (plt == nothing) ? plot!() : plt
     for state in traj
         x, y = state[:xpos], state[:ypos]
         dot = make_circle(x, y, radius)
         plot!(plt, dot, color=color, linealpha=0, alpha=alpha, legend=false)
     end
     return plt
end

function render!(pts::Vector{Tuple{Int,Int}}, plt=nothing;
                 alphas=[0.50], color=:red, radius=0.1, kwargs...)
     # Get last plot if not provided
     plt = (plt == nothing) ? plot!() : plt
     for (i, (x, y)) in enumerate(pts)
         alpha = alphas[min(i, length(alphas))]
         dot = make_circle(x, y, radius)
         plot!(plt, dot, color=color, linealpha=0, alpha=alpha, legend=false)
     end
     return plt
end

"Render planned trajectories for each (weighted) trace of the world model."
function render_traces!(traces, weights=nothing, plt=nothing;
                        goal_colors=cgrad(:plasma)[1:3:30], max_alpha=0.60,
                        trace_future=false, kwargs...)
    weights = weights == nothing ? lognorm(get_score.(traces)) : weights
    pt_weights = Dict{Int,Dict{Tuple{Int,Int},Float64}}()
    for (tr, w) in zip(traces, weights)
        goal_idx = tr[:goal_init => :goal]
        goal_pt_weights = get!(pt_weights, goal_idx,
                               Dict{Tuple{Int,Int},Float64}())
        world_traj = get_retval(tr)
        plan_traj = [ws.plan_state for ws in world_traj]
        env_traj = extract_traj(plan_traj)
        if trace_future
            t_cur = length(world_traj)
            env_traj = env_traj[min(length(env_traj), t_cur+1):end]
        end
        for state in env_traj
            pt = (state[:xpos], state[:ypos])
            goal_pt_weights[pt] = get(goal_pt_weights, pt, 0.0) + exp(w)
        end
    end
    for (goal_idx, pt_ws) in pt_weights
        color = goal_colors[goal_idx]
        pts, ws = collect(keys(pt_ws)), collect(values(pt_ws))
        alphas = max_alpha .* ws
        render!(pts; alphas=alphas, color=color, radius=0.175)
    end
end

## Gridworld animation functions ##

"Render animation of state trajectory/ies."
function anim_traj(traj::AbstractVector{State}, canvas=nothing, animation=nothing;
                   show=true, fps=3, show_objs=true, show_inventory=true,
                   plan=nothing, start_pos=nothing, start_dir=nothing,
                   splitpoints=Int[], kwargs...)
    canvas = canvas == nothing ?
        render(traj[1]; show_objs=false, kwargs...) : canvas
    animation = animation == nothing ? Animation() : animation
    splitflag = length(splitpoints) > 0
    splitanims, splitpoints = Animation[], collect(splitpoints)
    dir = start_dir
    for (t, state) in enumerate(traj)
        plt = deepcopy(canvas)
        if !isnothing(plan) # Render past actions if provided
            part_plan = plan[1:max(1,min(t-1, length(plan)))]
            render!(part_plan, start_pos, plt; fade=true, trunc=6, color=:black)
            i = findlast(a -> a.name in [:up, :down, :left, :right, :unlock],
                         part_plan)
            dir = i == nothing ? start_dir : part_plan[i].name
            if (dir == :unlock) dir = part_plan[i].args[2].name end
        end
        render_pos!(state, plt; dir=dir, kwargs...) # Render position
        if show_objs # Render objcets
            render_objects!(state, plt; kwargs...) end
        if show_inventory # Render inventory
            i_plt = render_inventory!(state; kwargs...)
            sz = [plt[:size][1], plt[:size][2] + i_plt[:size][2]]
            plt = plot(plt, i_plt; size=sz,
                       layout=grid(2,1, heights=[0.9, 0.1]))
        end
        frame(animation)
        if length(splitpoints) > 0 && t >= splitpoints[1]
            # Split animation if split points are given
            push!(splitanims, animation)
            if t < length(traj) animation = Animation() end
            popfirst!(splitpoints)
        end
    end
    if splitflag && length(animation.frames) > 0
        push!(splitanims, animation) end
    if show
        display(gif(animation; fps=fps)) end
    return length(splitanims) > 0 ? splitanims : animation
end

"Render animation of multiple state trajectories."
function anim_traj(trajs, canvas=nothing, animation=nothing;
                   show=true, fps=3, show_objs=true, show_inventory=true,
                   kwargs...)
    canvas = canvas == nothing ?
        render(trajs[1][1]; show_objs=false, kwargs...) : canvas
    animation = animation == nothing ? Animation() : animation
    for t in 1:maximum(length.(trajs))
        plt = deepcopy(canvas)
        for traj in trajs
            state = t <= length(traj) ? traj[t] : traj[end]
            render_pos!(state, plt; kwargs...)
            if show_objs render_objects!(state, plt; kwargs...) end
        end
        frame(animation)
    end
    if show display(gif(animation; fps=fps)) end
    return animation
end

"Animate planner node expansions during tree search."
function anim_plan(trace, canvas, animation=nothing; show=true, fps=10,
                   node_radius=0.1, search_color=:red, search_alpha=0.3,
                   plan_color=:blue, plan_alpha=0.5, kwargs...)
    plt = deepcopy(canvas)
    animation = animation == nothing ? Animation() : animation
    node_choices = OrderedDict(get_values_shallow(get_choices(trace)))
    sort!(filter!(p -> p[1][1] == :state, node_choices))
    # Render each node expanded in sequence
    for state in values(node_choices)
        dot = make_circle(state[:xpos], state[:ypos], node_radius)
        plt = plot!(plt, dot, color=search_color, alpha=search_alpha,
                    linealpha=0, legend=false)
        frame(animation, plt)
    end
    # Render final plan
    plan, traj = get_retval(trace)
    plt = render!(traj, plt; alpha=plan_alpha,
                  color=plan_color, radius=node_radius*1.5)
    if show display(plt) end
    frame(animation, plt)
    frame(animation, plt)
    if show display(gif(animation; fps=fps)) end
    return animation
end

"Animate interleaved search and execution of a replanner."
function anim_replan(trace, canvas, animation=nothing;
                     show=true, fps=10, kwargs...)
    animation = animation == nothing ? Animation() : animation
    # Iterate over time steps
    choices = get_submap(get_choices(trace), :timestep)
    step_submaps = sort!(OrderedDict(get_submaps_shallow(choices)))
    for (addr, submap) in step_submaps
        # Get subtrace for this step
        addr = :timestep => addr => :plan
        step_trace = Gen.get_call(trace, addr).subtrace
        # Skip steps where no new plans were made
        if !Gen.has_call(step_trace, :subplan) continue end
        plan_trace = Gen.get_call(step_trace, :subplan).subtrace
        # Render agent's position
        _, _, state, _ = Gen.get_args(plan_trace)
        plt = render_pos!(state, deepcopy(canvas); alpha=0.5, kwargs...)
        # Render subtrace corresponding to base planner
        animation = anim_plan(plan_trace, plt, animation; show=false, kwargs...)
        # Animate trajectory over most recent plot
        plt = plot!()
        plan, traj = get_retval(plan_trace)
        animation = anim_traj(traj, plt, animation; show=false, kwargs...)
    end
    if show display(gif(animation; fps=fps)) end
    return animation
end

## Diagnostic and statistic plotters ##

"Make default plot canvas with appropriate size and margin."
plot_canvas() = plot(size=(600,600), framestyle=:box, margin=4*Plots.mm)

"""Plot goal probabilities at a particular timestep as a bar chart.
`goal_probs` should be a dictionary or array of goal probabilities."""
function plot_goal_bars!(goal_probs, goal_names=nothing,
                         goal_colors=cgrad(:plasma)[1:3:30]; plt=nothing)
    # Construct new plot if not provided
    if (plt == nothing) plt = plot_canvas() end
    # Extract goal names and probabilities
    if isa(goal_probs, AbstractDict)
        goal_probs = sort!(OrderedDict(goal_probs))
        if goal_names == nothing goal_names = collect(keys(goal_probs)) end
        goal_probs = collect(values(goal_probs))
    elseif goal_names == nothing
        goal_names = collect(1:length(goal_probs))
    end
    goal_colors = goal_colors[1:length(goal_probs)]
    # Plot bar chart
    plt = bar!(plt, goal_names, goal_probs; color=goal_colors, legend=false,
               ylims=(0.0, 1.0), xlabel="Goals", ylabel="Probability",
               guidefontsize=16, tickfontsize=14)
    ylims!(plt, (0.0, 1.0))
    return plt
end

"""Plot goal probabilities over time as a line graph.
`goal_probs` should be a 2D array of goal probabilities over time."""
function plot_goal_lines!(goal_probs, goal_names=nothing,
                          goal_colors=cgrad(:plasma)[1:3:30];
                          timesteps=nothing, plt=nothing)
    # Construct new plot if not provided
    if (plt == nothing) plt = plot_canvas() end
    # Set default goal names and timesteps
    if (goal_names == nothing)
        goal_names = ["Goal $i" for i in 1:size(goal_probs, 1)] end
    if (timesteps == nothing)
        timesteps = collect(1:size(goal_probs, 2)) end
    # Plot line graph, one series per goal
    plt = plot!(plt, timesteps, goal_probs'; linewidth=6,
                legend=:topright, legendtitle="Goals",
                fg_legend=:transparent, bg_legend=:transparent,
                labels=permutedims(goal_names), color=permutedims(goal_colors),
                ylims=(0.0, 1.0), xlabel="Time", ylabel="Probability",
                guidefontsize=16, tickfontsize=14)
    return plt
end

"Plot histogram of particle weights."
function plot_particle_weights!(weights; plt=nothing)
    # Construct new plot if not provided
    if (plt == nothing) plt = plot_canvas() end
    # Plot histogram
    weights = exp.(weights)
    plt = histogram!(plt, weights; normalize=:probability, legend=false,
                     xlabel="Particle Weights", ylabel="Frequency",
                     guidefontsize=16, tickfontsize=14)
end

"Plot histogram of partial plan lengths."
function plot_plan_lengths!(traces, weights; plt=nothing)
    # Construct new plot if not provided
    if (plt == nothing) plt = plot_canvas() end
    # Get plan lengths from traces
    plan_lengths = map(traces) do tr
        world_states = get_retval(tr)
        plan_states = [ws.plan_state for ws in world_states]
        if isa(plan_states[end], Plinf.ReplanState)
            _, rp = Plinf.get_last_planning_step(plan_states)
            return length(rp.part_plan)
        elseif isa(plan_states[end], Plinf.PlanState)
            return length(plan_states[end].plan)
        else
            return 0
        end
    end
    weights = exp.(weights)
    # Plot histogram
    plt = histogram!(plt, plan_lengths, weights=weights;
                     guidefontsize=16, tickfontsize=14, legend=false,
                     xlabel="Plan lengths", ylabel="Frequency")
end

## Particle filter callback functions ##

"Callback function that renders each state."
function render_cb(t::Int, state, traces, weights;
                   plan=nothing, start_pos=nothing, start_dir=nothing,
                   canvas=nothing, show_inventory=true, kwargs...)
    # Render canvas if not provided
    plt = canvas == nothing ? render(state; kwargs...) : deepcopy(canvas)
    dir = start_dir # Set agent direction to start dir
    if !isnothing(plan) # Render past actions if provided
        plan = plan[1:max(1,min(t-1, length(plan)))]
        render!(plan, start_pos, plt; fade=true, trunc=6, color=:black)
        i = findlast(a -> a.name in [:up, :down, :left, :right, :unlock], plan)
        dir = i == nothing ? start_dir : plan[i].name
        if (dir == :unlock) dir = plan[i].args[2].name end
    end
    render_objects!(state, plt; kwargs...) # Render objects in gridworld
    render_pos!(state, plt; dir=dir, kwargs...)  # Render agent's position
    render_traces!(traces, weights, plt; kwargs...) # Render trajectories
    title!(plt, "t = $t")
    if show_inventory
        i_plt = render_inventory!(state; kwargs...)
        sz = [plt[:size][1], plt[:size][2] + i_plt[:size][2]]
        plt = plot(plt, i_plt; size=sz, layout=grid(2,1, heights=[0.9, 0.1]))
    end
    return plt
end

"Callback function for plotting goal probability bar chart."
function goal_bars_cb(t::Int, state, traces, weights; kwargs...)
    goal_names = get(kwargs, :goal_names, [])
    goal_colors = get(kwargs, :goal_colors, cgrad(:plasma)[1:3:30])
    goal_idxs = collect(1:length(goal_names))
    goal_probs = sort!(get_goal_probs(traces, weights, goal_idxs))
    plt = plot_goal_bars!(goal_probs, goal_names, goal_colors)
    title!(plt, "t = $t")
    return plt
end

"Callback function for plotting goal probability line graph."
function goal_lines_cb(t::Int, state, traces, weights;
                       goal_probs=[], kwargs...)
    goal_names = get(kwargs, :goal_names, [])
    goal_colors = get(kwargs, :goal_colors, cgrad(:plasma)[1:3:30])
    if length(goal_probs) < t # Only accumulate if no one has done it yet
        goal_idxs = collect(1:length(goal_names))
        goal_probs_t = sort!(get_goal_probs(traces, weights, goal_idxs))
        push!(goal_probs, collect(values(goal_probs_t)))
    end
    plt = plot_goal_lines!(reduce(hcat, goal_probs), goal_names, goal_colors)
    title!(plt, "t = $t")
    return plt
end

"Callback function for plotting particle weights."
particle_weights_cb(t, state, traces, weights; kwargs...) =
    plot_particle_weights!(weights)

"Callback function for plotting plan lengths."
plan_lengths_cb(t, state, traces, weights; kwargs...) =
    plot_plan_lengths!(traces, weights)

"Callback function that combines a number of subplots."
function multiplot_cb(t::Int, state, traces, weights,
                      plotters=[render_cb]; layout=nothing,
                      keytimes::Vector{Int}=Int[], keyframes=nothing,
                      animation=nothing, show=true, kwargs...)
    subplots = [p(t, state, traces, weights; kwargs...) for p in plotters]
    margin = plotters == [render_cb] ? 2*Plots.mm : 10*Plots.mm
    if layout == nothing
        layout = length(subplots) > 1 ? (length(subplots) ÷ 2, 2) : (1, 1) end
    plt = plot(subplots...; layout=layout, margin=margin,
               size=(layout[2], layout[1]) .* 600)
    if keyframes != nothing && t in keytimes push!(keyframes, deepcopy(plt)) end
    if show display(plt) end # Display the plot in the GUI
    if animation != nothing frame(animation) end # Save frame to animation
    return plt
end

## Storyboard plotters ##

"Plot storyboard of frames showing goal inferences over time."
function plot_storyboard(frames::Vector, goal_probs=nothing, times=Int[];
                         titles=[], labels=["(i)", "(ii)", "(iii)", "(iv)"],
                         time_lims=nothing, legend=false,
                         goal_names=nothing, goal_colors=cgrad(:plasma)[1:3:30])
    frames = deepcopy(frames)
    n_frames = length(frames)
    # Add titles and times to each frame to each frame
    for i in 1:n_frames
        if i <= length(titles)
            lbl, ttl = labels[i], titles[i]
            title!(frames[i][1], "$lbl $ttl"; titlefontsize=20)
            plot!(frames[i][1]; top_margin=10*Plots.mm)
        end
        if i <= length(times)
            center = sum(frames[i][end][:xaxis][:lims]) / 2
            annotate!(frames[i][end], center, 1.35,
                      Plots.text("t = $(times[i])"))
        end
    end
    # Plot keyframes in sequence
    plt = plot(frames...; layout=(1, n_frames), size=(n_frames*600, 700))
    if goal_probs == nothing return plt end
    # Plot line graph of goal probabilities below frames
    if isa(goal_probs, Vector) goal_probs = reduce(hcat, goal_probs) end
    l_plt = plot_goal_lines!(goal_probs, goal_names, goal_colors)
    plot!(l_plt; legend=legend, legendfontsize=12, legendtitlefontsize=16,
          left_margin=20*Plots.mm, right_margin=20*Plots.mm,
          bottom_margin=5*Plots.mm)
    if time_lims == nothing
        xlims!(l_plt, 1, size(goal_probs)[2])
    else
        xlims!(l_plt, time_lims[1], time_lims[2])
    end
    xlabel!(l_plt, "")
    annotate!(l_plt, l_plt[1][:xaxis][:lims][2], -0.1, Plots.text("Time"))
    vline!(l_plt, times; ls=:dash, lw=2, color=:black, label="")
    for (t, lbl) in zip(times, labels) annotate!(t, -0.075, Plots.text(lbl)) end
    layout = grid(2, 1, heights=[0.75, 0.25])
    plt = plot(plt, l_plt; layout=layout, size=(n_frames*600, 900))
    return plt
end

"Plot legend for storyboard figure."
function plot_storyboard_legend(n_frames, gem_colors=cgrad(:plasma)[1:3:30])
    plt = plot(size=(n_frames*600, 200), aspect_ratio=1, framestyle=:none)
    # Observations label
    annotate!(plt, -0.75, 1, Plots.text("Observations:", 36, :right))
    # Agent label
    agent = Plots.scale(make_triangle(1, 1, 0.25*1.5, :right), 1.0, 0.8)
    plot!(plt, agent; color=:red, linealpha=0, alpha=1)
    annotate!(plt, 1.5, 1, Plots.text("Agent", 30, :left))
    # Actions label
    for (i, x) in enumerate([4, 4.3, 4.6])
        triangle = make_triangle(x, 1, 0.1*1.5, :right)
        plot!(plt, triangle; color=:black, linealpha=0, alpha=i*1/3)
    end
    annotate!(plt, 5, 1, Plots.text("Recent Actions", 30, :left))
    # Door label
    render_door!(10.5, 1, 0.7, plt=plt)
    annotate!(plt, 11.25, 1, Plots.text("Door", 30, :left))
    # Key label
    render_key!(13.5, 1, 0.4, plt=plt)
    annotate!(plt, 14.1, 1, Plots.text("Key", 30, :left))
    # Gem labels
    for (i, color) in enumerate(gem_colors)
        render_gem!(16+(i-1)*0.5, 1, 0.3, plt=plt, color=color)
    end
    n_gems = length(gem_colors)
    annotate!(plt, 16 + n_gems*0.5, 1, Plots.text("Gems", 30, :left))
    # Inferences label
    annotate!(plt, -0.75, 0, Plots.text("Inferences:", 36, :right))
    # Labels for inferred plans
    gem_offset = 1
    for gem_color in gem_colors
        for (i, x) in enumerate([0, 0.5, 1.0] .+ gem_offset)
            circ = make_circle(x, 0, 0.2)
            plot!(plt, circ; color=gem_color, linealpha=0, alpha=0.5)
        end
        annotate!(plt, gem_offset+1.5, 0,
                  Plots.text("Inferred Plans to", 30, :left))
        render_gem!(gem_offset+6.1, 0, 0.3, plt=plt, color=gem_color)
        gem_offset += 7
    end
    xlims!(plt, -5, 25)
    ylims!(plt, -0.5, 1.5)
    return plt
end
