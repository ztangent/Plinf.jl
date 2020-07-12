using InverseTAMP
using ShapesWorld
using PyPlot
using LightGraphs
using MetaGraphs
using StaticArrays

function pddl_to_scene_graph(state::State)
    # TODO: Clean up this function using functions in states.jl
    # TODO: Change this code and problems code to specify directly in hex
    color_map = Dict(:red => "FF0000",
                     :green => "00FF00",
                     :blue => "0000FF")

    g = ShapesWorld.SceneGraph()
    types = state.types
    facts = state.facts
    fluents = state.fluents
    objects = []
    # Get the names and colors of all the block objects
    for term in types
        if term.name == :block
            block_name = term.args[1].name
            color = ""
            for fact in facts
                if fact.name == :colored && fact.args[1].name == block_name
                    color = color_map[fact.args[2].name]
                end
            end
            push!(objects, ((block_name,), color))
        end
    end

    sizes = fluents[:size]
    xs, ys, zs = fluents[:posx], fluents[:posy], fluents[:posz]
    yaws, pitches, rolls = fluents[:yaw], fluents[:pitch], fluents[:roll]
    for (i, (object, color)) in enumerate(objects)
        size = sizes[object]
        ShapesWorld.addObject!(g, Symbol("color_", color, "_block", i), ShapesWorld.Box(size, size, size))
        if fluents[:roll][object] != -1
            ShapesWorld.setPose!(g, Symbol("color_", color, "_block", i), [xs[object], ys[object], zs[object]],
                        (yaw=yaws[object], pitch=pitches[object], roll=rolls[object]))
        end
    end

    for fact in facts
        if fact.name == :on
            base, top = fact.args
            base, top = (base.name,), (top.name,)
            # Works since each object in objects is unique
            base_idx = findfirst(x -> x == base, [object[1] for object in objects])
            top_idx = findfirst(x -> x == top, [object[1] for object in objects])
            base_color = objects[base_idx][2]
            top_color = objects[top_idx][2]
            x = xs[top]
            y = ys[top]
            theta = yaws[top]
            ShapesWorld.setContact!(g, Symbol("color_", base_color, "_block", base_idx), :top, (),
                        Symbol("color_", top_color, "_block", top_idx), :bottom, (),
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
    camera_config = ShapesWorld.fallbackCameraConfig()
    lighting_config = ShapesWorld.fallbackLightingConfig()
    (rgba, depth, seg, _) = ShapesWorld.renderScene(scene_graph; cameraConfig=camera_config, lightingConfig=lighting_config)
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
    new_sg = deepcopy(prev_sg)
    still_iter = true
    while still_iter
        still_iter = false
        for object in vertices(prev_sg)
            prev_pos = get_prop(prev_sg, object, :absolutePose).pos
            final_pos = get_prop(final_sg, object, :absolutePose).pos
            direction = sign.(final_pos - prev_pos)
            if prev_pos != final_pos
                still_iter = true
                new_pos = prev_pos + (fill(velocity, 3) .* direction)
                # Handle possible overshooting
                for i=1:length(new_pos)
                    # TODO: Clean this up
                    if (final_pos[i] > prev_pos[i] && new_pos[i] > final_pos[i]) ||
                        (final_pos[i] < prev_pos[i] && new_pos[i] < final_pos[i])
                        new_pos = setindex(new_pos, Float64(final_pos[i]), i)
                        println(object)
                        println(new_pos)
                    end
                end
                name = get_prop(prev_sg, object, :name)
                prev_rot = ShapesWorld.quaternionToYawPitchRoll(get_prop(prev_sg, object, :absolutePose).orientation)
                ShapesWorld.setPose!(new_sg, name, new_pos,
                            (yaw=prev_rot[1], pitch=prev_rot[2], roll=prev_rot[3]))
            end
        end
        println(new_sg)
        push!(intermediate_sgs, new_sg)
        prev_sg = new_sg
        new_sg = deepcopy(prev_sg)
    end
    return intermediate_sgs
end
