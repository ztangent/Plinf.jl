using PDDL, SymbolicPlanners
using CSV, DataFrames, Dates

include("goal_validation.jl")
include("gpt3_complete.jl")

## Helper functions ##

"Constructs a kitchen description from a PDDL problem."
function construct_kitchen_description(
    domain::Domain, problem::Problem
)
    # Construct initial state
    state = initstate(domain, problem)
    # List food ingredients
    ingredients = sort!(string.(PDDL.get_objects(state, :ftype)))
    ingredients_str = "Ingredients: " * join(ingredients, ", ")
    # List receptacles
    receptacles = sort!(string.(PDDL.get_objects(state, :rtype)))
    receptacles_str = "Receptacles: " * join(receptacles, ", ")
    # List tools
    # List appliances
    # List preparation methods
    query = pddl"(has-prepare-method ?method ?rtype ?ttype)"
    prepare_methods = String[]
    for subst in satisfiers(domain, state, query)
        method = subst[pddl"(?method)"]
        rtype = subst[pddl"(?rtype)"]
        ttype = subst[pddl"(?ttype)"]
        str = "$method (using $ttype with $rtype)"
        push!(prepare_methods, str)
    end
    prepare_methods = isempty(prepare_methods) ?
        "none" :  join(sort!(prepare_methods), ", ")
    prepare_str = "Preparation Methods: " * prepare_methods
    # List combination methods
    # List cooking methods
    # Concatenate all lines into kitchen description
    description = join([ingredients_str, receptacles_str, prepare_str], "\n")
    return description
end

"Constructs a recipe description from a PDDL problem."
function construct_recipe_description(
    domain::Domain, problem::Problem
)
    # Extract goal from problem
    goal = PDDL.get_goal(problem)
    # 
end

# Load domain and problem 1-1
domain = load_domain(joinpath(@__DIR__, "domain.pddl"))
problem = load_problem(joinpath(@__DIR__, "problem-1-5.pddl"))

s = construct_kitchen_description(domain, problem)
