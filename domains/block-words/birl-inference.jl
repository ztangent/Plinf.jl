using Julog, PDDL, Gen, Printf
using Plinf, CSV
using DataFrames

# include("render.jl")
include("utils.jl")
include("./new-scenarios/experiment-scenarios.jl")

#--- Initial Setup ---#

# Specify problem name
category = "2"
subcategory = "3"
experiment = "scenario-" * category * "-" * subcategory
problem_name = experiment * ".pddl"

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "block-words")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "new-scenarios", problem_name))

# Initialize state
state = initialize(problem)
goal = problem.goal

# Read possible goal words from file
goal_words = get_goal_space(category * "-" * subcategory)
goals = word_to_terms.(goal_words)

actions = get_action(category * "-" * subcategory)
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

#-- Bayesian IRL inference --#

function generate_init_states(state::State, domain::Domain, k=5)
    ff = precompute(FFHeuristic(), domain)
    prob_astar = ProbAStarPlanner(heuristic=ff, search_noise=0.1)
    replanner = Replanner(planner=prob_astar, persistence=(2, 0.95))
    optimal_trajs =
        reduce(vcat, (prob_astar(domain, state, g)[2] for g in goals))
    suboptimal_trajs =
        reduce(vcat, (replanner(domain, state, g)[2]
                      for g in goals for i in 1:k))
    return [optimal_trajs; suboptimal_trajs]
end

init_states = generate_init_states(state, domain)

function run_birl_inference(state::State, plan::Vector{<:Term},
                            goals, domain::Domain;
                            act_noise::Real=0.1, verbose::Bool=true)
    # Generate set of initial states to sample from
    init_states = [generate_init_states(state, domain);
                   PDDL.simulate(domain, state, plan)]
    # traj = PDDL.simulate(domain, state, plan)
    # Solve MDP for each goal via real-time dynamic programming
    ff = precompute(FFHeuristic(), domain)
    planners =  [RTDPlanner(heuristic=ff, act_noise=act_noise, rollout_len=5,
                            n_rollouts=length(init_states)*10) for g in goals]
    for (planner, goal) in zip(planners, goals)
        if verbose println("Solving for $goal...") end
        Plinf.solve!(planner, domain, init_states, GoalSpec(goal))
    end
    # Iterate across plan and compute goal probabilities
    cur_goal_probs = fill(1.0/length(goals), length(goals))
    goal_probs = [cur_goal_probs]
    if verbose println("Goal probs.:") end
    for act in plan
        # For each goal, compute likelihood of act given current state
        step_probs = map(zip(planners, goals)) do (planner, goal)
            goal_spec = GoalSpec(goal)
            qs = get!(planner.qvals, hash(state),
                      Plinf.default_qvals(planner, domain, state, goal_spec))
            act_probs = Plinf.softmax(values(qs) ./ planner.act_noise)
            act_probs = Dict(zip(keys(qs), act_probs))
            return act_probs[act]
        end
        # Compute filtering distribution over goals
        cur_goal_probs = cur_goal_probs .* step_probs
        cur_goal_probs ./= sum(cur_goal_probs)
        if verbose
            for prob in cur_goal_probs @printf("%.3f\t", prob) end
            print("\n")
        end
        # Advance to next state
        state = transition(domain, state, act)
        push!(goal_probs, cur_goal_probs)
    end
    return goal_probs
end

plan = parse_pddl.(actions)
goal_probs = run_birl_inference(state, plan, goals, domain)
