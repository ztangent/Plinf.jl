## Script for generating survey questions from recipe descriptions ##

using CSV, DataFrames, Dates

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
    lines = split(recipe, "\n")[2:end] # Remove description line
    lines = map(lines) do line
        line = strip(line) # Remove trailing spaces
        replace(line, r"(\w+:)" => s"<b>\1</b>") # Bold line heading
    end    
    html_recipe = join(lines, "<br>") # Add HTML linebreaks
    return html_recipe
end

# Initialize data frame
survey_df = DataFrame(
    kitchen_id=Int[],
    kitchen_name=String[],
    kitchen_desc=String[],
    problem=String[],
    source=String[],
    recipe_desc=String[],
    recipe=String[],
    html_recipe=String[],
    valid=Bool[],
    reason=String[]
)


# Paths to recipe source files
RECIPE_PATHS = [
    joinpath(@__DIR__, "recipes_baseline_2023-01-22T13-26-42.csv"),
    joinpath(@__DIR__, "recipes_gpt3_eng_text-davinci-003_temp_1.0_nperkitchen_3_2023-01-22T14-31-25.csv"),
    joinpath(@__DIR__, "recipes_handcrafted_2023-01-22T13-20-42.csv"),
]

# Names of recipe sources
RECIPE_SOURCES = [
    "baseline",
    "gpt3_eng",
    "handcrafted",
]

# Number of recipes to use from each source
N_RECIPES_PER_SOURCE = 5

# Old and new column names
OLD_NAMES = [:kitchen_id, :kitchen_name, :problem, :description, :eng_goal, :completion, :valid, :reason]
NEW_NAMES = [:kitchen_id, :kitchen_name, :problem, :kitchen_desc, :recipe_desc, :recipe, :valid, :reason]

# Iterate over recipe sources and convert each recipe to HTML
for (path, source) in zip(RECIPE_PATHS, RECIPE_SOURCES)
    # Load recipes 
    recipes_df = CSV.read(path, DataFrame)
    # Group by problem file name
    grouped_df = groupby(recipes_df, :problem)
    # Iterate over groups 
    for group in grouped_df
        # Filter out recipes with parse errors
        group = filter(row -> row.reason != "Parse error", group)
        # Extract first few recipes and rename columns
        sub_df = group[1:N_RECIPES_PER_SOURCE, OLD_NAMES]
        rename!(sub_df, NEW_NAMES)
        # Add source column
        sub_df.source .= source
        # Add HTML version of recipe
        sub_df.html_recipe .= recipe_to_html.(sub_df.recipe)
        # Append to survey dataframe
        append!(survey_df, sub_df, promote=true)
    end
end
# Sort by problem and source
sort!(survey_df, [:problem, :source])

# Write recipes to path
datetime = Dates.format(Dates.now(), "yyyy-mm-ddTHH-MM-SS")
df_path = "survey_recipes_$(datetime).csv"
df_path = joinpath(@__DIR__, df_path)
CSV.write(df_path, survey_df)

# Convert recipes to Qualtrics loop-and-merge matrix, one row per problem

N_RECIPES_PER_PROBLEM = N_RECIPES_PER_SOURCE * length(RECIPE_SOURCES)

loop_merge_df = DataFrame(
    "html_kitchen" => String[],
    ("html_recipe_$i" => String[] for i in 1:N_RECIPES_PER_PROBLEM)...
)

for group in groupby(survey_df, :problem)
    kitchen_name = group[1, :kitchen_name]
    kitchen_desc = group[1, :kitchen_desc]
    html_kitchen = kitchen_to_html(kitchen_name, kitchen_desc)
    row = Dict("html_kitchen" => html_kitchen)
    for (i, recipe) in enumerate(group.html_recipe)
        row["html_recipe_$i"] = recipe
    end
    push!(loop_merge_df, row)
end

# Write  to path
datetime = Dates.format(Dates.now(), "yyyy-mm-ddTHH-MM-SS")
df_path = "loop_merge_recipes_$(datetime).csv"
df_path = joinpath(@__DIR__, df_path)
CSV.write(df_path, loop_merge_df)
