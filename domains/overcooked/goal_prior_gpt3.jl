using PDDL, SymbolicPlanners
using CSV, DataFrames, Dates

include("gpt3_complete.jl")
include("goal_validation.jl")
include("recipe_writing.jl")
include("recipe_parsing.jl")

DOMAIN_DIR = @__DIR__
PROBLEM_DIR = joinpath(@__DIR__, "problems")
GOALS_DIR = joinpath(@__DIR__, "goals")
PLANS_DIR = joinpath(@__DIR__, "plans")

# Recipe generation instruction 
INSTRUCTION =
    "Below is a wide variety of recipes that can be made using only the " *
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

# Paths to problems to generate recipe descriptions for
PROBLEMS = [
    [joinpath(PROBLEM_DIR, "problem-$i-$j.pddl") for j in 1:5] for i in 1:5
]

GOALS = [
    [joinpath(GOALS_DIR, "goals-$i-$j.pddl") for j in 1:5] for i in 1:5
]

# Number of completions per prompt
N_REPEATS = 50

# Temperature of generated completion
TEMPERATURE = 1.0

# Model to request completions from
MODEL = "text-davinci-003" # "davinci"

function construct_multikitchen_prompt(
    domain::Domain,
    problem_sets,
    kitchen_names = KITCHEN_NAMES,
    instruction = INSTRUCTION;
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

function generate_recipes(
    domain::Domain, problem_path::String, n_recipes::Int=50;
    train_idxs_per_problem = 3:5,
    instruction::String = INSTRUCTION,
    instruction_modifier::String = "",
    include_description::Bool = false,
    stop_sequence::String = include_description ? "Description:" : "Ingredients:",
    batch_size::Int = 10,
    model = MODEL,
    temperature::Float64 = TEMPERATURE,
    verbose::Bool = false
)
    # Load problem
    problem = load_problem(problem_path)
    problem_name = basename(problem_path)
    m = match(r"problem-(\d+)-(\d+).pddl", problem_name)
    kitchen_idx, problem_idx = parse.(Int, m.captures)
    kitchen_name = KITCHEN_NAMES[kitchen_idx]

    # Construct multi-kitchen context from context problems
    train_idxs = filter(!=(kitchen_idx), 1:length(PROBLEMS))
    train_names = KITCHEN_NAMES[train_idxs]
    train_paths = [PROBLEMS[i][train_idxs_per_problem] for i in train_idxs]
    context = construct_multikitchen_prompt(
        domain, train_paths, train_names, instruction;
        include_english_description=include_description
    )

    # Construct kitchen description for test problem
    kitchen_desc = construct_kitchen_description(domain, problem)

    # Construct prompt from context and kitchen description
    prompt = (context * "KITCHEN: $(uppercase(kitchen_name))\n\n" *
              kitchen_desc * "\n\n" * instruction * instruction_modifier *
              "RECIPES\n\n" * stop_sequence)

    # Construct initial state and reachability heuristic
    state = initstate(domain, problem)
    heuristic = memoized(precomputed(HMax(), domain, state))

    # Repeatedly request GPT-3 completions until quota is met
    recipes = Term[]
    while length(recipes) < n_recipes
        # Request completions
        n_remaining = n_recipes - length(recipes)
        if verbose println("Requesting $n_remaining completions...") end
        completions = gpt3_batch_complete(
            prompt, n_remaining, batch_size;
            stop=stop_sequence, max_tokens=256,
            model=model, temperature=temperature,
            verbose=verbose, persistent=true
        )
        # Collect valid recipes
        for (i, completion_obj) in enumerate(completions)
            # Extract completion text and logprobs (stop sequence has 2 tokens)
            completion = completion_obj.text
            completion = strip(stop_sequence * completion)
            if verbose
                println("-- Completion $i--")
                println(completion)
            end
            # Try to parse to PDDL and English description
            result = try_parse_recipe(completion)
            if isnothing(result)
                if verbose println("Could not parse recipe to PDDL.") end
                continue
            end
            recipe, _ = result
            # Check if generated PDDL goal is valid
            valid = validate_predicates_and_types(recipe, domain)
            if !valid
                if verbose println("Invalid predicates or types.") end
                continue
            end
            valid = validate_objects(recipe, domain, state)
            if !valid
                if verbose println("Invalid objects.") end
                continue
            end
            hval = heuristic(domain, state, recipe)
            if hval == Inf
                if verbose println("Recipe is unreachable") end
                continue
            end
            push!(recipes, recipe)
        end
    end
    return recipes
end

function construct_quantity_modifier(quantity::Int)
    template = "Unlike the previous kitchens, these recipes are small dishes " *
               "or sides that use only {QUANTITY}.\n\n"
    if quantity == 1
        str = replace(template, "{QUANTITY}" => "1 ingredient")
    elseif quantity > 1
        str = replace(template, "{QUANTITY}" => "$quantity ingredients")
    else
        error("Quantity must be positive.")
    end
    return str
end
construct_quantity_modifier(quantity::Nothing) = ""

const GPT3_RECIPE_CACHE = Dict{String, Vector{Term}}()

@gen function gpt3_recipe_prior(
    domain::Domain, problem_path::String,
    include_description::Bool = true,
    n_recipes::Int = 50, 
    gpt3_recipe_cache::Dict = GPT3_RECIPE_CACHE
)
    problem_name = basename(problem_path)[1:end-5]
    key = "$(problem_name)_$(include_description)"
    recipes = get!(gpt3_recipe_cache, key) do
        generate_recipes(domain, problem_path, n_recipes,
                         include_description=include_description)
    end
    recipe_id ~ uniform_discrete(1, n_recipes)
    return recipes[recipe_id]
end

const GPT3_STRATIFIED_RECIPE_CACHE = Dict{String, Vector{Term}}()

@gen function gpt3_stratified_recipe_prior(
    domain::Domain, problem_path::String,
    include_description::Bool = true,
    strata = ((1, 10), (2, 10), (nothing, 30)), 
    gpt3_recipe_cache::Dict = GPT3_STRATIFIED_RECIPE_CACHE
)
    problem_name = basename(problem_path)[1:end-5]
    key = "$(problem_name)_$(include_description)_$(strata)"
    recipes = get!(gpt3_recipe_cache, key) do
        rs = Term[]
        for (quantity, n_recipes) in strata
            modifier = construct_quantity_modifier(quantity)
            r = generate_recipes(domain, problem_path, n_recipes;
                                 instruction_modifier=modifier,
                                 include_description=include_description,
                                 verbose = true)
            append!(rs, r)
        end
        return rs
    end
    recipe_id ~ uniform_discrete(1, length(recipes))
    return recipes[recipe_id]
end
