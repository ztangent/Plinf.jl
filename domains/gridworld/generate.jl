using Julog, PDDL

# Functions for generating gridworld PDDL problems

"Converts ASCII gridworlds to PDDL problem."
function ascii_to_pddl(str::String, name="gridworld-problem")
    rows = split(str, "\n", keepempty=false)
    init = Term[]
    start, goal = Term[], @julog(and())
    for (y, row) in enumerate(reverse(rows))
        for (x, char) in enumerate(row)
            if char == '.'
                continue
            elseif char == 'W' # Wall
                push!(init, @julog(wall($x, $y)))
            elseif char == 's' # Start position
                start = @julog [xpos == $x, ypos == $y]
            elseif char == 'g' # Goal position
                goal = @julog and(xpos == $x, ypos == $y)
            end
        end
    end
    width, height = maximum(length.(rows)), length(rows)
    dims = @julog [width == $width, height == $height]
    init = Term[dims; start; init]
    problem = Problem(Symbol(name), :gridworld, Const[], Dict{Const,Symbol}(),
                      init, goal, (-1, pddl"(total-cost)"))
    return problem
end
