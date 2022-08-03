using PDDL
using CSV, DataFrames, Statistics, StatsBase

N_REPEATS = 10

# Initialize data frame
df = DataFrame(
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
    pddl_goal=String[],
    eng_goal=String[],
    parse_success=Bool[],
    valid=Bool[],
    reason=String[]
)
df_types = eltype.(eachcol(df))


# Define columns that correspond to experimental conditions
condition_cols = [:use_predicates, :use_actions, :use_objects, :use_init,
                   :temperature, :example_type]

# Load dataframe
df_path = "domains/overcooked/prompt_eval_eng_pddl_temp_0.7.csv"
df = CSV.read(df_path, DataFrame, types=df_types)

# Compute various extra information
transform!(df, :parse_success => (x -> .!x) => :gpt3_parse_error)
transform!(df, :reason => (x -> x .== "Parse error") => :pddl_parse_error)
transform!(df, :reason => (x -> x .== "Non-existent predicates or types") => :non_existent_predicates)
transform!(df, :reason => (x -> x .== "Non-existent objects or variables") => :non_existent_objects)
transform!(df, :reason => (x -> x .== "Goal is not reachable") => :goal_unreachable)

# Group dataframe by header options
gdf = groupby(df, condition_cols)

# Take mean and std dev of columns of interest 
mean_cols = [:valid, :gpt3_parse_error, :pddl_parse_error,
             :non_existent_predicates, :non_existent_objects, :goal_unreachable]
mean_sem_ops = reduce(vcat, ([col => mean, col => sem] for col in mean_cols))
mean_ops = [col => mean for col in mean_cols]
mean_df = combine(gdf, mean_ops...)

"Computes number of unique parseable goals."
function n_unique_goals(pddl_parse_error, pddl_goal)
    parseable_goals = pddl_goal[.!pddl_parse_error]
    goals = parse_pddl.(parseable_goals)
    unique_goals = unique!(goals)
    return length(unique_goals)
end

"Computes number of unique valid goals."
function n_unique_valid_goals(valid, pddl_goal)
    valid_goals = pddl_goal[valid]
    goals = parse_pddl.(valid_goals)
    unique_goals = unique!(goals)
    return length(unique_goals)
end

# Compute uniqueness metric for each set of header options and problems
prob_df = groupby(df, [condition_cols; :problem])
unique_df = combine(prob_df,
    [:pddl_parse_error, :pddl_goal] => n_unique_goals => :n_unique,
    [:valid, :pddl_goal] => n_unique_valid_goals => :n_unique_valid)
unique_gdf = groupby(unique_df, condition_cols)
unique_mean_df = combine(unique_gdf,
    :n_unique => (x -> mean(x) / N_REPEATS) => :frac_unique,
    :n_unique_valid => (x -> mean(x) / N_REPEATS) => :frac_unique_valid,
)

## Merge uniqueness and correctness results
joined_df = innerjoin(mean_df, unique_mean_df,
                      on=condition_cols)
transform!(joined_df,
           [:frac_unique_valid, :valid_mean] => ((x, y) -> x./y) => :frac_unique_out_of_valid)

joined_df_path = joinpath(@__DIR__, "analysis_eng_pddl_temp_0.7.csv")
CSV.write(joined_df_path, joined_df)
