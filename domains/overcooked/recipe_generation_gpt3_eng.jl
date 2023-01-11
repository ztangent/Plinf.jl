using PDDL
using CSV, DataFrames, Dates

include("gpt3_complete.jl")
include("goal_validation.jl")
include("recipe_writing.jl")
include("recipe_parsing.jl")

## Recipe validation

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
    domain::Domain, problem_sets, kitchen_names, instruction=""
)
    prompt = ""
    for (problem_paths, name) in zip(problem_sets, kitchen_names)
        reference_problem = load_problem(problem_paths[end])
        kitchen = construct_kitchen_description(domain, reference_problem)
        recipes = map(problem_paths) do path
            prob = load_problem(path)
            desc_path = path[1:end-5] * ".txt"
            desc = load_english_recipe_description(desc_path)
            return construct_recipe_description(domain, prob, desc)
        end
        str = "KITCHEN: $(uppercase(name))\n\n" * kitchen * "\n\n" * instruction *
              "RECIPES\n\n" * join(recipes, "\n\n")
        prompt *= str * "\n\n"
    end
    return prompt
end

## Test multi-kitchen prompt construction from last two problems of each kitchen

prompt = construct_multikitchen_prompt(
    domain,
    [
        [joinpath(@__DIR__, "problem-1-4.pddl"), joinpath(@__DIR__, "problem-1-5.pddl")],
        [joinpath(@__DIR__, "problem-2-4.pddl"), joinpath(@__DIR__, "problem-2-5.pddl")],
        [joinpath(@__DIR__, "problem-3-4.pddl"), joinpath(@__DIR__, "problem-3-5.pddl")],
        [joinpath(@__DIR__, "problem-4-4.pddl"), joinpath(@__DIR__, "problem-4-5.pddl")],
        [joinpath(@__DIR__, "problem-5-4.pddl"), joinpath(@__DIR__, "problem-5-5.pddl")],
    ],
    ["salad bar", "sushi bar", "delicatassen", "pizzeria", "patisserie"]
)

## Script options ##

# Recipe generation instruction (defaults to empty string)
INSTRUCTION =
    "Below is a list of recipes that can be made using only the " *
    "ingredients, receptacles, tools, appliances, and methods in this kitchen.\n\n"

# Kitchen names
KITCHEN_NAMES = [
    "salad bar", 
    "sushi bar",
    "delicatessen",
    "pizzeria",
    "patisserie"
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
PROMPT_PROBLEMS = [joinpath.(@__DIR__, pset) for pset in PROMPT_PROBLEMS]

# Paths to problems to test goal generation on
TEST_PROBLEMS = [
    ["problem-1-1.pddl", "problem-1-2.pddl", "problem-1-3.pddl", "problem-1-4.pddl", "problem-1-5.pddl"],
    ["problem-2-1.pddl", "problem-2-2.pddl", "problem-2-3.pddl", "problem-2-4.pddl", "problem-2-5.pddl"],
    ["problem-3-1.pddl", "problem-3-2.pddl", "problem-3-3.pddl", "problem-3-4.pddl", "problem-3-5.pddl"],
    ["problem-4-1.pddl", "problem-4-2.pddl", "problem-4-3.pddl", "problem-4-4.pddl", "problem-4-5.pddl"],
    ["problem-5-1.pddl", "problem-5-2.pddl", "problem-5-3.pddl", "problem-5-4.pddl", "problem-5-5.pddl"],
]
TEST_PROBLEMS = [joinpath.(@__DIR__, pset) for pset in TEST_PROBLEMS]

# Number of completions per prompt
N_REPEATS = 50

# Temperature of generated completion
TEMPERATURE = 1.0

# Initialize data frame
df = DataFrame(
    kitchen_id=Int[],
    kitchen_name=String[],
    n_train_kitchens=Int[],
    n_train_recipes_per_kitchen=Int[],
    recipe_instruction=String[],
    problem=String[],
    description=String[],
    temperature=Float64[],
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
df_path = "recipes_gpt3_eng_" * "temp_$(TEMPERATURE)_" *
          "nperkitchen_$(n_per_kitchen)" * "_$(datetime).csv"
df_path = joinpath(@__DIR__, df_path)

# Load domain
domain = load_domain(joinpath(@__DIR__, "domain.pddl"))

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
        context = construct_multikitchen_prompt(domain, train_problems, train_names, INSTRUCTION)

        # Construct kitchen description for test problem
        kitchen_desc = construct_kitchen_description(domain, problem)

        # Construct prompt from context and kitchen description
        prompt = (context * "KITCHEN: $(uppercase(kitchen_name))\n\n" *
                  kitchen_desc * "\n\n" * INSTRUCTION * "RECIPES\n\nDescription:")
        
        println() 
        println("Prompt:\n")
        println(prompt)

        # Send prompt to GPT3 and get response
        println("---")
        println("Requesting $N_REPEATS completions through OpenAI API...")
        completions = gpt3_batch_complete(
            prompt, N_REPEATS, 10;
            stop="Description:", temperature=TEMPERATURE,
            verbose=true, persistent=true
        )
        println("---")

        # Iterate over multiple completions
        for (i, completion_obj) in enumerate(completions)
            # Extract completion text
            completion = completion_obj.text 
            completion = strip("Description:" * completion)
            println("-- Completion $i--")
            println(completion)
            # Extract log probability (stop sequence has 2 tokens)
            logprobs = extract_logprobs(completion_obj, 2)
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
                :problem => basename(problem_path),
                :description => kitchen_desc,
                :completion => completion,
                :logprobs => logprobs,
                :pddl_goal => pddl_goal,
                :eng_goal => eng_goal,
                :temperature => TEMPERATURE,
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
