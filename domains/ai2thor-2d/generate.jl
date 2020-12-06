# Functions for generating gridworld PDDL problems
using Julog, PDDL

"Converts ASCII gridworlds to PDDL problem."
function ascii_to_pddl(str::String, name="ai2thor-2d-problem")
    rows = split(str, "\n", keepempty=false)
    start, goals = Term[], Term[]
    n_fixed, n_movable, n_items, n_targets, n_containers = 0, 0, 0, 0, 0
    init = @julog Term[handsfree]
    objtypes = Dict{Const,Symbol}()

    add_obj! = (obj::Const, type::Symbol, x, y) -> begin
        objtypes[obj] = type
        push!(init, @julog(xobj(:obj) == $x))
        push!(init, @julog(yobj(:obj) == $y))
    end

    for (y, row) in enumerate(reverse(rows))
        for (x, char) in enumerate(strip(row))
            if char == '.' # Empty space
                continue
            elseif char == 'W' # Wall
                push!(init, @julog(wall($x, $y)))
            elseif char == 'f' # Fixed object
                n_fixed += 1; obj = Const(Symbol("fixed$n_fixed"))
                add_obj!(obj, :fixed, x, y)
            elseif char == 'm' # Movable object
                n_movable += 1; obj = Const(Symbol("movable$n_movable"))
                add_obj!(obj, :movable, x, y)
            elseif char == 'i' # Item (object that can be picked up)
                n_items += 1; obj = Const(Symbol("item$n_items"))
                add_obj!(obj, :item, x, y)
            elseif char == 't' # Target object
                n_targets += 1; obj = Const(Symbol("target$n_targets"))
                add_obj!(obj, :item, x, y)
                push!(goals, @julog(retrieve(:obj)))
            elseif char == 'c' # Target object hidden in openable container
                # Add target
                n_targets += 1; tgt = Const(Symbol("target$n_targets"))
                add_obj!(tgt, :item, x, y)
                push!(goals, @julog(retrieve(:tgt)))
                # Add openable container
                n_containers += 1; con = Const(Symbol("container$n_containers"))
                add_obj!(con, :fixed, x, y)
                append!(init, @julog(Term[receptacle(:con), openable(:con)]))
                # Set target within container
                append!(init, @julog(Term[inside(:tgt, :con), hidden(:tgt)]))
            elseif char == 'r' # Target object placed on receptacle (e.g. shelf)
                # Add target
                n_targets += 1; tgt = Const(Symbol("target$n_targets"))
                add_obj!(tgt, :item, x, y)
                push!(goals, @julog(retrieve(:tgt)))
                # Add container
                n_containers += 1; con = Const(Symbol("container$n_containers"))
                add_obj!(con, :fixed, x, y)
                push!(init, @julog(receptacle(:con)))
                # Set target within container
                push!(init, @julog(inside(:tgt, :con)))
            elseif char == 's' # Start position
                start = @julog [xpos == $x, ypos == $y]
            end
        end
    end
    width, height = maximum(length.(strip.(rows))), length(rows)
    dims = @julog [width == $width, height == $height]
    init = Term[dims; start; init]
    goal = Compound(:and, goals)
    objs = sort!(collect(keys(objtypes)), by=c->c.name)
    problem = Problem(Symbol(name), Symbol("ai2thor-2d"), objs, objtypes,
                      init, goal, nothing)
    return problem
end

function load_ascii_problem(path::String)
    str = open(f->read(f, String), path)
    return ascii_to_pddl(str)
end
