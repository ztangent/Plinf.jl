using PDDL, SymbolicPlanners
using CSV, DataFrames, Dates
using Gen, GenGPT3
using Random
using Serialization

include("gpt3_complete.jl")
include("goal_validation.jl")
include("recipe_writing.jl")
include("recipe_parsing.jl")
include("recipe_prompts.jl")

DOMAIN_DIR = @__DIR__
PROBLEM_DIR = joinpath(@__DIR__, "problems")
GOALS_DIR = joinpath(@__DIR__, "goals")
PLANS_DIR = joinpath(@__DIR__, "plans")

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

# Whether to include recipe description in completion
INCLUDE_RECIPE_DESCRIPTION = true

# Recipe cache
# GPT3_RECIPE_CACHE_PATH = joinpath(@__DIR__, "gpt3_recipe_cache.jls")
GPT3_RECIPE_CACHE = Dict{Tuple{Int, String, String}, GPT3ISTrace}()

"Recipe validator for a PDDL domain and state."
@kwdef mutable struct RecipeValidator
    domain::Domain
    state::State
    heuristic::Heuristic = memoized(precomputed(HMax(), domain, state))
    start_sequence::String = "Description:"
    verbose::Bool = false
end

RecipeValidator(domain::Domain, state::State; kwargs...) =
    RecipeValidator(;domain = domain, state = state, kwargs...)

function (validator::RecipeValidator)(completion::String)
    completion = strip(validator.start_sequence * completion)
    if validator.verbose
        println()
        println(completion)
        println()
    end
    # Try to parse to PDDL and English description
    result = try_parse_recipe(completion)
    if isnothing(result)
        if validator.verbose println("INVALID: Could not parse recipe to PDDL.") end
        return false
    end
    recipe, _ = result
    # Check if generated PDDL goal is valid
    valid = validate_predicates_and_types(recipe, validator.domain)
    if !valid
        if validator.verbose println("INVALID: Invalid predicates or types.") end
        return false
    end
    valid = validate_objects(recipe, validator.domain, validator.state)
    if !valid
        if validator.verbose println("INVALID: Invalid objects.") end
        return false
    end
    hval = validator.heuristic(validator.domain, validator.state, recipe)
    if hval == Inf
        if validator.verbose println("INVALID: Recipe is unreachable") end
        return false
    end
    return true
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

function construct_gpt3_recipe_prior(
    domain::Domain, state::State, n_samples::Int=50;
    model_prompt = construct_recipe_prior_prompt(domain, state),
    proposal_prompt = model_prompt,
    include_description = INCLUDE_RECIPE_DESCRIPTION, 
    model_stop = include_description ? "Description:" : "Ingredients:",
    proposal_stop = "===",
    model_name = MODEL,
    proposal_name = model_name,
    model_temp = TEMPERATURE,
    proposal_temp = model_temp,
    cache = GPT3_RECIPE_CACHE,
    verbose::Bool = false
)
    # Construct recipe validator
    start_sequence = include_description ? "Description:" : "Ingredients:"
    validator = RecipeValidator(domain, state; verbose=verbose,
                                start_sequence = start_sequence)
    # Construct GPT-3 importance sampler with validator
    model_gf = MultiGPT3GF(model=model_name, max_tokens=160,
                           stop=model_stop, temperature=model_temp)
    proposal_gf = model_prompt == proposal_prompt ?
        model_gf : MultiGPT3GF(model=proposal_name, max_tokens=160,
                               stop=proposal_stop, temperature=proposal_temp)
    gpt3_is = GPT3IS(
        model_gf = model_gf,
        proposal_gf = proposal_gf,
        cache_traces = true,
        cache = cache,
        validator = validator,
        max_samples = 50
    )
    # Construct wrapper generative function
    @gen function gpt3_recipe_prior(proposal_prompt = proposal_prompt)
        m_prompt = model_prompt * start_sequence
        p_prompt = proposal_prompt * start_sequence
        completion ~ gpt3_is(n_samples, m_prompt, p_prompt)
        completion = strip(start_sequence * completion)
        result = try_parse_recipe(completion)
        recipe = isnothing(result) ? nothing : result[1]
        return add_served(Specification(recipe))
    end
    return gpt3_recipe_prior
end
