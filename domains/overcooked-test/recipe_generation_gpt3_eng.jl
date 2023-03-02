using PDDL
using CSV, DataFrames, Dates

include("gpt3_complete.jl")
include("goal_validation.jl")
include("recipe_writing.jl")
include("recipe_parsing.jl")

## Recipe validation

"Check when a series of GPT-3 generated tokens reaches the end of a recipe."
function recipe_stop_condition(tokens)
    # Check if last token is a newline
    tokens[end] != "\n" && return false
    # Search backwards until we find another newline
    i = lastindex(tokens)
    while i > firstindex(tokens)
        i -= 1
        tokens[i] == "\n" && break
    end
    # Check if last line begins with "Serve:"
    last_line = tokens[i] == "\n" ? join(tokens[i+1:end]) : join(tokens[i:end])
    if match(r"Serve:.*", last_line) !== nothing
        return true
    else
        return false
    end
end

"Extract completion text and log probability from GPT-3 completion JSON."
function extract_completion_text_and_logprobs(
    completion_obj, n_stop_tokens=2
)
    # Check if completion went beyond what was expected
    if (completion_obj.finish_reason != "stop" ||
        occursin("KITCHEN", completion_obj.text))
        tokens, token_logprobs =
            extract_tokens_until_stop(completion_obj, recipe_stop_condition)
        completion = join(tokens)
        logprobs = sum(token_logprobs)
    else # Completion stopped as expected
        # Extract text
        completion = completion_obj.text 
        # Extract log probability
        logprobs = extract_logprobs(completion_obj, n_stop_tokens)
    end
    return completion, logprobs
end

"Validates a generated recipe string with several checks."
function validate_recipe_string(
    str::AbstractString, domain::Domain, state::State;
    verbose::Bool=false
)
    # Check if recipe parses to PDDL formula
    result = try_parse_recipe(str)
    if isnothing(result)
        reason = "Parse error"
        if verbose println("Validation Failed: $reason") end
        return (false, reason)
    end
    goal, _ = result
    if verbose println("Validation: Goal Parsed") end
    return validate_goal(goal, domain, state, verbose=verbose)
end

## Prompt generation functions ##

function construct_multikitchen_prompt(
    domain::Domain, problem_sets, kitchen_names, instruction="";
    include_english_description::Bool=true
)
    prompt = ""
    for (problem_paths, name) in zip(problem_sets, kitchen_names)
        reference_problem = load_problem(problem_paths[end])
        kitchen = construct_kitchen_description(domain, reference_problem)
        recipes = map(problem_paths) do path
            prob = load_problem(path)
            desc_path = path[1:end-5] * ".txt"
            desc = load_english_recipe_description(desc_path)
            return construct_recipe_description(
                domain, prob, desc;
                include_description=include_english_description
            )
        end
        str = "KITCHEN: $(uppercase(name))\n\n" * kitchen * "\n\n" * instruction *
              "RECIPES\n\n" * join(recipes, "\n\n")
        prompt *= str * "\n\n"
    end
    return prompt
end

## Test multi-kitchen prompt construction from last two problems of each kitchen

DOMAIN_DIR = @__DIR__
PROBLEM_DIR = joinpath(@__DIR__, "problems")

prompt = construct_multikitchen_prompt(
    load_domain(joinpath(@__DIR__, "domain.pddl")),
    [
        [joinpath(PROBLEM_DIR, "problem-1-4.pddl"), joinpath(PROBLEM_DIR, "problem-1-5.pddl")],
        [joinpath(PROBLEM_DIR, "problem-2-4.pddl"), joinpath(PROBLEM_DIR, "problem-2-5.pddl")],
        [joinpath(PROBLEM_DIR, "problem-3-4.pddl"), joinpath(PROBLEM_DIR, "problem-3-5.pddl")],
        [joinpath(PROBLEM_DIR, "problem-4-4.pddl"), joinpath(PROBLEM_DIR, "problem-4-5.pddl")],
        [joinpath(PROBLEM_DIR, "problem-5-4.pddl"), joinpath(PROBLEM_DIR, "problem-5-5.pddl")],
    ],
    ["salad bar", "sushi bar", "delicatessen", "pizzeria", "fruits and desserts"]
)

## Script options ##

# Recipe generation instruction 
INSTRUCTION =
    "Below is a list of recipes that can be made using only the " *
    "ingredients, receptacles, tools, appliances, and methods in this kitchen. " *
    "If ingredients in a recipe are not modified by any method, then they can be " * 
    "assumed to remain in store-bought form.\n\n"

# Kitchen names
KITCHEN_NAMES = [
    "salad bar", 
    "sushi bar",
    "delicatessen",
    "pizzeria",
    "fruits and desserts"
]

# Paths to problems used in prompt generation
# Make sure to include problem X-5 as the last in each set
PROMPT_PROBLEMS = [
    ["problem-1-3.pddl", "problem-1-4.pddl", "problem-1-5.pddl"],
    ["problem-2-3.pddl", "problem-2-4.pddl", "problem-2-5.pddl"],
    ["problem-3-3.pddl", "problem-3-4.pddl", "problem-3-5.pddl"],
    ["problem-4-3.pddl", "problem-4-4.pddl", "problem-4-5.pddl"],
    ["problem-5-3.pddl", "problem-5-4.pddl", "problem-5-5.pddl"], 
]
PROMPT_PROBLEMS = 
    [joinpath.(@__DIR__, "problems", pset) for pset in PROMPT_PROBLEMS]

# Paths to problems to test goal generation on
TEST_PROBLEMS = [
    ["problem-1-1.pddl", "problem-1-2.pddl", "problem-1-3.pddl", "problem-1-4.pddl", "problem-1-5.pddl"],
    ["problem-2-1.pddl", "problem-2-2.pddl", "problem-2-3.pddl", "problem-2-4.pddl", "problem-2-5.pddl"],
    ["problem-3-1.pddl", "problem-3-2.pddl", "problem-3-3.pddl", "problem-3-4.pddl", "problem-3-5.pddl"],
    ["problem-4-1.pddl", "problem-4-2.pddl", "problem-4-3.pddl", "problem-4-4.pddl", "problem-4-5.pddl"],
    ["problem-5-1.pddl", "problem-5-2.pddl", "problem-5-3.pddl", "problem-5-4.pddl", "problem-5-5.pddl"],
]
TEST_PROBLEMS =
    [joinpath.(@__DIR__, "problems", pset) for pset in TEST_PROBLEMS]

# Number of completions per prompt
N_REPEATS = 50

# Temperature of generated completion
TEMPERATURE = 1.0

# Model to request completions from
MODEL = "text-davinci-003" # "davinci"

# Whether to include English descriptions in recipes
INCLUDE_RECIPE_DESCRIPTION = false

# Initialize data frame
df = DataFrame(
    kitchen_id=Int[],
    kitchen_name=String[],
    n_train_kitchens=Int[],
    n_train_recipes_per_kitchen=Int[],
    recipe_instruction=String[],
    include_recipe_description=Bool[],
    problem=String[],
    kitchen_description=String[],
    temperature=Float64[],
    model=String[],
    completion=String[],
    logprobs=Float64[],
    pddl_goal=String[],
    eng_goal=String[],
    parse_success=Bool[],
    valid=Bool[],
    reason=String[]
)
df_types = eltype.(eachcol(df))
datetime = Dates.format(Dates.now(), "yyyy-mm-ddTHH-MM-SS")
n_per_kitchen = length(PROMPT_PROBLEMS[1]) 
df_path = "recipes_gpt3_eng_$(MODEL)_" * "temp_$(TEMPERATURE)_" *
          "nperkitchen_$(n_per_kitchen)" * "_$(datetime).csv"
df_path = joinpath(@__DIR__, df_path)

# Load domain
domain = load_domain(joinpath(@__DIR__, "domain.pddl"))

# Set start and stop token based on whether recipe description is included
START_AND_STOP_STRING = INCLUDE_RECIPE_DESCRIPTION ?
    "Description:" : "Ingredients:"

# Iterate over kitchen types
for (idx, kitchen_name) in enumerate(KITCHEN_NAMES)
    println("== Kitchen $idx : $kitchen_name ==")

    # Iterate over test problems for each kitchen type
    for problem_path in TEST_PROBLEMS[idx]
        println("-- Problem: $(basename(problem_path)) --")

        # Load problem and construct initial state
        problem = load_problem(problem_path)
        state = initstate(domain, problem)

        # Construct multi-kitchen context from context problems
        train_idxs = filter(!=(idx), 1:length(PROMPT_PROBLEMS))
        train_names = KITCHEN_NAMES[train_idxs]
        train_problems = PROMPT_PROBLEMS[train_idxs]
        n_train_kitchens = length(train_problems)
        n_train_recipes_per_kitchen = length(train_problems[1]) 
        context = construct_multikitchen_prompt(
            domain, train_problems, train_names, INSTRUCTION;
            include_english_description=INCLUDE_RECIPE_DESCRIPTION
        )

        # Construct kitchen description for test problem
        kitchen_desc = construct_kitchen_description(domain, problem)

        # Construct prompt from context and kitchen description
        prompt = (context * "KITCHEN: $(uppercase(kitchen_name))\n\n" *
                  kitchen_desc * "\n\n" * INSTRUCTION * "RECIPES\n\n" *
                  START_AND_STOP_STRING)
        
        println() 
        println("Prompt:\n")
        println(prompt)

        # Send prompt to GPT3 and get response
        println("---")
        println("Requesting $N_REPEATS completions through OpenAI API...")
        completions = gpt3_batch_complete(
            prompt, N_REPEATS, 10;
            stop=START_AND_STOP_STRING, max_tokens=256,
            model=MODEL, temperature=TEMPERATURE,
            verbose=true, persistent=true
        )
        println("---")

        # Iterate over multiple completions
        for (i, completion_obj) in enumerate(completions)
            # Extract completion text and logprobs (stop sequence has 2 tokens)
            completion, logprobs =
                extract_completion_text_and_logprobs(completion_obj, 2)
            completion = strip(START_AND_STOP_STRING * completion)
            println("-- Completion $i--")
            println(completion)
            # Try to parse to PDDL and English description
            result = try_parse_recipe(completion)
            if isnothing(result)
                pddl_goal, eng_goal = "", ""
                parse_success = false
            else
                pddl_goal, eng_goal = result
                pddl_goal = write_pddl(pddl_goal)
                parse_success = true
            end
            # Check if generated recipe is valid
            println()
            valid, reason =
                validate_recipe_string(completion, domain, state; verbose=true)
            println()
            println("Goal Validity: $valid")
            println("Validation Reason: $reason")
            println()
            row = Dict(
                :kitchen_id => idx,
                :kitchen_name => kitchen_name,
                :n_train_kitchens => n_train_kitchens,
                :n_train_recipes_per_kitchen => n_train_recipes_per_kitchen,
                :recipe_instruction => INSTRUCTION,
                :include_recipe_description => INCLUDE_RECIPE_DESCRIPTION,
                :problem => basename(problem_path),
                :kitchen_description => kitchen_desc,
                :completion => completion,
                :logprobs => logprobs,
                :pddl_goal => pddl_goal,
                :eng_goal => eng_goal,
                :temperature => TEMPERATURE,
                :model => MODEL,
                :parse_success => parse_success,
                :valid => valid,
                :reason => reason
            )
            push!(df, row)
        end
        CSV.write(df_path, df)
        println()
        println("Sleeping for 10s to avoid rate limit...")
        sleep(10.0)

        println()
    end
end
