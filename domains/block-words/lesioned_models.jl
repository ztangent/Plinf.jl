using Julog, PDDL, Gen, Printf
using Plinf, CSV
using DataFrames
using Statistics
using JSON
using UnPack
using Random

include("render.jl")
include("utils.jl")
include("./new-scenarios/experiment-scenarios.jl")

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


#--- Model Setup ---#
model_name = "ag" #ap #ag #pg
scenarios = ["1_1", "1_2", "1_3", "1_4",
            "2_1", "2_2", "2_3", "2_4"]

#--- Problem Setup ---#

for scenario in scenarios
    print("Scenario: " * scenario * " \n")
    # Specify problem
    category = split(scenario, "_")[1]
    subcategory = split(scenario, "_")[2]
    corrolation = []
    experiment = "scenario-" * category * "-" * subcategory
    problem_name = experiment * ".pddl"
    path = joinpath(dirname(pathof(Plinf)), "..", "domains", "block-words")


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


    #--- Generate Results ---#
    number_of_trials = 10
    for i in 1:number_of_trials
        print("Trial: " * string(i) * " \n")
        best_params = Dict()
        open(joinpath(path, "apg", "best_params", experiment * ".json"), "r") do f
            string_dict = read(f,String) # file information to string
            string_dict=JSON.parse(string_dict)  # parse and transform data
            best_params=JSON.parse(string_dict)
        end
        best_params["n_samples"] = 500
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
        CSV.write(joinpath(path, model_name, category * "_" * subcategory, string(i)*".csv"), df)
    end
end
