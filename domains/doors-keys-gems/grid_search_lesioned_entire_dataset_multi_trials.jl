using Julog, PDDL, Gen, Printf
using Plinf, CSV
using DataFrames
using Statistics
using JSON
using Glob

include("render.jl")
include("utils.jl")
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "doors-keys-gems")
domain = load_domain(joinpath(path, "domain.pddl"))

#--- Generate Search Grid ---#
model_name = "a"
pred_noise = [0.1]
rejuvenation = ["None"]
n_samples = [180]

if model_name == "a"
    search_noise = [NaN]
    r = [NaN]
    q = [NaN]
else
    search_noise = [0.02, 0.5]
    r = [2, 4]
    q = [0.9, 0.95]
end

if model_name == "p"
    action_noise = [NaN]
else
    action_noise = [0.05, 0.1, 0.2]
end


grid_list = Iterators.product(search_noise, action_noise, r, q, rejuvenation, pred_noise, n_samples)
grid_dict = []
for item in grid_list
    current_dict = Dict()
    current_dict["search_noise"] = item[1]
    current_dict["action_noise"] = item[2]
    current_dict["r"] = item[3]
    current_dict["q"] = item[4]
    current_dict["rejuvenation"] = item[5]
    current_dict["pred_noise"] = item[6]
    current_dict["n_samples"] = item[7]
    push!(grid_dict, current_dict)
end

judgement_points =
[[1,7,17,23],
[1,9,14,17],
[1,9,17,24],
[1,7,14,23,32],
[1,6,11,24],
[1,4,6,11],
[1,5,8,13],
[1,9,12,31,44],
[1,7,22,37,50],
[1,14,24,29,40,54],
[1,7,13,20,26],
[1,6,11,26,36,49],
[1,8,14,20],
[1,4,7,10],
[1,5,8,10],
[1,7,12,18]
]

grid_dict

#--- Goal Inference ---#

function goal_inference(params, domain, problem, goals, state, traj, isplan, isaction)
    #--- Goal Inference Setup ---#
    # Specify possible goals
    # goals = [@julog([has(gem1)]), @julog([has(gem2)]), @julog([has(gem3)])]
    goal_idxs = collect(1:length(goals))
    goal_names = [repr(t[1]) for t in goals]

    # Define uniform prior over possible goals
    @gen function goal_prior()
        GoalSpec(goals[@trace(uniform_discrete(1, length(goals)), :goal)])
    end
    goal_strata = Dict((:init => :agent => :goal => :goal) => goal_idxs)

    if isplan
        # Assume either a planning agent or replanning agent as a model
        # planner = ProbAStarPlanner(heuristic=GemManhattan(), search_noise=0.1)
        planner = ProbAStarPlanner(heuristic=GemMazeDist(), search_noise=params["search_noise"])
        # TODO: change to maze dist heuristic!!
        replanner = Replanner(planner=planner, persistence=(params["r"], params["q"]))
        agent_planner = replanner # planner
    else
        planner = AStarPlanner(heuristic=GemMazeDist())
        replanner = Replanner(planner=planner, persistence=(10, 0.999))
        agent_planner = replanner # planner
    end

    # Configure agent model with goal prior and planner
    if isaction
        act_noise = params["action_noise"] # Assume a small amount of action noise
        agent_init = AgentInit(agent_planner, goal_prior)
        agent_config = AgentConfig(domain, agent_planner, act_noise=act_noise)
    else
        act_noise = 0
        agent_init = AgentInit(agent_planner, goal_prior)
        agent_config = AgentConfig(domain=domain, planner=agent_planner,  act_args=(),
                                act_step=Plinf.planned_act_step)
    end


    # Define observation noise model
    obs_params = observe_params(
        (@julog(xpos), normal, 0.25), (@julog(ypos), normal, 0.25),
        (@julog(forall(doorloc(X, Y), door(X, Y))), 0.05),
        (@julog(forall(item(Obj),has(Obj))), 0.05),
        (@julog(forall(and(item(Obj), itemloc(X, Y)), at(Obj, X, Y))), 0.05)
    )
    obs_terms = collect(keys(obs_params))

    # Configure world model with planner, goal prior, initial state, and obs params
    world_init = WorldInit(agent_init, state, state)
    world_config = WorldConfig(domain, agent_config, obs_params)

    #--- Online Goal Inference ---#

    goal_probs = [] # Buffer of goal probabilities over time
    callback = (t, s, trs, ws) -> begin
        goal_probs_t = collect(values(sort!(get_goal_probs(trs, ws, goal_idxs))))
        push!(goal_probs, goal_probs_t)
        # print("t=$t\t")
        # print_goal_probs(get_goal_probs(trs, ws, goal_idxs))
    end

    # Set up rejuvenation moves
    goal_rejuv! = pf -> pf_goal_move_accept!(pf, goals)
    plan_rejuv! = pf -> pf_replan_move_accept!(pf)
    mixed_rejuv! = pf -> pf_mixed_move_accept!(pf, goals; mix_prob=0.25)

    # Set up action proposal to handle potential action noise
    act_proposal = act_noise > 0 ? forward_act_proposal : nothing
    act_proposal_args = (act_noise,)

    # Run a particle filter to perform online goal inference
    traces, weights =
        world_particle_filter(world_init, world_config, traj, obs_terms,  params["n_samples"];
                              resample=true, rejuvenate=nothing, strata=goal_strata,
                              callback=callback,
                              act_proposal=act_proposal,
                              act_proposal_args=act_proposal_args)
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
            stimulus_idx = ((parse(Int64,category)-1) * 4) +  parse(Int64,scenario)
            experiment = "scenario-" * category * "-" * scenario
            problem_name = experiment * ".pddl"

            # Load domain, problem, actions, and goal space
            problem = load_problem(joinpath(path, "new-scenarios", problem_name))
            file_name = category * "_" * scenario * ".dat"
            actions = readlines(joinpath(path, "new-scenarios", "actions" ,file_name))
            goals = [@julog([has(gem1)]), @julog([has(gem2)]), @julog([has(gem3)])]

            goal_colors = [colorant"#D41159", colorant"#FFC20A", colorant"#1A85FF"]
            gem_terms = @julog [gem1, gem2, gem3]
            gem_colors = Dict(zip(gem_terms, goal_colors))

            # Initialize state
            state = initialize(problem)
            start_pos = (state[:xpos], state[:ypos])
            goal = [problem.goal]


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
            if model_name == "a"
                isplan = false
                isaction = true
            elseif model_name == "p"
                isplan = true
                isaction = false
            end

            mean_array = zeros(3*length(judgement_points[stimulus_idx]))
            for j in 1:number_of_search_trials
                goal_probs = goal_inference(params, domain, problem, goals, state, traj,
                                            isplan, isaction)
                df = DataFrame(Timestep=collect(1:length(traj)), Probs=goal_probs)
                CSV.write(joinpath(path, "results_entire_dataset", model_name,
                                    "search_results_multi_trials", "parameter_set_"*string(i),
                                    category*"_"*scenario, string(j)*".csv"), df)
                flattened_array = collect(Iterators.flatten(goal_probs[1:end]))
                only_judgement_model = []
                for k in judgement_points[stimulus_idx]
                    idx = (k) * 3
                    for n in flattened_array[idx-2:idx]
                        push!(only_judgement_model, n)
                    end
                end
                mean_array = mean_array + only_judgement_model
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
        global best_params = params
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
best_params["n_samples"] = 300

number_of_trials = 10
for category in 1:4
    category = string(category)
    for scenario in 1:4
        scenario = string(scenario)
        mkpath(joinpath(path, "results_entire_dataset", model_name, "results_multi_trials", category * "_" * scenario))

        #--- Initial Setup ---#
        # Specify problem
        stimulus_idx = ((parse(Int64,category)-1) * 4) +  parse(Int64,scenario)
        experiment = "scenario-" * category * "-" * scenario
        problem_name = experiment * ".pddl"

        # Load domain, problem, actions, and goal space
        problem = load_problem(joinpath(path, "new-scenarios", problem_name))
        file_name = category * "_" * scenario * ".dat"
        actions = readlines(joinpath(path, "new-scenarios", "actions" ,file_name))
        goals = [@julog([has(gem1)]), @julog([has(gem2)]), @julog([has(gem3)])]

        goal_colors = [colorant"#D41159", colorant"#FFC20A", colorant"#1A85FF"]
        gem_terms = @julog [gem1, gem2, gem3]
        gem_colors = Dict(zip(gem_terms, goal_colors))

        # Initialize state
        state = initialize(problem)
        start_pos = (state[:xpos], state[:ypos])
        goal = [problem.goal]


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
        if model_name == "a"
            isplan = false
            isaction = true
        elseif model_name == "p"
            isplan = true
            isaction = false
        end

        for i in 1:number_of_trials
            goal_probs = goal_inference(best_params, domain, problem, goals, state, traj,
                                        isplan, isaction)
            df = DataFrame(Timestep=collect(1:length(traj)), Probs=goal_probs)
            CSV.write(joinpath(path, "results_entire_dataset", model_name,
                                "results_multi_trials",
                                category*"_"*scenario, string(i)*".csv"), df)
        end
    end
end
