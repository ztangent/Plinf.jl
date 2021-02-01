using Julog, PDDL, Gen, Printf
using Plinf, CSV
using DataFrames
using Statistics
using JSON

include("render.jl")
include("utils.jl")
include("./new-scenarios/experiment-scenarios.jl")

#--- Generate Search Grid ---#
model = "ap"
search_noise = [0.05, 0.1, 0.3, 0.5, 0.7]
action_noise = [0.01, 0.05, 0.1, 0.2, 0.5, 0.7]
pred_noise = [0.1]
n_samples = [300]
grid_list = Iterators.product(search_noise, action_noise, pred_noise, n_samples)
grid_dict = []
for item in grid_list
    current_dict = Dict()
    current_dict["search_noise"] = item[1]
    current_dict["action_noise"] = item[2]
    current_dict["pred_noise"] = item[3]
    current_dict["n_samples"] = item[4]
    push!(grid_dict, current_dict)
end
corrolation = []

#--- Initial Setup ---#

# Specify problem
category = "1"
subcategory = "1"
experiment = "scenario-" * category * "-" * subcategory
problem_name = experiment * ".pddl"
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "block-words")

# Load human data
file_name = category * "_" * subcategory * ".csv"
human_data = vec(CSV.read(joinpath(path, "human_results_arrays", file_name), datarow=1, Tables.matrix))


# Load domain, problem, actions, and goal space
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "new-scenarios", problem_name))
actions = get_action(category * "-" * subcategory)
goal_words = get_goal_space(category * "-" * subcategory)
goals = word_to_terms.(goal_words)

# Initialize state
state = initialize(problem)
goal = problem.goal

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

#--- Goal Inference ---#

function goal_inference(params, domain, problem, goal_words, goals, state, traj)
    #### Goal Inference Setup ####

    # Goal noise
    #
    # # Define custom goal specification type
    # struct MyGoalSpec
    #     init_goal::GoalSpec
    #     cur_goal::GoalSpec
    # end
    #
    # function terms_to_word(terms::Vector{Term})
    #     # assumes :on terms are ordered top to bottom in terms
    #     word = ""
    #     for term in terms
    #         # first letter
    #         if (term.name == :clear)
    #             word = string(terms[1].args[1]) * word
    #         # other letters
    #     elseif (term.name == :on)
    #             word = word * string(term.args[2])
    #         end
    #     end
    #     return word
    # end
    #
    # function permute_goal(goalspec::GoalSpec)
    #     # performs one random swap of adjacent letters of the goal word
    #     # returns new corrupted goalspec
    #     goal_word = collect(terms_to_word(goalspec.goals))
    #     swap_idx = rand(2:length(goal_word))
    #     temp = goal_word[swap_idx]
    #     goal_word[swap_idx] = goal_word[swap_idx-1]
    #     goal_word[swap_idx-1]  = temp
    #     corrupted_goal = ""
    #     for c in goal_word
    #         corrupted_goal = corrupted_goal * string(c)
    #     end
    #     # print(corrupted_goal)
    #     return GoalSpec(word_to_terms(string(corrupted_goal)))
    # end
    #
    # # Define getter that returns current goal
    # get_goal(goal_spec::MyGoalSpec) = goal_spec.cur_goal
    # # Define uniform prior over possible goals
    # @gen function goal_prior()
    #     goal_spec = GoalSpec(word_to_terms(@trace(labeled_unif(goal_words), :goal)))
    #     return MyGoalSpec(goal_spec, goal_spec)
    # end
    #
    # # Define custom noisy goal transition
    # @gen function goal_step(t, goal_spec::MyGoalSpec, goal_noise::Real)
    #     @unpack init_goal, cur_goal = goal_spec
    #     # Corrupt the current goal
    #     cur_goal = permute_goal(init_goal)
    #     return MyGoalSpec(init_goal, cur_goal)
    # end
    # # Configure agent to use the custom goal step
    # agent_config = AgentConfig(domain, agent_planner, act_noise=0.05,
    #                            goal_step=goal_step, goal_args=(0.1,))

    # Define uniform prior over possible goals
    @gen function goal_prior()
        GoalSpec(word_to_terms(@trace(labeled_unif(goal_words), :goal)))
    end
    goal_strata = Dict((:goal_init => :goal) => goal_words)

    # Assume either a planning agent or replanning agent as a model
    heuristic = precompute(FFHeuristic(), domain)
    planner = ProbAStarPlanner(heuristic=heuristic, search_noise=params["search_noise"])
    replanner = Replanner(planner=planner, persistence=(2, 0.95))
    agent_planner = replanner # planner

    # Configure agent model with goal prior and planner
    agent_init = AgentInit(agent_planner, goal_prior)
    agent_config = AgentConfig(domain, agent_planner, act_noise=params["action_noise"])

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

    act_proposal = act_noise > 0 ? forward_act_proposal : nothing
    act_proposal_args = (params["action_noise"],)

    # Set up rejuvenation moves
    goal_rejuv! = pf -> pf_goal_move_accept!(pf, goal_words)
    plan_rejuv! = pf -> pf_replan_move_accept!(pf)
    mixed_rejuv! = pf -> pf_mixed_move_accept!(pf, goal_words; mix_prob=0.25)

    traces, weights =
        world_particle_filter(world_init, world_config, traj, obs_terms, params["n_samples"];
                              resample=true, rejuvenate=pf_replan_move_accept!,
                              strata=goal_strata, callback=callback,
                              act_proposal=act_proposal,
                              act_proposal_args=act_proposal_args)

    # Show animation of goal inference
    #gif(anim, joinpath(path, "sips-results", experiment*".gif"), fps=1)

    df = DataFrame(Timestep=collect(1:length(traj)), Probs=goal_probs)
    # CSV.write(joinpath(path, "sips-results", experiment*".csv"), df)
    return goal_probs
end

for (i, params) in enumerate(grid_dict)
    total = size(grid_dict)[1]
    goal_probs = goal_inference(params, domain, problem, goal_words, goals, state, traj)
    flattened_array = collect(Iterators.flatten(goal_probs[1:2:end]))
    push!(corrolation, cor(flattened_array, human_data))
    print("Parameters Set " * string(i) * " / " * string(total) * " done \n")
end

#--- Save Best Parameters ---#
mxval, mxindx = findmax(corrolation)
best_params = grid_dict[mxindx]
best_params["corr"] = mxval
json_data = JSON.json(best_params)
json_file = joinpath(path, model_name, "best_params", experiment*".json")
open(json_file, "w") do f
    JSON.print(f, json_data)
end


#--- Generate Results ---#
number_of_trials = 5
for i in 1:number_of_trials
    goal_probs = goal_inference(best_params, domain, problem, goal_words, goals, state, traj)
    df = DataFrame(Timestep=collect(1:length(traj)), Probs=goal_probs)
    CSV.write(joinpath(path, model_name, category * "_" * subcategory, string(i)*".csv"), df)
end
