using PDDL
using CSV, DataFrames, Statistics, StatsBase

# Initialize data frame
df = DataFrame(
    kitchen_id=Int[],
    kitchen_name=String[],
    n_train_kitchens=Int[],
    n_train_recipes_per_kitchen=Int[],
    recipe_instruction=String[],
    recipe_summary_in_prompt=Bool[],
    problem=String[],
    description=String[],
    temperature=Float64[],
    model=String[],
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
condition_cols = [:model, :include_recipe_description]

# Load dataframes

# GPT-3.5, with English recipe description
df_path = "recipes_gpt3_eng_text-davinci-003_temp_1.0_nperkitchen_3_2023-01-23T17-52-40.csv"
df_path = joinpath(@__DIR__, df_path)
df = CSV.read(df_path, DataFrame, types=df_types)

# GPT-3.5, without English recipe description
df_path = "recipes_gpt3_eng_text-davinci-003_temp_1.0_nperkitchen_3_2023-01-27T21-03-51.csv"
df_path = joinpath(@__DIR__, df_path)
append!(df, CSV.read(df_path, DataFrame, types=df_types))

# GPT-3, with English recipe description
df_path = "recipes_gpt3_eng_davinci_temp_1.0_nperkitchen_3_2023-01-23T21-15-58.csv"
df_path = joinpath(@__DIR__, df_path)
append!(df, CSV.read(df_path, DataFrame, types=df_types))

# GPT-3, without English recipe description
df_path = "recipes_gpt3_eng_davinci_temp_1.0_nperkitchen_3_2023-01-27T22-59-36.csv"
df_path = joinpath(@__DIR__, df_path)
append!(df, CSV.read(df_path, DataFrame, types=df_types))

df_path = "recipes_baseline_2023-01-22T13-26-42.csv"
df_path = joinpath(@__DIR__, df_path)
baseline_df = CSV.read(df_path, DataFrame)
baseline_df.model .= "baseline"
append!(df, baseline_df; cols=:subset)

# Compute various extra information
transform!(df, :reason => (x -> x .== "Parse error") => :parse_error)
transform!(df, :reason => (x -> x .== "Non-existent predicates or types") => :non_existent_predicates)
transform!(df, :reason => (x -> x .== "Non-existent objects or variables") => :non_existent_objects)
transform!(df, :reason => (x -> x .== "Goal is not reachable") => :goal_unreachable)

# Group data frame by problems and conditions
problem_gdf = groupby(df, [condition_cols; [:problem, :kitchen_name]])
kitchen_gdf = groupby(df, [condition_cols; :kitchen_name])
condition_gdf = groupby(df, condition_cols)

## Validity Metrics ##

# Define operations and columns
ci(xs) = 1.96 * sem(xs) # 95% confidence interval
# validity_cols =
#     [:valid, :parse_error,:non_existent_objects, :goal_unreachable]
validity_cols =
    [:valid, :parse_error,
     :non_existent_predicates, :non_existent_objects, :goal_unreachable]
mean_ops = [col => mean for col in validity_cols]
sem_ops = [col => sem for col in validity_cols]
ci_ops = [col => ci for col in validity_cols]
validity_ops = [mean_ops; sem_ops; ci_ops]
     
#  Compute validity metrics for each problem and condition
prob_validity_df = combine(problem_gdf, validity_ops...)

#  Compute validity metrics for each kitchen and condition
kitchen_validity_df = combine(kitchen_gdf, validity_ops...)

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
    [:parse_error, :pddl_goal] => frac_unique_goals => :frac_unique,
    [:valid, :pddl_goal] => frac_unique_valid_goals => :frac_unique_valid,
    [:valid, :logprobs] => entropy_of_valid_goals => :entropy_valid
)

# Average diversity metrics over problems within each kitchen
diversity_gdf = groupby(prob_diversity_df, [condition_cols; :kitchen_name])
kitchen_diversity_df = combine(diversity_gdf, [col => mean => col for col in diversity_cols])

# Average diversity metrics over problems within each condition
diversity_gdf = groupby(prob_diversity_df, condition_cols)
mean_diversity_df = combine(diversity_gdf, [col => mean => col for col in diversity_cols])

## Merge Results ##

# Merge validity and diversity results for each problem
prob_df = innerjoin(prob_validity_df, prob_diversity_df, matchmissing=:equal,
                    on=[condition_cols; [:problem, :kitchen_name]])
transform!(prob_df, [:frac_unique_valid, :valid_mean] => ((x, y) -> x./y) => :frac_unique_out_of_valid)

# Merge validity and diversity results for each kitchen
kitchen_df = innerjoin(kitchen_validity_df, kitchen_diversity_df, matchmissing=:equal,
                       on=[condition_cols; :kitchen_name])
transform!(prob_df, [:frac_unique_valid, :valid_mean] => ((x, y) -> x./y) => :frac_unique_out_of_valid)

# Merge validity and diversity results for each condition
mean_df = innerjoin(mean_validity_df, mean_diversity_df,
                    matchmissing=:equal, on=condition_cols)
transform!(mean_df, [:frac_unique_valid, :valid_mean] => ((x, y) -> x./y) => :frac_unique_out_of_valid)

# Write out files
prob_df_path = joinpath(@__DIR__, "analysis_per_problem.csv")
CSV.write(prob_df_path, prob_df)
kitchen_df_path = joinpath(@__DIR__, "analysis_per_kitchen.csv")
CSV.write(kitchen_df_path, kitchen_df)
mean_df_path = joinpath(@__DIR__, "analysis_per_condition.csv")
CSV.write(mean_df_path, mean_df)

## Plotting ##
using StatsPlots, CategoricalArrays
using ColorSchemes

palette = ColorSchemes.Hiroshige[[5,3,1,7]]
default(fontfamily="Arial", palette=palette, tickfontsize=12)

validity_mean_cols = [Symbol(name, "_mean") for name in validity_cols
                      if name != :non_existent_predicates]
validity_ci_cols = [Symbol(name, "_ci") for name in validity_cols
                    if name != :non_existent_predicates]

# Plot per-model results
plot_df = select(mean_df, Not(r"non_existent_predicates"))

# Ensure categories preserve order instead of following alphabetical order
group_labels = ["InstructGPT\n(No Desc.)", "InstructGPT\n(Desc.)",
                "GPT-3\n(No Desc.)", "GPT-3\n(Desc.)", "Baseline\nPrior"]
groups = CategoricalArray(repeat(group_labels, outer=4))
levels!(groups, group_labels)

# category_labels = reverse!(["Valid", "Parse Error", "Spurious Predicates", "Spurious Objects", "Unachievable Goal"])
category_labels = reverse!(["Valid", "Parse Error", "Spurious Objects", "Unachievable Goal"])
categories = CategoricalArray(repeat(category_labels, inner=5))
levels!(categories, category_labels)

# Construct grouped bar plot
validity = Matrix(plot_df[:, reverse(validity_mean_cols)])
errs = Matrix(plot_df[:, reverse(validity_ci_cols)])
groupedbar(groups, validity, errorbar=errs, bar_position=:stack,
           group=categories, ylabel="Fraction", legendposition=:bottomleft,
           ylims=(0, 1.1), size=(640, 360), dpi=300)
savefig(joinpath(@__DIR__, "goal_generation_computational_results_per_model.pdf"))
title!("Validity of Generated Recipes across Different Models")
plot!(legendposition=:outerright, size=(900, 360),
      bottom_margin=20*Plots.px, left_margin=20*Plots.px)
savefig(joinpath(@__DIR__, "goal_generation_computational_results_per_model.png"))

# Plot per-kitchen results
plot_df = select(kitchen_df, Not(r"non_existent_predicates"))

plot_titles = ["InstructGPT (No Description)", "InstructGPT (Description)",
               "GPT-3 (No Description)", "GPT-3 (Description)", "Baseline Prior"]
category_labels = reverse!(["Valid", "Parse Error", "Spurious Objects", "Unachievable Goal"])

subplots = []
for (i, (key, sub_df)) in enumerate(pairs(groupby(plot_df, [:model, :include_recipe_description])))
    # Ensure categories preserve order instead of following alphabetical order
    group_labels = titlecase.(replace.(sub_df.kitchen_name, "and" => "&"))
    groups = CategoricalArray(repeat(group_labels, outer=5))
    levels!(groups, group_labels)

    categories = CategoricalArray(repeat(category_labels, inner=5))
    levels!(categories, category_labels)

    # Construct grouped bar plot
    validity = Matrix(sub_df[:, reverse(validity_mean_cols)])
    errs = Matrix(sub_df[:, reverse(validity_ci_cols)])
    p = groupedbar(groups, validity, errorbar=errs, legend=false,
                   group=categories, ylims=(0, 1.1), bar_position=:stack,
                   title="\n" * plot_titles[i], xrotation=-20.0,
                   xtickfontsize=10, xtickfontvalign=:bottom)
    push!(subplots, p)
end
legend_plot = plot(
    fill(missing, (1, 4)), seriestype=:bar, linewidth=1, framestyle=:none,
         legend=true, labels=permutedims(category_labels),
         legendposition=:left, legend_font_pointsize=10,
         left_margin=-20 * Plots.px
    )
l = @layout [grid(1, 5) lp{0.1w}]
plot(subplots..., legend_plot, layout=l, size=(2000, 400), dpi=300,
     top_margin = 40 .* Plots.px, bottom_margin = 50 .* Plots.px)
savefig(joinpath(@__DIR__, "goal_generation_computational_results_per_kitchen.pdf"))
plot!(plot_title="Validity of Generated Recipes across Different Models and Subdomains")
savefig(joinpath(@__DIR__, "goal_generation_computational_results_per_kitchen.png"))
