# Recipe inference with GPT-3 given known options #

using PDDL, SymbolicPlanners
using Gen, GenGPT3
using CSV, DataFrames, Dates
using Random
using Printf

using GenParticleFilters: softmax

include("recipe_writing.jl")
include("recipe_inference_prompts.jl")
include("gpt3_complete.jl")
include("load_goals.jl")
include("load_plan.jl")

# Define directory paths
DOMAIN_DIR = @__DIR__
PROBLEM_DIR = joinpath(@__DIR__, "problems")
GOALS_DIR = joinpath(@__DIR__, "goals")
PLANS_DIR = joinpath(@__DIR__, "plans")

# Paths to problems to generate recipe descriptions for
PROBLEMS = [
    [joinpath(PROBLEM_DIR, "problem-$i-$j.pddl") for j in 1:5] for i in 1:5
]

GOALS = [
    [joinpath(GOALS_DIR, "goals-$i-$j.pddl") for j in 1:5] for i in 1:5
]

# Find plan paths
PLANS = [
    [joinpath(PLANS_DIR, "problem-$i-$j", "narrative-plan-$i-$j-1.pddl") for j in 1:5] for i in 1:5
]

# Inference prompt headers
INFERENCE_KITCHEN_HEADER = 
    "Someone is in a kitchen, and is about to make a dish. The following is a description of the kitchen."
INFERENCE_NARRATIVE_HEADER =
    "You now observe them taking the following actions:"
INFERENCE_QUESTION_TEXT =
    "Which of these recipes are they likely trying to make?"

# Whether to include English description of recipe in recipe description
INCLUDE_RECIPE_DESCRIPTION = true

# OpenAI model to use
MODEL = "text-davinci-002" # "davinci"

# Whether to use multishot inference
MULTISHOT = true

# Controls how many steps of the narrative to include in the prompt
TRAIN_STEP_MODE = :fixed
TRAIN_STEP_FRAC = 0.75

# Temperature range
TEMPERATURES = 2.0 .^ collect(-1:0.5:4)

# Kitchen names
KITCHEN_NAMES = [
    "salad bar", 
    "sushi bar",
    "delicatessen",
    "pizzeria",
    "fruits and desserts"
]

# Load PDDL domain and problem
domain = load_domain(joinpath(DOMAIN_DIR, "domain.pddl"))
problem = load_problem(joinpath(PROBLEM_DIR, "problem-1-5.pddl"))
kitchen_name = KITCHEN_NAMES[1]

# Load plan to do inference on 
plan, narrative, narrative_times =
    load_plan(joinpath(PLANS_DIR, "problem-1-5", "narrative-plan-1-5-1.pddl"))

# Load possible goals
descriptions, goals = load_goals(joinpath(GOALS_DIR, "goals-1-5.pddl"))
true_goal_idx = 1
true_goal = goals[true_goal_idx]

# Compute semantic overlap with true goal
goal_overlaps = [recipe_overlap(goals[true_goal_idx], g) for g in goals]

# Construct recipe descriptions
recipes = map(zip(descriptions, goals)) do (desc, goal)
    construct_recipe_description(goal, desc; 
                                 include_description=INCLUDE_RECIPE_DESCRIPTION)
end

# Test recipe inference prompt
prompt = construct_recipe_inference_prompt(
    domain, problem, narrative, 5, recipes, kitchen_name
)
println(prompt)
println("Token Count: ", length(GenGPT3.tokenize(prompt)))

# Construct training set
ref_idx = 5 # Index of reference problem for each kitchen
train_idxs = [2, 3, 4, 5]
train_names = KITCHEN_NAMES[train_idxs]
train_problems = [load_problem(ps[ref_idx]) for ps in PROBLEMS[train_idxs]]
train_narratives = [load_plan(ps[ref_idx])[2] for ps in PLANS[train_idxs]]
train_recipes = map(GOALS[train_idxs]) do gs
    descs, goals = load_goals(gs[ref_idx])
    map(zip(descs, goals)) do (desc, goal)
        construct_recipe_description(
            goal, desc; 
            include_description=INCLUDE_RECIPE_DESCRIPTION
        )
    end
end
train_correct_ids = [1, 1, 1, 1]

# Test multishot recipe inference prompt
prompt = construct_multishot_recipe_inference_prompt(
    domain,
    train_problems, train_narratives, train_recipes,
    train_correct_ids, train_names,
    problem, narrative, 5, recipes, kitchen_name;
    train_step_mode=TRAIN_STEP_MODE,
    train_step_frac=TRAIN_STEP_FRAC
)
println(prompt)
println("Token Count: ", length(GenGPT3.tokenize(prompt)))

df = DataFrame(
    :kitchen_id => Int[],
    :kitchen_name => String[],
    :problem => String[],
    :multishot => Bool[],
    :train_step_mode => Symbol[],
    :train_step_frac => Float64[],
    :temperature => Float64[],
    :randperm_seed => Int[],
    :step => Int[],
    :timestep => Int[],
    :systime => Float64[],
    :narrative => String[],
    (Symbol("goal_logprobs_$i") => Float64[] for i in 1:5)...,
    (Symbol("goal_probs_$i") => Float64[] for i in 1:5)...,
    :true_goal_probs => Float64[],
    :true_overlap => Float64[],
    :brier_score => Float64[]
)

# Define recipe permutation
rng = MersenneTwister(0)
recipe_perm = randperm(rng, length(recipes))

MULTISHOT = true

# Iterate over narrative steps
for (step, timestep) in [(0, 0); collect(enumerate(narrative_times))]
    # Construct initial prompt from training set and test problem
    if MULTISHOT
        prompt = construct_multishot_recipe_inference_prompt(
            domain,
            train_problems, train_narratives, train_recipes,
            train_correct_ids, train_names,
            problem, narrative, step, recipes[recipe_perm], kitchen_name;
            train_step_mode=TRAIN_STEP_MODE,
            train_step_frac=TRAIN_STEP_FRAC
        )
    else
        prompt = construct_recipe_inference_prompt(
            domain, problem, narrative, step,
            recipes[recipe_perm], kitchen_name
        )
    end
    if step == 0
        println("Prompt:\n")
        println(prompt, "\n")
        narrative_line = ""
    else
        narrative_line = narrative[step]
        println("$(step). ", narrative_line)
    end

    # Evaluate completion probabilities
    option_chars = [" " * Char(64 + i) for i in 1:length(recipes)]
    goal_logprobs = gpt3_eval_next_token_logprobs(
        prompt, option_chars; model=MODEL
    )
    # Unpermute logprobs
    goal_logprobs = goal_logprobs[invperm(recipe_perm)]
    # Compute goal probabilities
    goal_probs = softmax(goal_logprobs)
    # Print completion logprobs
    for p in goal_logprobs
        @printf("%.3f\t", p)
    end
    # Print completion probabilities
    print("\t")
    for p in goal_probs
        @printf("%.3f\t", p)
    end
    println()

    # Record current time
    systime = time()

    # Iterate over different temperatures and renormalize
    orig_goal_logprobs = copy(goal_logprobs)
    for temperature in TEMPERATURES
        # Compute temperature-adjusted logprobs
        goal_logprobs = orig_goal_logprobs ./ temperature
        # Compute goal probabilities
        goal_probs = softmax(goal_logprobs)
        # Compute true goal probability
        true_goal_probs = goal_probs[true_goal_idx]
        # Compute semantic overlap with respect to true goal
        true_overlap = sum(goal_probs .* goal_overlaps)
        # Compute Brier score with respect to true goal
        is_true_goal = zero(goal_probs)
        is_true_goal[true_goal_idx] = 1.0
        brier_score = sum((is_true_goal .- goal_probs).^2)

        # Construct and append row
        row = Dict(
            :kitchen_id => 1,
            :kitchen_name => kitchen_name,
            :problem => "problem-1-5.pddl",
            :multishot => MULTISHOT,
            :train_step_mode => TRAIN_STEP_MODE,
            :train_step_frac => TRAIN_STEP_FRAC,
            :temperature => temperature,
            :randperm_seed => 0,
            :step => step,
            :timestep => timestep,
            :systime => systime,
            :narrative => narrative_line,
            (Symbol("goal_logprobs_$i") => lp for (i, lp) in enumerate(goal_logprobs))...,
            (Symbol("goal_probs_$i") => p for (i, p) in enumerate(goal_probs))...,
            :true_goal_probs => true_goal_probs,
            :true_overlap => true_overlap,
            :brier_score => brier_score
        )
        push!(df, row)
    end
end

sort!(df, [:temperature])
