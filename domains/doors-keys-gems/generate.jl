# Functions for generating gridworld PDDL problems
using Julog, PDDL

dir_objs = @julog [up, down, left, right]
dir_diffs = @julog [
    ==(xdiff(up), 0),
    ==(ydiff(up), 1),
    ==(xdiff(down), 0),
    ==(ydiff(down), -1),
    ==(xdiff(right), 1),
    ==(ydiff(right), 0),
    ==(xdiff(left), -1),
    ==(ydiff(left), 0),
]

"Converts ASCII gridworlds to PDDL problem."
function ascii_to_pddl(str::String, name="doors-keys-gems-problem")
    rows = split(str, "\n", keepempty=false)
    init = Term[]
    gems, keys = Const[], Const[]
    start, goal = Term[], @julog(and())
    for (y, row) in enumerate(reverse(rows))
        for (x, char) in enumerate(strip(row))
            if char == '.'
                continue
            elseif char == 'W' # Wall
                push!(init, @julog(wall($x, $y)))
            elseif char == 'D' # Door
                push!(init, @julog(door($x, $y)))
                push!(init, @julog(doorloc($x, $y)))
            elseif char == 'k' # Key
                k = Const(Symbol("key$(length(keys)+1)"))
                push!(keys, k)
                push!(init, @julog(at(:k, $x, $y)))
                push!(init, @julog(itemloc($x, $y)))
            elseif char == 'g' || char == 'G' # Gem
                g = Const(Symbol("gem$(length(gems)+1)"))
                push!(gems, g)
                push!(init, @julog(at(:g, $x, $y)))
                push!(init, @julog(itemloc($x, $y)))
                if char == 'G' # Set goal
                    goal = @julog has(:g)
                end
            elseif char == 's' # Start position
                start = @julog [xpos == $x, ypos == $y]
            end
        end
    end
    width, height = maximum(length.(strip.(rows))), length(rows)
    dims = @julog [width == $width, height == $height]
    init = Term[dir_diffs; dims; start; init]
    objs = Const[dir_objs; keys; gems]
    objtypes = merge(Dict(d => :direction for d in dir_objs),
                     Dict(k => :key for k in keys),
                     Dict(g => :gem for g in gems))
    problem = Problem(Symbol(name), Symbol("doors-keys-gems"), objs, objtypes,
                      init, goal, nothing)
    return problem
end

function load_ascii_problem(path::String)
    str = open(f->read(f, String), path)
    return ascii_to_pddl(str)
end
