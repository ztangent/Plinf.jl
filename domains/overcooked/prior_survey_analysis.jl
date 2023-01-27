using CSV, DataFrames, Statistics

# Names of recipe sources
RECIPE_SOURCES = [
    "baseline",
    "gpt3_eng",
    "handcrafted",
]

# Names of kitchens
KITCHEN_NAMES = [
    "salad bar", 
    "sushi bar",
    "delicatessen",
    "pizzeria",
    "fruits and desserts"
]

# Load data frame
df_path = "prior_survey_results.csv"
df_path = joinpath(@__DIR__, df_path)
df = CSV.read(df_path, DataFrame, header=2, skipto=4)

# Filter by comprehension check score
filter!(row -> row["Score"] >= 2, df)

# Filter column names that store recipe ratings
rating_cols = filter(names(df)) do name
    match(r"Kitchen-(\d+)-Goal-(\d+) - (\d+) - (\w+)", name) !== nothing
end

# Stack by rating columns
df = df[:, [["Response ID"]; rating_cols]]
stacked_df = stack(df, rating_cols)

# Compute mean and std across participants for each rating
agg_df = combine(groupby(stacked_df, :variable),
    :value => (x -> mean(skipmissing(x))) => :rating_mean,
    :value => (x -> std(skipmissing(x))) => :rating_std,
    :value => (x -> length(collect(skipmissing(x)))) => :n_ratings
)

# Transform rating field name to multiple fields
function parse_rating_name(names)
    matches = match.(r"Kitchen-(\d+)-Goal-(\d+) - (\d+) - (\w+)", names)
    kitchen_ids = map(m -> parse(Int, m.captures[1]), matches)
    kitchen_names = KITCHEN_NAMES[kitchen_ids]
    goal_ids = map(m -> parse(Int, m.captures[2]), matches)
    problem_ids = map(m -> parse(Int, m.captures[3]), matches)
    rating_types = map(m -> m.captures[4], matches)
    sources = map(goal_ids) do id
        source_id = div(id-1, 5) + 1
        return RECIPE_SOURCES[source_id]
    end
    return (kitchen_id=kitchen_ids, kitchen_name=kitchen_names,
            problem_id=problem_ids, goal_id=goal_ids,
            source=sources, rating_type=rating_types)
end

df = transform(stacked_df, :variable => parse_rating_name => AsTable)
select!(df, [1, 4:9..., 3]) # Reorder columns

# Compute mean ratings for each source
source_gdf = groupby(df, [:source, :rating_type])
source_df = combine(source_gdf,
    :value => (x -> x |> skipmissing |> mean) => :rating_mean,
    :value => (x -> x |> skipmissing |> std)  => :rating_std,
    :value => (x -> (x |> skipmissing |> std) / sqrt(length(collect(skipmissing(x))))) => :rating_sem
)
transform!(source_df, :rating_sem => (x -> 1.96 .* x) => :rating_ci)
source_df_path = joinpath(@__DIR__, "prior_survey_analysis_per_source.csv")
CSV.write(source_df_path, source_df)

# Compute mean ratings for each source and kitchen type
kitchen_gdf = groupby(df, [:source, :kitchen_name, :rating_type])
kitchen_df = combine(kitchen_gdf,
    :value => (x -> x |> skipmissing |> mean) => :rating_mean,
    :value => (x -> x |> skipmissing |> std)  => :rating_std,
    :value => (x -> (x |> skipmissing |> std) / sqrt(length(collect(skipmissing(x))))) => :rating_sem
)
transform!(kitchen_df, :rating_sem => (x -> 1.96 .* x) => :rating_ci)
kitchen_df_path = joinpath(@__DIR__, "prior_survey_analysis_per_kitchen.csv")
CSV.write(kitchen_df_path, kitchen_df)

# Compute mean ratings for each source and problem
problem_gdf = groupby(df, [:source, :kitchen_name, :problem_id, :rating_type])
problem_df = combine(problem_gdf,
    :value => (x -> x |> skipmissing |> mean) => :rating_mean,
    :value => (x -> x |> skipmissing |> std)  => :rating_std,
    :value => (x -> (x |> skipmissing |> std) / sqrt(length(collect(skipmissing(x))))) => :rating_sem
)
problem_df_path = joinpath(@__DIR__, "prior_survey_analysis_per_problem.csv")
CSV.write(problem_df_path, problem_df)
