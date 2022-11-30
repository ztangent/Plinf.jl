using PDDL, SymbolicPlanners
using CSV, DataFrames, Dates

include("goal_validation.jl")
include("gpt3_complete.jl")

## Goal parsing and validation ##

"Parse a string as a PDDL goal, checking if it is a valid PDDL formula."
function parse_goal(str::AbstractString)
    goal = parse_pddl(str)
    @assert goal isa Term
    return goal
end

"Validates a generated goal string with several checks."
function validate_goal_string(
    str::AbstractString, domain::Domain, state::State;
    verbose::Bool=false
)
    # Check if string parses to PDDL formula
    goal = nothing
    try
        goal = parse_goal(str)
    catch e
        reason = "Parse error"
        if verbose println("Validation Failed: $reason") end
        return (false, reason)
    end
    if verbose println("Validation: Goal Parsed") end
    return validate_goal(goal, domain, state, verbose=verbose)
end

## Prompt generation ##

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
    # Extract initial state description from description text
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
    @assert n_examples <= 1
   # Extract goal expression from problem file
    m = match(r"\(:goal([\n\s\w\-;,\(\).\?]*\)\)\))[\w\s]*", problem_str)
    pddl_goal = isnothing(m) ? error(":goal block not found") : m.captures[1] 
    # Extract English goal description from description text
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
    if example_type == :pddl
        m = match(r"\n([\n\s\w\-\;\,\?\(\)]*)", completion)
        if m === nothing 
            return false, "", ""
        else 
            return true, m.captures[1], ""
        end
    elseif example_type == :eng
        m = match(r"\n([\n\s\w\-\;\,\.]*)", completion)
        if m === nothing 
            return false, "", ""
        else 
            return true, "", m.captures[1]
        end
    elseif example_type == :eng_pddl
        m = match(r"\n([\n\s\w\-\;\,\.]*)PDDL:\n([\n\s\w\-\;\,\?\(\)]*)", completion)
        if m === nothing 
            return false, "", ""
        else 
            return true, m.captures[2], m.captures[1]
        end 
    elseif example_type == :pddl_eng
        m = match(r"\n([\n\s\w\-\;\,\?\(\)]*)English:\n([\n\s\w\-\;\,\.]*)", completion)
        if m === nothing 
            return false, "", ""
        else 
            return true, m.captures[1], m.captures[2]
        end
    end
end

## Script options ##

GOAL_PROMPT = """
Here are 100 dishes that could be made with the ingredients in this kitchen,
in this exact format:
"""
GOAL_PROMPT = replace(GOAL_PROMPT, "\n" => " ")

# PDDL problems
PROBLEMS = [
    "problem-1-1.pddl"
    "problem-2-1.pddl"
    "problem-3-1.pddl"
    "problem-4-1.pddl"
    "problem-5-1.pddl"
]
PROBLEMS = joinpath.(@__DIR__, PROBLEMS)

# English descriptions of PDDL problems
DESCRIPTIONS = [
    "problem-1-1.txt"
    "problem-2-1.txt"
    "problem-3-1.txt"
    "problem-4-1.txt"
    "problem-5-1.txt"
]
DESCRIPTIONS = joinpath.(@__DIR__, DESCRIPTIONS)

# Number of completions per prompt
N_REPEATS = 10

# Prompt header options
USE_PREDICATES = false
USE_ACTIONS = false
USE_OBJECTS = false
USE_INIT = true

# Prompt example type
# One of [:pddl, :eng, :pddl2eng, :eng2pddl, :pddl_eng, :eng_pddl]
EXAMPLE_TYPE = :pddl_eng
N_EXAMPLES = 1

# Temperature of generated completion
TEMPERATURE = 0.7

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
    temperature=Float64[],
    n_examples=Int[],
    example_type=Symbol[],
    completion=String[],
    pddl_goal=String[],
    eng_goal=String[],
    parse_success=Bool[],
    valid=Bool[],
    reason=String[]
)
df_types = eltype.(eachcol(df))
df_path = joinpath(@__DIR__, "prompt_eval_$(Dates.now()).csv")

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

    println("---")
    println("Requesting $N_REPEATS completions through OpenAI API...")
    response = gpt3_complete(prompt, N_REPEATS, verbose=true,
                             stop=stop, temperature=TEMPERATURE)
    println("---")

    # Iterate over multiple completions
    for (i, choice) in enumerate(response.choices)
        # Extract completion text
        completion = choice.text # TODO: Get string completion from JSON
        println("-- Completion $i--")
        println(completion)
        # Parse completion into PDDL and English parts using regex
        success, pddl_goal, eng_goal = parse_completion(completion, EXAMPLE_TYPE)
        println()
        println("-- Validation --")
        println("Parse Successful: $success")
        # Check if goal is valid
        valid, reason = validate_goal_string(pddl_goal, domain, state; verbose=true)
        println("Goal Validity: $valid")
        println("Validation Reason: $reason")
        println()
        row = Dict(
            :problem => basename(problem_path),
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
            :temperature => TEMPERATURE,
            :n_examples => N_EXAMPLES,
            :example_type => EXAMPLE_TYPE,
            :parse_success => success,
            :valid => valid,
            :reason => reason
            )
        push!(df, row)
    end
    CSV.write(df_path, df)
    println()
    println("Sleeping for 15s to avoid rate limit...")
    sleep(15.0)

    println()
end

# Construct filename for CSV

df_path = "/home/ucfai/Projects/Plinf.jl/domains/overcooked/prompt_eval_2022-07027T22:14:38.355.csv"

# Save to CSV file


# Read saved CSV
df = CSV.read(df_path, DataFrame, types=df_types)