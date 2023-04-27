## Script for generating inference survey questions from recipe descriptions ##

using CSV, DataFrames, Dates

include("load_plan.jl")
include("load_goals.jl")
include("recipe_writing.jl")

"Convert kitchen description to formatted HTML for display in web survey."
function kitchen_to_html(name::AbstractString, description::AbstractString)
    title = "<b>KITCHEN: $(uppercase(name))</b>"
    lines = split(description, "\n")
    lines = map(lines) do line
        line = strip(line) # Remove trailing spaces
        replace(line, r"([ \w]+:)" => s"<b>\1</b>") # Bold line heading
    end
    html_desc = join(lines, "<br>") # Add HTML linebreaks
    html_desc = title * "<br><br>" * html_desc # Prepend title
    return html_desc
end

"Convert recipe to formatted HTML for display in web survey."
function recipe_to_html(recipe::AbstractString)
    recipe = strip(recipe)
    lines = split(recipe, "\n")
    lines = map(lines) do line
        line = strip(line) # Remove trailing spaces
        replace(line, r"(\w+:)" => s"<b>\1</b>") # Bold line heading
    end    
    html_recipe = join(lines, "<br>") # Add HTML linebreaks
    return html_recipe
end

"Convert narrative steps to formatted HTML for display in web survey."
function narrative_to_html(narrative::AbstractVector{<:AbstractString})
    lines = map(narrative) do line
        return "<li>$(strip(line))</li>" # Surround in <li> tags
    end    
    html_narrative = "<ol>" * join(lines) * "</ol>" # Surround in <ol> tags
    return html_narrative
end

# Kitchen names
KITCHEN_NAMES = [
    "salad bar", 
    "sushi bar",
    "delicatessen",
    "pizzeria",
    "fruits and desserts"
]

N_GOALS_PER_PROBLEM = 5
MAX_STEPS_PER_PLAN = 9

DOMAIN_DIR = @__DIR__
PROBLEM_DIR = joinpath(@__DIR__, "problems")
GOALS_DIR = joinpath(@__DIR__, "goals")
PLANS_DIR = joinpath(@__DIR__, "plans")

# Load domain
domain = load_domain(joinpath(DOMAIN_DIR, "domain.pddl"))

# Find problems, goals, and plans
problem_paths = filter(readdir(PROBLEM_DIR, join=true)) do path
    match(r"problem-\d-\d.pddl", path) !== nothing
end
goals_paths = filter(readdir(GOALS_DIR, join=true)) do path
    match(r"goals-\d-\d.pddl", path) !== nothing
end
plan_paths = [joinpath(PLANS_DIR, "problem-$i-$j", "narrative-plan-$i-$j-1.pddl")
              for i in 1:5 for j in 1:5]

# Initialize data frame
loop_merge_df = DataFrame(
    kitchen_name=String[],
    kitchen_id=Int[],
    problem_id=Int[],
    n_steps=Int[],
    html_kitchen=String[];
    (Symbol("html_recipe_$i") => String[] for i in 1:N_GOALS_PER_PROBLEM)...,
    (Symbol("step_$i") => String[] for i in 1:MAX_STEPS_PER_PLAN)...
)

# Iterate over problems, goals, and plans
for (probpath, goalpath, planpath) in zip(problem_paths, goals_paths, plan_paths)
    # Parse kitchen and problem ID from filename
    m = match(r"problem-(\d+)-(\d+)\.pddl", basename(probpath))
    kitchen_id, problem_id = Tuple(parse.(Int, m.captures))
    kitchen_name = KITCHEN_NAMES[kitchen_id]
    # Construct HTML kitchen description from problem
    problem = load_problem(probpath)
    kitchen_desc = construct_kitchen_description(domain, problem)
    html_kitchen = kitchen_to_html(kitchen_name, kitchen_desc)
    # Convert goals / recipes to HTML
    descriptions, goals = load_goals(goalpath)
    html_recipes = map(zip(descriptions, goals)) do (desc, goal)
        construct_recipe_description(goal, desc) |> recipe_to_html
    end
    # Convert plan annotations / narratives to HTML
    plan, annotations, _ = load_plan(planpath)
    n_steps = length(annotations)
    html_steps = map(eachindex(annotations)) do t
        narrative_to_html(annotations[1:t])
    end
    # Construct and append row
    row = Dict(
        :kitchen_name => kitchen_name,
        :kitchen_id => kitchen_id,
        :problem_id => problem_id,
        :n_steps => n_steps,
        :html_kitchen => html_kitchen,
        (Symbol("html_recipe_$i") => recipe for (i, recipe) in enumerate(html_recipes))...,
        (Symbol("step_$i") => step for (i, step) in enumerate(html_steps))...,
    )
    push!(loop_merge_df, row, cols=:subset)
end

# Write recipes to path
datetime = Dates.format(Dates.now(), "yyyy-mm-ddTHH-MM-SS")
df_path = "loop_merge_inference_$(datetime).csv"
df_path = joinpath(@__DIR__, df_path)
CSV.write(df_path, loop_merge_df)
