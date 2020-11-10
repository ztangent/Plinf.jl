# Functions for generating gridworld PDDL problems
using Julog, PDDL

"Converts ASCII gridworlds to PDDL problem."
function ascii_to_pddl(str::String, name="ai2thor-2d-problem")
    rows = split(str, "\n", keepempty=false)
    init = @julog Term[handsfree]
    cylinders, blocks = Const[], Const[]
    start, goal = Term[], @julog(and())
    for (y, row) in enumerate(reverse(rows))
        for (x, char) in enumerate(strip(row))
            if char == '.'
                continue
            elseif char == 'W' # Wall
                push!(init, @julog(wall($x, $y)))
            elseif char == 'c' # Cylinder
                c = Const(Symbol("cylinder$(length(cylinders)+1)"))
                push!(cylinders, c)
                push!(init, @julog(xitem(:c) == $x))
                push!(init, @julog(yitem(:c) == $y))
            elseif char == 'b' # Block
                b = Const(Symbol("block$(length(blocks)+1)"))
                push!(blocks, b)
                push!(init, @julog(xitem(:b) == $x))
                push!(init, @julog(yitem(:b) == $y))
            elseif char == 's' # Start position
                start = @julog [xpos == $x, ypos == $y]
            end
        end
    end
    width, height = maximum(length.(strip.(rows))), length(rows)
    dims = @julog [width == $width, height == $height]
    init = Term[dims; start; init]
    objs = Const[cylinders; blocks]
    objtypes = merge(Dict(c => :cylinder for c in cylinders),
                     Dict(b => :block for b in blocks))
    problem = Problem(Symbol(name), Symbol("ai2thor-2d"), objs, objtypes,
                      init, goal, nothing)
    return problem
end

function load_ascii_problem(path::String)
    str = open(f->read(f, String), path)
    return ascii_to_pddl(str)
end

function ascii_to_state(str::String)
    rows = split(str, "\n", keepempty=false)
    terms = @julog Term[handsfree]
    cylinders, blocks = Term[], Term[]
    pos = Term[]
    for (y, row) in enumerate(reverse(rows))
        for (x, char) in enumerate(strip(row))
            if char == '.'
                continue
            elseif char == 'W' # Wall
                push!(terms, @julog(wall($x, $y)))
            elseif char == 'c' # Cylinder
                c = Const(Symbol("cylinder$(length(cylinders)+1)"))
                push!(cylinders, @julog(cylinder(:c)))
                push!(terms, @julog(xitem(:c) == $x))
                push!(terms, @julog(yitem(:c) == $y))
            elseif char == 'b' # Block
                b = Const(Symbol("block$(length(blocks)+1)"))
                push!(blocks, @julog(block(:b)))
                push!(terms, @julog(xitem(:b) == $x))
                push!(terms, @julog(yitem(:b) == $y))
            elseif char == 's' # Start position
                pos = @julog [xpos == $x, ypos == $y]
            end
        end
    end
    width, height = maximum(length.(strip.(rows))), length(rows)
    dims = @julog [width == $width, height == $height]
    terms = Term[dims; pos; terms]
    types = Term[cylinders; blocks]
    state = State(terms, types)
    return state
end

function load_ascii_state(path::String)
    str = open(f->read(f, String), path)
    return ascii_to_state(str)
end

function load_scene(scene_num::Int, dir::String)
    states = []
    fns = readdir(dir)
    split_fns = [split(fn, r"_|\.") for fn in fns]
    for trial in 0:8
        trial_states = []
        num_steps = maximum([parse(Int64, fn[3]) for fn in split_fns if parse(Int64, fn[1]) == scene_num && parse(Int64, fn[2]) == trial])
        for step in 0:num_steps
            fn = lpad(scene_num, 4, "0") * "_" * lpad(trial, 4, "0") * "_" * lpad(step, 4, "0") * ".txt"
            push!(trial_states, load_ascii_state(joinpath(dir, fn)))
        end
        push!(states, trial_states)
    end
    return states
end
