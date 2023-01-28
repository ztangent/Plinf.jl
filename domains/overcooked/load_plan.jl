using PDDL

"""
    load_plan(path::AbstractString)
    load_plan(io::IO)

Load a comment-annotated PDDL plan from file.
"""
function load_plan(io::IO)
    str = read(io, String)
    return parse_plan(str)
end
load_plan(path::AbstractString) = open(io->load_plan(io), path)

"""
    parse_plan(str::AbstractString)

Parse a comment-annotated PDDL plan from a string.
"""
function parse_plan(str::AbstractString)
    plan = Term[]
    annotations = String[]
    annotation_idxs = Int[]
    for line in split(str, "\n")
        line = strip(line)
        if isempty(line)
            continue
        elseif line[1] == ';'
            push!(annotations, strip(line[2:end]))
            push!(annotation_idxs, length(plan))
        else
            push!(plan, parse_pddl(line))
        end
    end
    return plan, annotations, annotation_idxs
end
