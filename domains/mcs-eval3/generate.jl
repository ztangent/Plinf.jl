# Functions for generating gridworld PDDL problems
using Julog, PDDL

"Converts ASCII gridworlds to PDDL problem."
function ascii_to_pddl(str::String, name="mcs-agency-problem")
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
