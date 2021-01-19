using Julog, PDDL, Gen, Printf
using Plinf, CSV
using DataFrames

include("render.jl")
include("utils.jl")
include("./new-scenarios/experiment-scenarios.jl")

#--- Initial Setup ---#

# Specify problem name
category = "2"
subcategory = "3"
# experiment = "experiment-" * category * "-" * subcategory
# problem_name =  experiment * ".pddl"
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

#--- Goal Inference Setup ---#

# Define uniform prior over possible goals
@gen function goal_prior()
    GoalSpec(word_to_terms(@trace(labeled_unif(goal_words), :goal)))
end
goal_strata = Dict((:goal_init => :goal) => goal_words)

# Assume either a planning agent or replanning agent as a model
heuristic = precompute(FFHeuristic(), domain)
planner = ProbAStarPlanner(heuristic=heuristic, search_noise=0.1)
replanner = Replanner(planner=planner, persistence=(2, 0.95))
agent_planner = replanner # planner

# Configure agent model with goal prior and planner
act_noise = 0.05 # Assume a small amount of action noise
agent_init = AgentInit(agent_planner, goal_prior)
agent_config = AgentConfig(domain, agent_planner, act_noise=0.05)

# Define observation noise model
obs_params = observe_params(domain, pred_noise=0.05; state=state)
obs_terms = collect(keys(obs_params))

# Configure world model with planner, goal prior, initial state, and obs params
world_init = WorldInit(agent_init, state, state)
world_config = WorldConfig(domain, agent_config, obs_params)

# likely_traj = true
# if likely_traj
#     # Sample a trajectory as the ground truth (no observation noise)
#     goal = goal_prior()
#     plan, traj = planner(domain, state, goal)
#     traj = traj[1:min(length(traj), 7)]
# else
#     # Use trajectory that comes from a different planner
#     plan = @pddl("(pick-up o)","(stack o w)","(unstack r p)","(stack r o)",
#                  "(unstack d a)","(put-down d)","(unstack a c)","(put-down a)",
#                  "(pick-up c)", "(stack c r)")
#     traj = PDDL.simulate(domain, state, plan)
# end

anim = anim_traj(traj)


#--- Offline Goal Inference ---#

# Run importance sampling to infer the likely goal
n_samples = 20
traces, weights, lml_est =
    world_importance_sampler(world_init, world_config,
                             traj, obs_terms, n_samples;
                             use_proposal=true, strata=goal_strata);

# Render distribution over goal states
plt = render(traj[end])
#render_traces!(traces, weights, plt)

# Compute posterior probability of each goal
goal_probs = get_goal_probs(traces, weights, goal_words)
println("Posterior probabilities:")
for (goal, prob) in zip(sort(goal_words), values(sort(goal_probs)))
    @printf "Goal: %s\t Prob: %0.3f\n" goal prob
end

# Plot bar chart of goal probabilities
plot_goal_bars!(goal_probs, goal_words)


#--- Online Goal Inference ---#

# Set up visualization and logging callbacks for online goal inference
anim = Animation() # Animation to store each plotted frame
goal_probs = [] # Buffer of goal probabilities over time
plotters = [ # List of subplot callbacks:
    render_cb,
    # goal_lines_cb,
    goal_bars_cb,
    # plan_lengths_cb,
    # particle_weights_cb,
]
canvas = render(state; show_blocks=false)
callback = (t, s, trs, ws) -> begin
    multiplot_cb(t, s, trs, ws, plotters;
                 canvas=canvas, animation=anim, show=true,
                 goal_probs=goal_probs, goal_names=goal_words);
    print("t=$t\t");
    push!(goal_probs, return_goal_probs(get_goal_probs(trs, ws, goal_words)));
    print_goal_probs(get_goal_probs(trs, ws, goal_words))
end
# callback = (t, s, trs, ws) ->
#     (multiplot_cb(t, s, trs, ws, plotters;
#                   canvas=canvas, animation=anim, show=true,
#                   goal_probs=goal_probs, goal_names=goal_words);
#      print("t=$t\t");
#      push!(goal_probs, return_goal_probs(get_goal_probs(trs, ws, goal_words)));
#      print_goal_probs(get_goal_probs(trs, ws, goal_words))
#      )

# Set up action proposal to handle potential action noise
act_proposal = act_noise > 0 ? forward_act_proposal : nothing
act_proposal_args = (act_noise,)

# Run a particle filter to perform online goal inference
n_samples = 500
traces, weights =
    world_particle_filter(world_init, world_config, traj, obs_terms, n_samples;
                          resample=true, rejuvenate=pf_replan_move_accept!,
                          strata=goal_strata, callback=callback,
                          act_proposal=act_proposal,
                          act_proposal_args=act_proposal_args)

# Show animation of goal inference
#gif(anim, joinpath(path, "sips-results", experiment*".gif"), fps=1)

df = DataFrame(Timestep=collect(1:length(traj)), Probs=goal_probs)
CSV.write( joinpath(path, "sips-results", experiment*".csv"), df)
