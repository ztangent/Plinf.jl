using Julog, PDDL, Plots
using DataStructures: OrderedDict

## Shapes ##

make_rect(x, y, w, h) = Shape(x .+ [0, w, w, 0, 0], y .+ [0, 0, h, h, 0])
make_square(x, y, w) = make_rect(x, y, w, w)

"Make suction gripper as a collection of shapes."
function make_gripper(x, y, width, top)
    radius = width / 2.5
    block_top = y + width/2
    # Make gripper arm
    arm = make_rect(x - width/6, block_top, width/3, top - block_top)
    join = make_rect(x - width/5, block_top, width*2/5, radius + width/15)
    # Make suction cup
    xs, ys = Plots.unzip(Plots.partialcircle(0, pi, 100, radius))
    cup = Shape(xs .+ x, ys .+ block_top)
    return [arm, join, cup]
end

## Utility functions ##

"Compute block locations from the symbolic state."
function compute_locations(state::State, nan_holding=false)
    locs = OrderedDict{Symbol,Tuple{Real,Real}}()
    # Get list of blocks
    _, subst = satisfy(@julog(block(X)), state, mode=:all)
    blocks = sort!([s[Var(:X)].name for s in subst])
    width, height = length(blocks)*1.5, length(blocks)*1.5
    for (i, block) in enumerate(blocks)
        # Compute location for each block on table
        if state[@julog(ontable($block))]
            x, y = (i-1) * 1.5 + 0.25, 1
            locs[block] = (x, y)
            while !state[@julog(clear($block))]
                # Compute location for all stacked blocks
                _, subst = satisfy(@julog(on(X, $block)), state)
                block = subst[1][Var(:X)].name
                y += 1
                locs[block] = (x, y)
            end
        elseif state[@julog(holding($block))]
            # Compute location for gripped block
            x, y = (nan_holding ? NaN : width/2 - 0.5), height - 3
            locs[block] = (x, y)
            # locs[:_gripper] = (x+0.5, y+0.5)
        end
    end
    # Center gripper if nothing is held
    # if !haskey(locs, :_gripper) locs[:_gripper] = (width/2, height-1.5) end
    return locs
end

"Interpolate block locations for animation purposes."
function interpolate_locations(locs1::AbstractDict, locs2::AbstractDict;
                               n_frames=30)
    locs_traj = [deepcopy(locs1) for i in 1:n_frames]
    x_frames, y_frames = Int(n_frames/3), Int(n_frames * 2/3)
    for name in keys(locs1)
        x_old, x_new = locs1[name][1], locs2[name][1]
        if x_new === NaN x_new = x_old end
        y_old, y_new = locs1[name][2], locs2[name][2]
        if y_new === NaN y_new = y_old end
        x_diff, y_diff = x_new - x_old, y_new - y_old
        # Interpolate changes in first dimension
        n_frames_1 = y_diff > 0 ? y_frames : x_frames
        for i in 2:n_frames_1
            if y_diff > 0 # Change y first if moving up
                y = y_old + y_diff * i / n_frames_1
                locs_traj[i][name] = (x_old, y)
            elseif x_diff != 0 # Else change x first
                x = x_old + x_diff * i / n_frames_1
                locs_traj[i][name] = (x, y_old)
            end
        end
        # Interpolate changes in second dimension
        n_frames_2 = y_diff > 0 ? x_frames : y_frames
        for i in 1:n_frames_2
            if y_diff < 0 # Change y second if moving down
                y = y_old + y_diff * i / n_frames_2
                locs_traj[n_frames_1+i][name] = (x_new, y)
            else # Else change x second
                x = x_old + x_diff * i / n_frames_2
                locs_traj[n_frames_1+i][name] = (x, y_new)
            end
        end
    end
    return locs_traj
end

function interpolate_locations(locs::Vector{<:AbstractDict}; kwargs...)
    inter_locs = []
    queue = copy(locs)
    while length(queue) > 0
        l1 = popfirst!(queue)
        if isempty(queue)
            push!(inter_locs, l1)
            break
        end
        l2 = queue[1]
        segment = interpolate_locations(l1, l2; kwargs...)
        append!(inter_locs, segment[1:end-1])
        queue[1] = segment[end]
    end
    return inter_locs
end

## Blocksworld rendering ##

"Render blocks and their names, given their locations or a state."
function render_blocks!(block_locs::AbstractDict, plt=nothing; alpha=1.0,
                        block_colors=cgrad(:plasma)[1:24:256], kwargs...)
    height = (length(block_locs) - 1) *1.5
    # Render gripper
    # x, y = block_locs[:_gripper]
    # gripper = make_gripper(x, y, 1, height)
    # plot!(plt, gripper, color=[:gray60, :green, :darkgreen],
    #       alpha=alpha, linealpha=0, legend=false)
    # delete!(block_locs, :_gripper)
    # Render blocks
    for (i, (name, loc)) in enumerate(sort(block_locs))
        x, y = loc
        plot!(plt, make_square(x, y, 1), color=block_colors[i],
              alpha=alpha, linealpha=0, legend=false)
        annotate!(x+0.5, y+0.5, Plots.text(name, 16, :white, :center),
                  alpha=alpha)
    end
    return plt
end

function render_blocks!(state::State, plt=nothing; kwargs...)
    plt = (plt == nothing) ? plot!() : plt
    block_locs = compute_locations(state)
    return render_blocks!(block_locs, plt; kwargs...)
end

"Render blocksworld state."
function render!(state::State, plt=nothing;
                 show_blocks=true, kwargs...)
    # Get last plot if not provided
    plt = (plt == nothing) ? plot!() : plt
    # Get list of blocks
    _, subst = satisfy(@julog(block(X)), state, mode=:all)
    blocks = sort!([s[Var(:X)].name for s in subst])
    # Create axis
    width, height = length(blocks)*1.5, length(blocks)*1.5
    plot!(plt, xticks=([], []), yticks=([], []))
    # Render table
    table = make_rect(0, 0, width, 1)
    plot!(plt, table, color=:gray70, linealpha=0, legend=false)
    # Render blocks
    if show_blocks render_blocks!(state, plt; kwargs...) end
    # Resize limits
    xlims!(plt, 0, width)
    ylims!(plt, 0, height)
    return plt
end

function render(state::State; kwargs...)
    # Create new plot and render to it
    return render!(state, plot(size=(600,600), framestyle=:box); kwargs...)
end

"Render goal states for each (weighted) trace of the world model."
function render_traces!(traces, weights=nothing, plt=nothing;
                        max_alpha=0.50, kwargs...)
    weights = weights == nothing ? lognorm(get_score.(traces)) : weights
    plt = (plt == nothing) ? plot!() : plt
    for (tr, w) in zip(traces, weights)
        init_state = tr[:env_init]
        _, subst = satisfy(@julog(block(X)), init_state, mode=:all)
        block_consts = [s[Var(:X)] for s in subst]
        block_terms = Term[@julog(block(:b)) for b in block_consts]
        goal_state = State([tr[:goal_init].goals; block_terms])
        plt = render_blocks!(goal_state, plt; alpha=exp(w)*max_alpha)
    end
    return plt
end

## Blocksworld animations ##

"Render animation of state trajectory/ies."
function anim_traj(trajs, canvas=nothing, animation=nothing;
                   show=true, fps=30, kwargs...)
    if isa(trajs, Vector{State}) trajs = [trajs] end
    canvas = canvas == nothing ?
        render(trajs[1][1]; show_blocks=false, kwargs...) : canvas
    animation = animation == nothing ? Animation() : animation
    trajs = [interpolate_locations(compute_locations.(traj, true))
             for traj in trajs]
    for t in 1:maximum(length.(trajs))
        plt = deepcopy(canvas)
        for traj in trajs
            locs = t <= length(traj) ? traj[t] : traj[end]
            render_blocks!(locs, plt; kwargs...)
        end
        frame(animation)
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
                         goal_colors=nothing; plt=nothing)
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
    goal_colors = goal_colors != nothing ? goal_colors[1:length(goal_probs)] :
        collect(cgrad(:plasma, length(goal_probs); categorical=true))
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
                          goal_colors=nothing; timesteps=nothing, plt=nothing)
    # Construct new plot if not provided
    if (plt == nothing) plt = plot_canvas() end
    # Set default goal names and timesteps
    if (goal_names == nothing)
        goal_names = ["Goal $i" for i in 1:size(goal_probs, 1)] end
    if (timesteps == nothing)
        timesteps = collect(1:size(goal_probs, 2)) end
    goal_colors = goal_colors != nothing ? goal_colors[1:length(goal_probs)] :
        collect(cgrad(:plasma, length(goal_probs); categorical=true))
    # Plot line graph, one series per goal
    plt = plot!(plt, timesteps, goal_probs'; linewidth=3,
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
function render_cb(t::Int, state, traces, weights; canvas=nothing, kwargs...)
    # Render canvas if not provided
    plt = canvas == nothing ? render(state; kwargs...) : deepcopy(canvas)
    render_blocks!(state, plt; kwargs...) # Render blocks
    render_traces!(traces, weights, plt; kwargs...) # Render likely goal states
    title!(plt, "t = $t")
    return plt
end

"Callback function for plotting goal probability bar chart."
function goal_bars_cb(t::Int, state, traces, weights; kwargs...)
    goal_names = sort(get(kwargs, :goal_names, []))
    goal_colors = get(kwargs, :goal_colors,
                      cgrad(:plasma, length(goal_names); categorical=true))
    goal_probs = sort!(get_goal_probs(traces, weights, goal_names))
    plt = plot_goal_bars!(goal_probs, goal_names, goal_colors)
    title!(plt, "t = $t")
    return plt
end

"Callback function for plotting goal probability line graph."
function goal_lines_cb(t::Int, state, traces, weights;
                       goal_probs=[], kwargs...)
    goal_names = sort(get(kwargs, :goal_names, []))
    goal_colors = get(kwargs, :goal_colors,
                      cgrad(:plasma, length(goal_names); categorical=true))
    goal_probs_t = sort!(get_goal_probs(traces, weights, goal_names))
    push!(goal_probs, collect(values(goal_probs_t)))
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
                      animation=nothing, show=true, kwargs...)
    subplots = [p(t, state, traces, weights; kwargs...) for p in plotters]
    margin = plotters == [render_cb] ? 2*Plots.mm : 10*Plots.mm
    if layout == nothing
        layout = length(subplots) > 1 ? (length(subplots) ÷ 2, 2) : (1, 1) end
    plt = plot(subplots...; layout=layout, margin=margin,
               size=(layout[2], layout[1]) .* 600)
    if show display(plt) end # Display the plot in the GUI
    if animation != nothing frame(animation) end # Save frame to animation
    return plt
end
