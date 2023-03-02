using PDDL
using CSV, DataFrames, Statistics, StatsBase

# Initialize data frame
df = DataFrame(
    kitchen_id=Int[],
    kitchen_name=String[],
    problem=String[],
    description=String[],
    goal_prompt=String[],
    header=String[],
    examples=String[],
    use_predicates=Bool[],
    use_actions=Bool[],
    use_objects=Bool[],
    use_init=Bool[],
    temperature=Float64[],
    n_examples=Int[],
    example_type=Symbol[],
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
condition_cols = [:kitchen_name, :use_predicates, :use_actions, :use_objects, :use_init,
                  :temperature, :example_type]

# Load dataframe
df_path = "prompt_eval_temp_1.0_options_0001_example_type_eng_pddl_2022-12-12T00-24-53.csv"
df_path = joinpath(@__DIR__, df_path)
df = CSV.read(df_path, DataFrame, types=df_types)

# Compute various extra information
transform!(df, :parse_success => (x -> .!x) => :gpt3_parse_error)
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
prob_df_path = joinpath(@__DIR__, "analysis_per_problem_gpt3_pddl.csv")
CSV.write(prob_df_path, prob_df)
mean_df_path = joinpath(@__DIR__, "analysis_per_condition_gpt3_pddl.csv")
CSV.write(mean_df_path, mean_df)
