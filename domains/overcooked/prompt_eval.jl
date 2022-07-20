using PDDL, SymbolicPlanners
using CSV, DataFrames, Dates

include("goal_validation.jl")
include("gpt3_complete.jl")

## Script options ##

# TODO: Make more general
GOAL_PROMPT = """
What are some dishes that could possibly be made with the current
ingredients? Given the initial state and an initial example, next
describe two more examples different from the first. In each example
first give a description in English then give a specification in the
Planning Domain Definition Language (PDDL). Be as descriptive
as possible with each English description.
"""
GOAL_PROMPT = replace(GOAL_PROMPT, "\n" => " ")

# PDDL problems
PROBLEMS = [
    "problem-1-1.pddl"
#    "problem-2-1.pddl"
]
PROBLEMS = joinpath.(@__DIR__, PROBLEMS)

# English descriptions of PDDL problems
DESCRIPTIONS = [
    "problem-1-1.txt"
  #  "problem-2-1.txt"
]
DESCRIPTIONS = joinpath.(@__DIR__, DESCRIPTIONS)

# Number of completions per prompt
N_REPEATS = 1

# Prompt header options
USE_PREDICATES = false
USE_ACTIONS = false
USE_OBJECTS = false
USE_INIT = true

# Prompt example type
# One of [:pddl, :eng, :pddl2eng, :eng2pddl, :pddl_eng, :eng_pddl]
EXAMPLE_TYPE = :pddl_eng
N_EXAMPLES = 1

## Helper functions ##

"Constructs a prompt header from a problem and a English language description."
function construct_prompt_header(
    domain_str::String, problem_str::String, description::String;
    use_predicates::Bool=false, use_actions::Bool=false,
    use_objects::Bool=true, use_init::Bool=true
)
    # Extract objects from problem file
    m = match(r"(\(:objects[\n\s\w\-;,]*\))[\w\s]*\(:init", problem_str)
    objects = isnothing(m) ? error(":objects block not found") : m.captures[1] 
    # Extract initial facts from problem file
    m = match(r"(\(:init[\n\s\w\-;,\(\)]*\))[\w\s]*\(:goal", problem_str)
    init = isnothing(m) ? error(":init block not found") : m.captures[1]
    # TODO: Extract initial state description from description text
    m = match(r"Initial State:([\n\s\w\-;,\(\).]*)[\w\s]*Goal:", description)
    description = isnothing(m) ? error("Description not found") : m.captures[1]
    # Construct header
    header = description
    if use_objects
        header = header * "\n\nHere is the initial set of objects:\n\n" * objects
    end
    if use_init
        header = header * "\n\nHere is the initial state:\n\n" * init
    end
    return header
end    

"Constructs prompt examples from PDDl goal and English language description."
function construct_prompt_examples(
    problem_str::String, description::String;
    n_examples::Int=1, example_type::Symbol=:pddl_eng
)
    @assert n_examples <= 1 "More than 1 example not supported yet."
    if n_examples == 0
        return ""
    end
    # TODO: Extract goal expression from problem file
    m = match(r"\(:goal([\n\s\w\-;,\(\).\?]*\)\)\))[\w\s]*", problem_str)
    pddl_goal = isnothing(m) ? error(":goal block not found") : m.captures[1] 
    # TODO: Extract English goal description from description text
    m = match(r"Goal:([\n\s\w\-;,\(\).]*)[\w\s]*", description)
    eng_goal = isnothing(m) ? error("English goal description not found") : m.captures[1] 
    # Construct examples
    if example_type == :pddl
        return "PDDL:\n" * pddl_goal * "\n\n" *  "PDDL:"
    elseif example_type == :eng
        return "English:\n" * eng_goal * "\n\n" * "English:"
    elseif example_type == :eng_pddl
        return "English:\n" * eng_goal * "\n\n" * "PDDL:\n" * pddl_goal * "\n\n" * "English:"
    elseif example_type == :pddl_eng
        return "PDDL:\n" * pddl_goal * "\n\n" * "English:\n" * eng_goal * "\n\n" * "PDDL:"
    end
end

"Parse GPT-3 completion into PDDL and English goal descriptions."
function parse_completion(completion::String, example_type::Symbol)
    # TODO: Use regex to split completion into parts
    if example_type == :pddl
        m = match(r"PDDL:\n([\n\s\w\-\;\,\?\(\)]*)", completion)
        if m === nothing 
            return false, "", ""
        else 
            return true, m.captures[1], ""
        end
    elseif example_type == :eng
        m = match(r"English:\n([\n\s\w\-\;\,\.]*)", completion)
        if m === nothing 
            return false, "", ""
        else 
            return true, "", m.captures[1]
        end
    elseif example_type == :eng_pddl
        m = match(r"English:\n([\n\s\w\-\;\,\.]*)PDDL:\n([\n\s\w\-\;\,\?\(\)]*)", completion)
        if m === nothing 
            return false, "", ""
        else 
            return true, m.captures[2], m.captures[1]
        end 
    elseif example_type == :pddl_eng
        m = match(r"PDDL:\n([\n\s\w\-\;\,\?\(\)]*)English:\n([\n\s\w\-\;\,\.]*)", completion)
        if m === nothing 
            return false, "", ""
        else 
            return true, m.captures[1], m.captures[2]
        end
    end
end

# Initialize data frame
df = DataFrame(
    problem=String[],
    description=String[],
    goal_prompt=String[],
    header=String[],
    examples=String[],
    use_predicates=Bool[],
    use_actions=Bool[],
    use_objects=Bool[],
    use_init=Bool[],
    n_examples=Int[],
    example_type=Symbol[],
    completion=String[],
    pddl_goal=String[],
    eng_goal=String[],
    parse_success=Bool[],
    valid=Bool[],
    reason=String[]
)

# Read domain as string
domain_str = read(joinpath(@__DIR__, "domain.pddl"), String);
# Parse domain
domain = parse_domain(domain_str);

for (problem_path, description_path) in zip(PROBLEMS, DESCRIPTIONS)
    # Read problem and description strings
    problem_str = read(problem_path, String)
    description = read(description_path, String)
    println("== Problem: $(basename(problem_path)) ==")

    # Parse problem and construct initial state
    problem = parse_problem(problem_str)
    state = initstate(domain, problem)

    # Construct prompt header from domain, problem, and description strings
    header = construct_prompt_header(
        domain_str, problem_str, description;
        use_predicates=USE_PREDICATES, use_actions=USE_ACTIONS,
        use_objects=USE_OBJECTS, use_init=USE_INIT)
    # Construct prompt examples
    examples = construct_prompt_examples(
        problem_str, description,
        n_examples=N_EXAMPLES, example_type=EXAMPLE_TYPE) 
    prompt = header * "\n\n\n" * GOAL_PROMPT * "\n\n\n" * examples
    println() 
    println("Prompt:\n")
    println(prompt)

    # Send prompt to GPT3 and get response
    if EXAMPLE_TYPE == :pddl 
        stop = "PDDL:"
    elseif EXAMPLE_TYPE == :eng
        stop = "English:"
    elseif EXAMPLE_TYPE == :pddl_eng
        stop = "PDDL:"
    elseif EXAMPLE_TYPE == :eng_pddl
        stop = "English:"
    end

    response = gpt3_complete(prompt, N_REPEATS, stop=stop)
    # Iterate over multiple completions
    for choice in response.choices
        # Extract completion text
        completion = choice.text # TODO: Get string completion from JSON
        println("Completion:")
        println(completion)
        # TODO: Parse completion into PDDL and English parts using regex
        success, pddl_goal, eng_goal = parse_completion(completion, EXAMPLE_TYPE)
        if !success
            continue
        end
        # Check if goal is valid
        valid, reason = validate_goal(pddl_goal, domain, state)
        row = Dict(
            :problem => problem_path,
            :description => description,
            :goal_prompt => GOAL_PROMPT,
            :header => header,
            :examples => examples,
            :completion => completion,
            :pddl_goal => pddl_goal,
            :eng_goal => eng_goal,
            :use_predicates => USE_PREDICATES,
            :use_actions => USE_ACTIONS,
            :use_objects => USE_OBJECTS,
            :use_init => USE_INIT,
            :n_examples => N_EXAMPLES,
            :example_type => EXAMPLE_TYPE,
            :parse_success => success,
            :valid => valid,
            :reason => reason
            )
        push!(df, row)
    end

    println()
end

df_path = joinpath(@__DIR__, "prompt_eval_$(Dates.now()).csv")
CSV.write(df_path, df)

# # Test prompt construction
# problem_str = read(PROBLEMS[1], String)
# description = read(DESCRIPTIONS[1], String)
# header = construct_prompt_header(domain_str, problem, description)
# examples = construct_prompt_examples(problem, description)

# # Example of how to match completions using regex

# #English and PDDL
# str1 = "English:
# A sliced lettuce salad.

# PDDL:
# (exists (?lettuce - food ?plate - receptacle)
# (and (food-type lettuce ?lettuce)
#      (receptacle-type plate ?plate)
#      (prepared slice ?lettuce)
#      (in-receptacle ?lettuce ?plate)))
# "

# #PDDL and English
# str2 = "PDDL:
# (exists (?lettuce - food ?plate - receptacle)
# (and (food-type lettuce ?lettuce)
#      (receptacle-type plate ?plate)
#      (prepared slice ?lettuce)
#      (in-receptacle ?lettuce ?plate)))

#      English:
# A sliced lettuce salad."
# m = match(r"PDDL:\n([\n\s\w\-\;\,\?\(\)]*)English:\n([\n\s\w\-]*)", str2)
# m.captures[1]
# m.captures[2]

# #English to PDDL
# # str3 = "English:
# # A sliced lettuce salad.

# # PDDL:"
# # m = match(r"English:\n([\n\s\w\-\;\,\.]*)PDDL:*", str3)
# # m.captures[1]
# # m.captures[2]

# # #PDDL to English
# # str4 = "PDDL:
# # (exists (?lettuce - food ?plate - receptacle)
# # (and (food-type lettuce ?lettuce)
# #      (receptacle-type plate ?plate)
# #      (prepared slice ?lettuce)
# #      (in-receptacle ?lettuce ?plate)))

# #      English:"
# # m = match(r"PDDL:\n([\n\s\w\-\;\,\?\(\)]*)English:*", str4)
# # m.captures[1]
# # m.captures[2]
