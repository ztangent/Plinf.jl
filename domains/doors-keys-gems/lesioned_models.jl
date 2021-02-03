using Julog, PDDL, Gen, Printf
using Plinf, CSV
using DataFrames
using Statistics
using JSON

include("render.jl")
include("utils.jl")


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
        replanner = Replanner(planner=planner)
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
        agent_config = AgentConfig(domain=domain, planner=agent_planner, act_args=(),
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
                              resample=true, rejuvenate=mixed_rejuv!, strata=goal_strata,
                              callback=callback,
                              act_proposal=act_proposal,
                              act_proposal_args=act_proposal_args)
    return goal_probs
end


#--- Model Setup ---#
model_name = "p" #a #p
scenarios = ["1_1", "1_2", "1_3"]

for scenario in scenarios
    #--- Problem Setup ---#

    category = split(scenario, "_")[1]
    subcategory = split(scenario, "_")[2]
    stimulus_idx = ((parse(Int64,category)-1) * 4) +  parse(Int64,subcategory)
    correlation = []
    experiment = "scenario-" * category * "-" * subcategory
    problem_name = experiment * ".pddl"
    path = joinpath(dirname(pathof(Plinf)), "..", "domains", "doors-keys-gems")


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

    #--- Generate Results ---#
    number_of_trials = 10
    for i in 1:number_of_trials
        best_params = Dict()
        open(joinpath(path, "ap", "best_params", experiment * ".json"), "r") do f
            string_dict = read(f,String) # file information to string
            string_dict=JSON.parse(string_dict)  # parse and transform data
            best_params=JSON.parse(string_dict)
        end
        best_params["n_samples"] = 150
        if model_name == "a"
            isplan = false
            isaction = true
        elseif model_name == "p"
            isplan = true
            isaction = false
        end

        goal_probs = goal_inference(best_params, domain, problem, goals, state, traj,
                                    isplan, isaction)
        df = DataFrame(Timestep=collect(1:length(traj)), Probs=goal_probs)
        CSV.write(joinpath(path, model_name, category * "_" * subcategory, string(i)*".csv"), df)

    end

end
