using Julog, PDDL, Gen, Printf
using Plinf, CSV
using DataFrames
using Statistics
using JSON

include("render.jl")
include("utils.jl")

#--- Generate Search Grid ---#
model_name = "ap"
search_noise = [0.02, 0.5]
action_noise = [0.05, 0.1, 0.2]
r = [2, 4]
q = [0.9, 0.95]
pred_noise = [0.1]
rejuvenation = ["None"]
n_samples = [300]
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
[[1,7,14,20],
[1,9,14,17],
[1,9,17,24],
[1,7,14,23,32],
[1,6,11,21],
[1,6,11],
[1,5,8,13],
[1,9,12,31,44],
[1,7,22,37],
[1,14,24,29],
[1,7,13,20],
[1,6,11,47],
[1,8,14,18],
[1,4,8],
[1,5,8],
[1,7,12,18]
]


#--- Initial Setup ---#
for category in ["1","2","3","4"]
    for subcategory in ["1","2","3","4"]
        # Specify problem
        # category = "2"
        # subcategory = "1"
        stimulus_idx = ((parse(Int64,category)-1) * 4) +  parse(Int64,subcategory)
        correlation = []
        experiment = "scenario-" * category * "-" * subcategory
        println("Starting Search for " * experiment)
        problem_name = experiment * ".pddl"
        path = joinpath(dirname(pathof(Plinf)), "..", "domains", "doors-keys-gems")

        # Load human data
        file_name = category * "_" * subcategory * ".csv"
        human_data = vec(CSV.read(joinpath(path, "human_results_arrays", file_name), datarow=1, Tables.matrix))


        # Load domain, problem, actions, and goal space
        domain = load_domain(joinpath(path, "domain.pddl"))
        problem = load_problem(joinpath(path, "new-scenarios", problem_name))
        file_name = category * "_" * subcategory * ".dat"
        actions = readlines(joinpath(path, "new-scenarios", "actions" ,file_name))
        goals = [@julog([has(gem1)]), @julog([has(gem2)]), @julog([has(gem3)])]

        goal_colors = [colorant"#D41159", colorant"#FFC20A", colorant"#1A85FF"]
        gem_terms = @julog [gem1, gem2, gem3]
        gem_colors = Dict(zip(gem_terms, goal_colors))

        # Initialize state
        state = initialize(problem)
        start_pos = (state[:xpos], state[:ypos])
        goal = [problem.goal]

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
        # print(size(traj))



        #--- Goal Inference ---#

        function goal_inference(params, domain, problem, goals, state, traj)
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

            # Assume either a planning agent or replanning agent as a model
            # planner = ProbAStarPlanner(heuristic=GemManhattan(), search_noise=0.1)
            planner = ProbAStarPlanner(heuristic=GemMazeDist(), search_noise=0.1)
            # TODO: change to maze dist heuristic!!
            replanner = Replanner(planner=planner, persistence=(2, 0.95))
            agent_planner = replanner # planner

            # Configure agent model with goal prior and planner
            act_noise = 0.05 # Assume a small amount of action noise
            agent_init = AgentInit(agent_planner, goal_prior)
            agent_config = AgentConfig(domain, agent_planner, act_noise=0.05)

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
                                      resample=true, rejuvenate=mixed_rejuv!, strata=goal_strata,
                                      callback=callback,
                                      act_proposal=act_proposal,
                                      act_proposal_args=act_proposal_args)
            return goal_probs
        end

        for (i, params) in enumerate(grid_dict)
            total = size(grid_dict)[1]
            goal_probs = goal_inference(params, domain, problem, goals, state, traj)
            flattened_array = collect(Iterators.flatten(goal_probs[1:end]))
            # println(flattened_array)
            # only correlate model predictions at judgement points
            only_judgement_model = []
            for i in judgement_points[stimulus_idx]
                idx = (i) * 3
                for j in flattened_array[idx-2:idx]
                    push!(only_judgement_model, j)
                end
            end
            push!(correlation, cor(only_judgement_model, human_data))
            print("Parameters Set " * string(i) * " / " * string(total) * " done \n")
        end

        #--- Save Best Parameters ---#
        mxval, mxindx = findmax(correlation)
        best_params = grid_dict[mxindx]
        best_params["corr"] = mxval
        json_data = JSON.json(best_params)
        println(experiment)
        println(json_data)
        json_file = joinpath(path, model_name, "best_params", experiment*".json")
        open(json_file, "w") do f
            JSON.print(f, json_data)
        end
    end
end


#--- Generate Results ---#
number_of_trials = 10
for i in 1:number_of_trials
    best_params["n_samples"] = 500
    goal_probs = goal_inference(best_params, domain, problem, goals, state, traj)
    df = DataFrame(Timestep=collect(1:length(traj)), Probs=goal_probs)
    CSV.write(joinpath(path, model_name, category * "_" * subcategory, string(i)*".csv"), df)
end
