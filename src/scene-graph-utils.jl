using InverseTAMP
using ShapesWorld

function pddl_to_scene_graph(state::State, problem::Problem)
    g = SceneGraph()
    facts = state.facts
    objects = problem.objects

    for object in objects
        size =
        addObject!(g, Symbol("block", i), Box(size, size, size))

        base = nothing
        for potential_base in objects
            if 
                base = potential_base
            end
        end

        if base == nothing
            position =
            orientation =
            setPose!()
        else
            x =
            y =
            theta =
            setContact!(g, base, :top, (),
                        Symbol("block", i), :bottom, (),
                        x, y, theta)
        end
    end

    return g
end

function scene_graph_to_pddl(scene_graph)

end
