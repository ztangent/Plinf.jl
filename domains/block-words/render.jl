using Julog, PDDL
using Plots

make_rect(x, y, w, h) = Shape(x .+ [0, w, w, 0, 0], y .+ [0, 0, h, h, 0])
make_square(x, y, w) = make_rect(x, y, w, w)

"Render blocks world state."
function render!(state::State, plt=nothing; show_blocks=true, kwargs...)
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

function render_blocks!(state::State, plt=nothing; alpha=1.0,
                        block_colors=cgrad(:plasma)[1:24:256], kwargs...)
    # Get last plot if not provided
    plt = (plt == nothing) ? plot!() : plt
    # Get list of blocks
    _, subst = satisfy(@julog(block(X)), state, mode=:all)
    blocks = sort!([s[Var(:X)].name for s in subst])
    width, height = length(blocks)*1.5, length(blocks)*1.5
    # Render blocks
    for (i, block) in enumerate(blocks)
        # Render each block on table
        if state[@julog(ontable($block))]
            x, y = (i-1) * 1.5 + 0.25, 1
            plot!(plt, make_square(x, y, 1), color=block_colors[i],
                  alpha=alpha, linealpha=0, legend=false)
            annotate!(x+0.5, y+0.5, Plots.text(block, 16, :white, :center))
            # Render any stacked blocks
            while !state[@julog(clear($block))]
                _, subst = satisfy(@julog(on(X, $block)), state)
                block = subst[1][Var(:X)].name
                y += 1
                block_color = block_colors[findfirst(blocks .== block)]
                plot!(plt, make_square(x, y, 1), color=block_color,
                      alpha=alpha, linealpha=0, legend=false)
                annotate!(x+0.5, y+0.5, Plots.text(block, 16, :white, :center))
            end
        elseif state[@julog(holding($block))]
            x, y = (i-1) * 1.5 + 0.25, height - 1
            plot!(plt, make_square(x, y, 1), color=block_colors[i],
                  alpha=alpha, linealpha=0, legend=false)
            annotate!(x+0.5, y+0.5, Plots.text(block, 16, :white, :center))
        end
    end
    return plt
end

"Render animation of state trajectory/ies."
function anim_traj(trajs, canvas=nothing, animation=nothing;
                   show=true, fps=2, kwargs...)
    if isa(trajs, Vector{State}) trajs = [trajs] end
    canvas = canvas == nothing ?
        render(trajs[1][1]; show_blocks=false, kwargs...) : canvas
    animation = animation == nothing ? Animation() : animation
    for t in 1:maximum(length.(trajs))
        plt = deepcopy(canvas)
        for traj in trajs
            state = t <= length(traj) ? traj[t] : traj[end]
            render_blocks!(state, plt; kwargs...)
        end
        frame(animation)
    end
    if show display(gif(animation; fps=fps)) end
    return animation
end
