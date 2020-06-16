# Functions for generating gridworld PDDL problems
using Julog, PDDL

dir_objs = @julog [up, down, left, right]

"Converts ASCII gridworlds to PDDL problem."
function ascii_to_pddl(str::String, name="doors-keys-gems-problem")
    rows = split(str, "\n", keepempty=false)
    init = Term[]
    locs, gems, keys = Const[], Const[], Const[]
    goal = @julog(and())
    width, height = maximum(length.(strip.(rows))), length(rows)
    for (y, row) in enumerate(reverse(rows))
        for (x, char) in enumerate(strip(row))
            loc = Const(Symbol("x$(x)y$(y)"))
            push!(locs, loc)
            if x > 1
                adj = Const(Symbol("x$(x-1)y$(y)"))
                push!(init, @julog(conn(left, :loc, :adj)))
            end
            if x < width
                adj = Const(Symbol("x$(x+1)y$(y)"))
                push!(init, @julog(conn(right, :loc, :adj)))
            end
            if y > 1
                adj = Const(Symbol("x$(x)y$(y-1)"))
                push!(init, @julog(conn(down, :loc, :adj)))
            end
            if y < height
                adj = Const(Symbol("x$(x)y$(y+1)"))
                push!(init, @julog(conn(up, :loc, :adj)))
            end
            if char == '.'
                continue
            elseif char == 'W' # Wall
                push!(init, @julog(wall(:loc)))
            elseif char == 'D' # Door
                push!(init, @julog(door(:loc)))
            elseif char == 'k' # Key
                k = Const(Symbol("key$(length(keys)+1)"))
                push!(keys, k)
                push!(init, @julog(at(:k, :loc)))
            elseif char == 'g' || char == 'G' # Gem
                g = Const(Symbol("gem$(length(gems)+1)"))
                push!(gems, g)
                push!(init, @julog(at(:g, :loc)))
                if char == 'G' # Set goal
                    goal = @julog has(:g)
                end
            elseif char == 's' # Start position
                push!(init, @julog(pos(:loc)))
            end
        end
    end
    objs = Const[dir_objs; locs; keys; gems]
    objtypes = merge(Dict(d => :dir for d in dir_objs),
                     Dict(l => :loc for l in locs),
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
