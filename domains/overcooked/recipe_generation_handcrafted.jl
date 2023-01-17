using PDDL
using CSV, DataFrames, Dates

include("load_goals.jl")
include("goal_validation.jl")
include("recipe_writing.jl")

# Kitchen names
KITCHEN_NAMES = [
    "salad bar", 
    "sushi bar",
    "delicatessen",
    "pizzeria",
    "patisserie"
]

# Paths to problems to generate recipe descriptions for
PROBLEMS = [
    ["problem-1-1.pddl", "problem-1-2.pddl", "problem-1-3.pddl", "problem-1-4.pddl", "problem-1-5.pddl"],
    ["problem-2-1.pddl", "problem-2-2.pddl", "problem-2-3.pddl", "problem-2-4.pddl", "problem-2-5.pddl"],
    ["problem-3-1.pddl", "problem-3-2.pddl", "problem-3-3.pddl", "problem-3-4.pddl", "problem-3-5.pddl"],
    ["problem-4-1.pddl", "problem-4-2.pddl", "problem-4-3.pddl", "problem-4-4.pddl", "problem-4-5.pddl"],
    ["problem-5-1.pddl", "problem-5-2.pddl", "problem-5-3.pddl", "problem-5-4.pddl", "problem-5-5.pddl"],
]
PROBLEMS = [joinpath.(@__DIR__, pset) for pset in PROBLEMS]

GOALS = [
    ["goals-1-1.pddl", "goals-1-2.pddl", "goals-1-3.pddl", "goals-1-4.pddl", "goals-1-5.pddl"],
    ["goals-2-1.pddl", "goals-2-2.pddl", "goals-2-3.pddl", "goals-2-4.pddl", "goals-2-5.pddl"],
    ["goals-3-1.pddl", "goals-3-2.pddl", "goals-3-3.pddl", "goals-3-4.pddl", "goals-3-5.pddl"],
    ["goals-4-1.pddl", "goals-4-2.pddl", "goals-4-3.pddl", "goals-4-4.pddl", "goals-4-5.pddl"],
    ["goals-5-1.pddl", "goals-5-2.pddl", "goals-5-3.pddl", "goals-5-4.pddl", "goals-5-5.pddl"],
]
GOALS = [joinpath.(@__DIR__, gset) for gset in GOALS]

# Initialize data frame
df = DataFrame(
    kitchen_id=Int[],
    kitchen_name=String[],
    problem=String[],
    description=String[],
    logprobs=Float64[],
    completion=String[],
    pddl_goal=String[],
    eng_goal=String[],
    valid=Bool[],
    reason=String[]
)
df_types = eltype.(eachcol(df))
datetime = Dates.format(Dates.now(), "yyyy-mm-ddTHH-MM-SS")
df_path = "recipes_handcrafted_$(datetime).csv"
df_path = joinpath(@__DIR__, df_path)

# Load domain
domain = load_domain(joinpath(@__DIR__, "domain.pddl"))

# Iterate over kitchen types
for (idx, kitchen_name) in enumerate(KITCHEN_NAMES)
    println("== Kitchen $idx : $kitchen_name ==")

    # Iterate over problems and goals for each kitchen type
    for (problem_path, goals_path) in zip(PROBLEMS[idx], GOALS[idx])
        println("-- Problem: $(basename(problem_path)) --")

        # Load problem and construct initial state
        problem = load_problem(problem_path)
        state = initstate(domain, problem)

        # Construct kitchen description for test problem
        kitchen_desc = construct_kitchen_description(domain, problem)

        # Load the set of goals and natural language descriptions
        descriptions, goals = load_goals(goals_path)

        # Construct recipes from hand-crafted PDDL goals
        for (i, (eng_goal, pddl_goal)) in enumerate(zip(descriptions, goals))
            # Convert PDDL to English recipe description
            completion = construct_recipe_description(pddl_goal, eng_goal)
            println("-- Goal $i--")
            println(completion)
            # Check if generated recipe is valid
            println()
            valid, reason = validate_goal(pddl_goal, domain, state; verbose=true)
            println()
            println("Goal Validity: $valid")
            println("Validation Reason: $reason")
            println()
            pddl_goal = write_pddl(pddl_goal)
            row = Dict(
                :kitchen_id => idx,
                :kitchen_name => kitchen_name,
                :problem => basename(problem_path),
                :description => kitchen_desc,
                :logprobs => NaN,
                :completion => completion,
                :pddl_goal => pddl_goal,
                :eng_goal => eng_goal, 
                :valid => valid,
                :reason => reason
            )
            push!(df, row)
        end
        CSV.write(df_path, df)
        println()
    end
end
