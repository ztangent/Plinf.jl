using Julog, PDDL, Gen, Printf
using Plinf, CSV
using DataFrames
using Statistics
using JSON
using UnPack
using Random
using Glob

include("render.jl")
include("utils.jl")
include("./new-scenarios/experiment-scenarios.jl")
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "block-words")
domain = load_domain(joinpath(path, "domain.pddl"))

#--- Generate Search Grid ---#
model_name = "pg"
pred_noise = [0.1]
rejuvenation = ["None"]
n_samples = [300]

if model_name == "ag"
    search_noise = [NaN]
    r = [NaN]
    q = [NaN]
else
    search_noise = [0.02, 0.5]
    r = [2, 4]
    q = [0.9, 0.95]
end

if model_name == "ap"
    goal_noise = [NaN]
else
    goal_noise = [0.1, 0.2]
end

if model_name == "pg"
    action_noise = [NaN]
else
    action_noise = [0.05, 0.1, 0.2]
end


grid_list = Iterators.product(search_noise, action_noise, goal_noise, r, q, rejuvenation, pred_noise, n_samples)
grid_dict = []
for item in grid_list
    current_dict = Dict()
    current_dict["search_noise"] = item[1]
    current_dict["action_noise"] = item[2]
    current_dict["goal_noise"] = item[3]
    current_dict["r"] = item[4]
    current_dict["q"] = item[5]
    current_dict["rejuvenation"] = item[6]
    current_dict["pred_noise"] = item[7]
    current_dict["n_samples"] = item[8]
    push!(grid_dict, current_dict)
end

grid_dict

#--- Goal Inference ---#

# Define custom goal specification type
struct NoisyGoal
    init_goal::GoalSpec
    cur_goal::GoalSpec
end

"Uniform distribution over permutations (shuffles) of an array."
struct RandomShuffle{T <: AbstractArray} <: Gen.Distribution{T}
    v::T # Original array to be shuffled
end
(d::RandomShuffle)() = Gen.random(d)
@inline Gen.random(d::RandomShuffle) = shuffle(d.v)
function Gen.logpdf(d::RandomShuffle{T}, xs::T) where {T}
    if size(xs) != size(d.v) return -Inf end
    v_counts = countmap(d.v)
    score = sum(logfactorial.(values(v_counts))) - logfactorial(length(d.v))
    for x in xs
        x in keys(v_counts) || return -Inf
        v_counts[x] -= 1
    end
    return all(values(v_counts) .== 0) ? score : -Inf
end
Gen.logpdf_grad(::RandomShuffle, x) =
    (nothing,)
Gen.has_output_grad(::RandomShuffle) =
    false
Gen.has_argument_grads(::RandomShuffle) =
    (nothing,)

# Goal noise implementation
function terms_to_word(terms::Vector{Term})
    # assumes :on terms are ordered top to bottom in terms
    word = ""
    for term in terms
        # first letter
        if (term.name == :clear)
            word = string(terms[1].args[1]) * word
        # other letters
    elseif (term.name == :on)
            word = word * string(term.args[2])
        end
    end
    return word
end

@gen function corrupt_goal(goalspec::GoalSpec)
    # returns new corrupted goalspec
    goal_word = collect(terms_to_word(goalspec.goals))
    corrupted_goal = @trace(RandomShuffle(goal_word)(), :permutation)
    corrupted_goal = String(corrupted_goal)
    # print(corrupted_goal)
    return GoalSpec(word_to_terms(string(corrupted_goal)))
end

# Define getter that returns current goal
Plinf.get_goal(goal_spec::NoisyGoal) = goal_spec.cur_goal

function goal_inference(params, domain, problem, goal_words, goals, state, traj, isgoal, isplan, isaction)
    if isaction
        action_noise = params["action_noise"]
    else
        action_noise = 0
    end
    #### Goal Inference Setup ####

    # Define uniform prior over possible goals
    @gen function goal_prior()
        goal_spec = GoalSpec(word_to_terms(@trace(labeled_unif(goal_words), :goal)))
        return NoisyGoal(goal_spec, goal_spec)
    end
    goal_strata = Dict((:goal_init => :goal) => goal_words)

    if isgoal
        # Define custom noisy goal transition
        @gen function goal_step(t, goal_spec::NoisyGoal, goal_noise::Real)
            @unpack init_goal, cur_goal = goal_spec
            # Corrupt the current goal with some parameter noise
            if @trace(bernoulli(goal_noise), :corrupt)
                if cur_goal == init_goal
                    cur_goal = corrupt_goal(init_goal)
                else
                    cur_goal = init_goal
                end
            end
            return NoisyGoal(init_goal, cur_goal)
        end
    end

    if isplan
        # Assume either a planning agent or replanning agent as a model
        heuristic = precompute(FFHeuristic(), domain)
        planner = ProbAStarPlanner(heuristic=heuristic, search_noise=params["search_noise"])
        replanner = Replanner(planner=planner, persistence=(params["r"], params["q"]))
        agent_planner = replanner # planner
    else
        heuristic = precompute(FFHeuristic(), domain)
        planner = AStarPlanner(heuristic=heuristic)
        replanner = Replanner(planner=planner, persistence=(10,0.999)) ##todo: add persistence
        agent_planner = replanner # planner
    end

    # Configure agent model with goal prior and planner
    agent_init = AgentInit(agent_planner, goal_prior)
    if isgoal
        if isaction
            agent_config = AgentConfig(domain=domain, planner=agent_planner, act_args=(action_noise, ),
                                    act_step=Plinf.noisy_act_step, goal_step=goal_step,
                                    goal_args=(params["goal_noise"],))
        else
            agent_config = AgentConfig(domain=domain, planner=agent_planner, act_args=(),
                                    act_step=Plinf.planned_act_step, goal_step=goal_step,
                                    goal_args=(params["goal_noise"],))
        end
    else
        agent_config = AgentConfig(domain, agent_planner, act_noise=action_noise)
    end
    # Define observation noise model
    obs_params = observe_params(domain, pred_noise=params["pred_noise"]; state=state)
    obs_terms = collect(keys(obs_params))

    # Configure world model with planner, goal prior, initial state, and obs params
    world_init = WorldInit(agent_init, state, state)
    world_config = WorldConfig(domain, agent_config, obs_params)


    #### Online Goal Inference ####

    # Set up visualization and logging callbacks for online goal inference
    goal_probs = [] # Buffer of goal probabilities over time
    callback = (t, s, trs, ws) -> begin
        # print("t=$t\t");
        push!(goal_probs, return_goal_probs(get_goal_probs(trs, ws, goal_words)));
        # print_goal_probs(get_goal_probs(trs, ws, goal_words))
    end

    act_proposal = action_noise > 0 ? forward_act_proposal : nothing
    act_proposal_args = (action_noise,)

    # Set up rejuvenation moves
    goal_rejuv! = pf -> pf_goal_move_accept!(pf, goal_words)
    plan_rejuv! = pf -> pf_replan_move_accept!(pf)
    mixed_rejuv! = pf -> pf_mixed_move_accept!(pf, goal_words; mix_prob=0.25)

    traces, weights =
        world_particle_filter(world_init, world_config, traj, obs_terms, params["n_samples"];
                              resample=true, rejuvenate=nothing,
                              strata=goal_strata, callback=callback,
                              act_proposal=act_proposal,
                              act_proposal_args=act_proposal_args)

    # Show animation of goal inference
    #gif(anim, joinpath(path, "sips-results", experiment*".gif"), fps=1)

    # df = DataFrame(Timestep=collect(1:length(traj)), Probs=goal_probs)
    # CSV.write(joinpath(path, "sips-results", experiment*".csv"), df)
    return goal_probs
end

#--- Search ---#
mkpath(joinpath(path, "results_entire_dataset", model_name, "search_results_multi_trials"))

# Load human data
human_data = []
for category in 1:4
    for scenario in 1:4
        category = string(category)
        scenario = string(scenario)
        file_name = category * "_" * scenario * ".csv"
        temp = vec(CSV.read(joinpath(path, "average_human_results_arrays", file_name), datarow=1, Tables.matrix))
        append!(human_data, temp)
    end
end

# Search parameters
number_of_search_trials = 5
corrolation = []

for (i, params) in enumerate(grid_dict)
    model_data = []
    scenarios_list = []
    corrolation_list = []
    for category in 1:4
        category = string(category)
        for scenario in 1:4
            scenario = string(scenario)
            mkpath(joinpath(path, "results_entire_dataset", model_name, "search_results_multi_trials", "parameter_set_"*string(i), category*"_"*scenario))

            #--- Initial Setup ---#
            # Specify problem
            experiment = "scenario-" * category * "-" * scenario
            problem_name = experiment * ".pddl"

            # Load domain, problem, actions, and goal space
            problem = load_problem(joinpath(path, "new-scenarios", problem_name))
            actions = get_action(category * "-" * scenario)
            goal_words = get_goal_space(category * "-" * scenario)
            goals = word_to_terms.(goal_words)

            # Initialize state
            state = initialize(problem)
            goal = problem.goal

            #--- Initialize algorithm ---#
            # Execute list of actions and generate intermediate states
            function execute_plan(state, domain, actions)
                states = State[]
                push!(states, state)
                for action in actions
                    action = parse_pddl(action)
                    state = execute(action, state, domain)
                    push!(states, state)
                end
                return states
            end
            traj = execute_plan(state, domain, actions)

            #--- Run inference ---#
            if model_name == "ap"
                isgoal = false
                isplan = true
                isaction = true
            elseif model_name == "ag"
                isgoal = true
                isplan = false
                isaction = true
            elseif model_name == "pg"
                isgoal = true
                isplan = true
                isaction = false
            end

            #--- Run inference ---#
            mean_array = zeros(5*length(traj[1:2:end]))
            for j in 1:number_of_search_trials
                goal_probs = goal_inference(params, domain, problem, goal_words, goals,
                                            state, traj, isgoal, isplan, isaction)
                df = DataFrame(Timestep=collect(1:length(traj)), Probs=goal_probs)
                CSV.write(joinpath(path, "results_entire_dataset", model_name,
                                    "search_results_multi_trials", "parameter_set_"*string(i),
                                    category*"_"*scenario, string(j)*".csv"), df)
                flattened_array = collect(Iterators.flatten(goal_probs[1:2:end]))
                mean_array = mean_array + flattened_array
            end
            mean_array = mean_array / number_of_search_trials
            append!(model_data, mean_array)

            #--- Store corrolation for current scenario ---#
            file_name = category * "_" * scenario * ".csv"
            temp_human_data = vec(CSV.read(joinpath(path, "average_human_results_arrays", file_name), datarow=1, Tables.matrix))
            push!(scenarios_list, category*"_"*scenario)
            push!(corrolation_list, cor(mean_array, temp_human_data))
        end
    end
    R = cor(model_data, human_data)
    push!(corrolation, R)

    #--- Save corrolation CSV ---#
    df = DataFrame(Scenario=scenarios_list, Corrolation=corrolation_list)
    CSV.write(joinpath(path, "results_entire_dataset", model_name,
                        "search_results_multi_trials", "parameter_set_"*string(i)*".csv"), df)

    # #--- Save Parameters ---#
    params["corr"] = R
    json_data = JSON.json(params)
    json_file = joinpath(path, "results_entire_dataset", model_name, "search_results_multi_trials", "parameter_set_"*string(i)*".json")
    open(json_file, "w") do f
        JSON.print(f, json_data)
    end
end


#--- Save Best Parameters ---#
# mxval, mxindx = findmax(corrolation)
# best_params = grid_dict[mxindx]
# best_params["corr"] = mxval
# json_data = JSON.json(best_params)
# json_file = joinpath(path, "results_entire_dataset", model_name, "search_results_multi_trials", "best_params_"*string(mxindx)*".json")
# open(json_file, "w") do f
#     JSON.print(f, json_data)
# end
best_params = Dict("corr"=>0)
mxindx = 0
for i=1:length(grid_dict)
    file = joinpath(path, "results_entire_dataset", model_name, "search_results_multi_trials", "parameter_set_"*string(i)*".json")
    open(file, "r") do f
        params_dict = read(f,String) # file information to string
        params_dict=JSON.parse(params_dict)  # parse and transform data
        global params =JSON.parse(params_dict)
    end
    if params["corr"] > best_params["corr"]
        best_params = params
        mxindx = i
    end
end
json_data = JSON.json(best_params)
json_file = joinpath(path, "results_entire_dataset", model_name, "search_results_multi_trials", "best_params_"*string(mxindx)*".json")
open(json_file, "w") do f
    JSON.print(f, json_data)
end

#--- Generate Results ---#
best_params = Dict()

# Read best Params #
files = glob("best_params_*.json", joinpath(path, "results_entire_dataset", model_name, "search_results_multi_trials"))
file = files[1]
open(file, "r") do f
    string_dict = read(f,String) # file information to string
    string_dict=JSON.parse(string_dict)  # parse and transform data
    global best_params=JSON.parse(string_dict)
end
best_params["n_samples"] = 500

number_of_trials = 10
for category in 1:4
    category = string(category)
    for scenario in 1:4
        scenario = string(scenario)
        mkpath(joinpath(path, "results_entire_dataset", model_name, "results_multi_trials", category * "_" * scenario))

        #--- Initial Setup ---#
        # Specify problem
        experiment = "scenario-" * category * "-" * scenario
        problem_name = experiment * ".pddl"

        # Load domain, problem, actions, and goal space
        problem = load_problem(joinpath(path, "new-scenarios", problem_name))
        actions = get_action(category * "-" * scenario)
        goal_words = get_goal_space(category * "-" * scenario)
        goals = word_to_terms.(goal_words)

        # Initialize state
        state = initialize(problem)
        goal = problem.goal

        #--- Initialize algorithm ---#
        # Execute list of actions and generate intermediate states
        function execute_plan(state, domain, actions)
            states = State[]
            push!(states, state)
            for action in actions
                action = parse_pddl(action)
                state = execute(action, state, domain)
                push!(states, state)
            end
            return states
        end
        traj = execute_plan(state, domain, actions)

        #--- Run inference ---#
        for i in 1:number_of_trials
            #--- Run inference ---#
            if model_name == "ap"
                isgoal = false
                isplan = true
                isaction = true
            elseif model_name == "ag"
                isgoal = true
                isplan = false
                isaction = true
            elseif model_name == "pg"
                isgoal = true
                isplan = true
                isaction = false
            end
            goal_probs = goal_inference(best_params, domain, problem, goal_words, goals,
                                        state, traj, isgoal, isplan, isaction)
            df = DataFrame(Timestep=collect(1:length(traj)), Probs=goal_probs)
            CSV.write(joinpath(path, "results_entire_dataset", model_name, "results_multi_trials", category * "_" * scenario, string(i)*".csv"), df)
        end
    end
end
