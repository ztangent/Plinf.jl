using PDDL
using CSV, DataFrames, Statistics, StatsBase

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

# Define columns that correspond to experimental conditions
condition_cols = [:kitchen_name, :temperature, :n_train_recipes_per_kitchen]

# Read all CSV files that match format and concatenate them 
csv_paths = readdir(@__DIR__)
for path in csv_paths
    m = match(r"prompt_eval_multi_temp_.*\.csv", path)
    if isnothing(m)
        continue
    end
    path = joinpath(@__DIR__, path)
    next_df = CSV.read(path, DataFrame, types=df_types)
    df = vcat(df, next_df)
end

# Load dataframe
# df_path = "prompt_eval_multi_temp_0.25_nperkitchen_3_2022-12-06T22-23-49.csv"
# df_path = joinpath(@__DIR__, df_path)
# df = CSV.read(df_path, DataFrame, types=df_types)

# Post-hoc fix for errors in parse validation
# Make sure to compile parse_recipe and try_parse_recipe in prompt_eval_multi.jl before running this
function fix_parse_error(completion::String)
    result = try_parse_recipe(completion)
    if isnothing(result)
        pddl_goal, eng_goal = "", ""
        parse_success = false
    else
        pddl_goal, eng_goal = result
        pddl_goal = write_pddl(pddl_goal)
        parse_success = true
    end
    return pddl_goal, eng_goal, parse_success
end

transform!(df, :completion => ByRow(fix_parse_error) => [:pddl_goal, :eng_goal, :parse_success])
transform!(df, [:parse_success, :reason] => ByRow((x, y) -> x ? y : "Parse error") => :reason)

# Compute various extra information
transform!(df, :reason => (x -> x .== "Parse error") => :pddl_parse_error)
transform!(df, :reason => (x -> x .== "Non-existent predicates or types") => :non_existent_predicates)
transform!(df, :reason => (x -> x .== "Non-existent objects or variables") => :non_existent_objects)
transform!(df, :reason => (x -> x .== "Goal is not reachable") => :goal_unreachable)

# Group data frame by problems and conditions
problem_gdf = groupby(df, [condition_cols; :problem])
condition_gdf = groupby(df, condition_cols)

## Validity Metrics ##

# Define operations and columns
validity_cols =
    [:valid, :pddl_parse_error,
     :non_existent_predicates, :non_existent_objects, :goal_unreachable]
validity_sem_ops = reduce(vcat, ([col => mean, col => sem] for col in validity_cols))
validity_ops = [col => mean for col in validity_cols]
     
#  Compute validity metrics for each problem and condition
prob_validity_df = combine(problem_gdf, validity_ops...)

#  Compute average validity metrics for each condition
mean_validity_df = combine(condition_gdf, validity_ops...)

## Diversity Metrics ##

"Computes fraction of unique parseable goals."
function frac_unique_goals(pddl_parse_error, pddl_goal)
    parseable_goals = pddl_goal[.!pddl_parse_error]
    goals = parse_pddl.(parseable_goals)
    unique_goals = unique!(goals)
    return length(unique_goals) / length(pddl_goal)
end

"Computes fraction of unique valid goals."
function frac_unique_valid_goals(valid, pddl_goal)
    valid_goals = pddl_goal[valid]
    goals = parse_pddl.(valid_goals)
    unique_goals = unique!(goals)
    return length(unique_goals) / length(pddl_goal)
end

"Computes entropy of valid goals."
function entropy_of_valid_goals(valid, logprobs)
    logprobs = logprobs[valid]
    return isempty(logprobs) ? 0.0 : -mean(logprobs)
end

diversity_cols =
    [:frac_unique, :frac_unique_valid, :entropy_valid]

# Compute diversity metrics for each problem and condition
prob_diversity_df = combine(problem_gdf,
    [:pddl_parse_error, :pddl_goal] => frac_unique_goals => :frac_unique,
    [:valid, :pddl_goal] => frac_unique_valid_goals => :frac_unique_valid,
    [:valid, :logprobs] => entropy_of_valid_goals => :entropy_valid
)

# Average diversity metrics over problems within each condition
diversity_gdf = groupby(prob_diversity_df, condition_cols)
mean_diversity_df = combine(diversity_gdf, [col => mean => col for col in diversity_cols])

## Merge Results ##

# Merge validity and diversity results for each problem
prob_df = innerjoin(prob_validity_df, prob_diversity_df, on=[condition_cols; :problem])
transform!(prob_df, [:frac_unique_valid, :valid_mean] => ((x, y) -> x./y) => :frac_unique_out_of_valid)

# Merge validity and diversity results for each condition
mean_df = innerjoin(mean_validity_df, mean_diversity_df, on=condition_cols)
transform!(mean_df, [:frac_unique_valid, :valid_mean] => ((x, y) -> x./y) => :frac_unique_out_of_valid)

# Write out files
prob_df_path = joinpath(@__DIR__, "analysis_multi_per_problem.csv")
CSV.write(prob_df_path, prob_df)
mean_df_path = joinpath(@__DIR__, "analysis_multi_per_condition.csv")
CSV.write(mean_df_path, mean_df)
