using InverseTAMP
using ShapesWorld

function pddl_to_scene_graph(state::State)
    g = SceneGraph()
    facts = state.facts
    fluents = state.fluents
    objects = []
    # Get the names of all the block objects
    for term in facts
        if term.name == :block
            push!(objects, term.args[1])
        end
    end

    sizes = fluents[:size]

    for (i, object) in enumerate(objects)
        size = sizes[object]
        addObject!(g, Symbol("block", i), Box(size, size, size))
    end

    for fact in facts
        if fact.name == :on
            base, top = fact.args
            x = fluents[:x][top]
            y = fluents[:y][top]
            theta = fluents[:theta][top]
            setContact!(g, base, :top, (),
                        top, :bottom, (),
                        x, y, theta)
        elseif fact.name == :holding
            block = fact.args[1]

            setPose!()
        end
    end

        if base == nothing
            position =
            orientation =
            setPose!()
        else

        end
    end

    return g
end

function scene_graph_to_pddl(scene_graph)

end
