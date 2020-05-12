using InverseTAMP
using ShapesWorld
using PyPlot
using LightGraphs

function pddl_to_scene_graph(state::State)
    g = ShapesWorld.SceneGraph()
    facts = state.facts
    fluents = state.fluents
    objects = []
    # Get the names of all the block objects
    for term in facts
        if term.name == :block
            push!(objects, (term.args[1].name,))
        end
    end

    sizes = fluents[:size]
    xs, ys, zs = fluents[:posx], fluents[:posy], fluents[:posz]
    yaws, pitches, rolls = fluents[:yaw], fluents[:pitch], fluents[:roll]
    for (i, object) in enumerate(objects)
        size = sizes[object]
        ShapesWorld.addObject!(g, Symbol("block", i), ShapesWorld.Box(size, size, size))
        if fluents[:roll][object] != -1
            ShapesWorld.setPose!(g, Symbol("block", i), [xs[object], ys[object], zs[object]],
                        (yaw=yaws[object], pitch=pitches[object], roll=rolls[object]))
        end
    end

    for fact in facts
        if fact.name == :on
            base, top = fact.args
            base, top = (base.name,), (top.name,)
            # Works since each object in objects is unique
            base_idx = findfirst(x -> x == base, objects)
            top_idx = findfirst(x -> x == top, objects)
            x = xs[top]
            y = ys[top]
            theta = yaws[top]
            ShapesWorld.setContact!(g, Symbol("block", base_idx), :top, (),
                        Symbol("block", top_idx), :bottom, (),
                        x, y, theta)
        end
    end

    ShapesWorld.set_prop!(g, :blurWidth, 5)
    ShapesWorld.set_prop!(g, :decayFactor, 0.1)
    return g
end

function scene_graph_to_pddl(scene_graph)

end

function visualize(scene_graph, outdir, frame_name_prefix)
    (rgba, depth, seg, _, _) = ShapesWorld.renderScene(scene_graph)
    png_file_path = joinpath(outdir, frame_name_prefix * ".png")
    PyPlot.imsave(png_file_path, rgba)
end

"""
Currently assumes no rotations.
"""
# TODO: Add in rotation transition
function smooth_transition(initial_sg, final_sg, velocity)
    intermediate_sgs = []

    prev_sg = initial_sg
    new_sg = copy(prev_sg)
    while prev_sg != final_sg
        for object in vertices(prev_sg)
            prev_pos = get_prop(prev_sg, object, :absolutePose)
            final_pos = get_prop(final_sg, object, :absolutePose)
            direction = sign.([final_pos - prev_pos])
            if prev_pos != final_pos
                new_pos = prev_pos + (fill(velocity, 3) .* direction)
                # Handle possible overshooting
                for i=1:length(new_pos)
                    # TODO: Clean this up
                    if (final_pos[i] > prev_pos[i] && new_pos[i] > final_pos[i])
                        || (final_pos[i] > prev_pos[i] && new_pos[i] > final_pos[i])
                        new_pos[i] = final_pos[i]
                    end
                end
                name = get_prop(prev_sg, object, :name)
                ShapesWorld.setPose!(g, name, new_pos,
                            (yaw=yaws[object], pitch=pitches[object], roll=rolls[object]))
            end
        end
        push!(intermediate_sgs, new_sg)
        prev_sg = new_sg
        new_sg = copy(prev_sg)
    end
    return intermediate_sgs
end
