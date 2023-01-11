using PDDL

"""
    load_goals(path::AbstractString)
    load_goals(io::IO)

Load a list of commented PDDL goals from a path or IO object.
"""
function load_goals(io::IO)
    str = read(io, String)
    return parse_goals(str)
end
load_goals(path::AbstractString) = open(io->load_goals(io), path)

"""
    parse_goals(str::AbstractString)

Parse a list of commented PDDL goals from a string.
"""
function parse_goals(str::AbstractString)
    # Split string by comment markers
    goal_strs = split(str, ";")
    # Split each goal string into its commented description and the PDDL formula
    descriptions = String[]
    goals = Term[]
    for s in goal_strs
        all(isspace(c) for c in s) && continue
        split_idx = findfirst('\n', s)
        if split_idx === nothing
            error("Could not find newline between description and goal.")
        end
        description = strip(s[1:split_idx-1])
        goal = parse_pddl(s[split_idx+1:end])
        push!(descriptions, description)
        push!(goals, goal)
    end
    return descriptions, goals
end
