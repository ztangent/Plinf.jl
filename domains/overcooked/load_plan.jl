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

"""
    load_subgoals(path::AbstractString; include_count = false)
    load_subgoals(io::IO; include_count = false)

Load a comment-annotated PDDL subgoal sequence from file.
"""
function load_subgoals(io::IO; include_count = false)
    str = read(io, String)
    return parse_subgoals(str; include_count = include_count)
end
load_subgoals(path::AbstractString) = open(io->load_subgoals(io), path)

"""
    parse_subgoals(str::AbstractString; include_count = false)

Parse a comment-annotated PDDL subgoal sequence from a string.
"""
function parse_subgoals(str::AbstractString; include_count = false)
    subgoals = Vector{Term}[]
    annotations = String[]
    in_annotation = false
    for line in split(str, "\n")
        line = strip(line)
        if isempty(line)
            continue
        elseif line[1] == ';'
            if in_annotation
                if !include_count && occursin("Number of subgoals:", line)
                    continue
                end
                annotations[end] *= "\n" * strip(line[2:end])
            else
                push!(annotations, strip(line[2:end]))
                in_annotation = true
            end
        else
            if in_annotation
                in_annotation = false
                push!(subgoals, Term[parse_pddl(line)])
            else
                push!(subgoals[end], parse_pddl(line))
            end
        end
    end
    return subgoals, annotations
end
