using Julog, PDDL, Gen, Printf
using Plinf

include("render.jl")
include("utils.jl")

#--- Initial Setup ---#

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "block-words")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem-1.pddl"))

# Initialize state
state = initialize(problem)
goal = problem.goal

#--- Visualize Plans ---#

# Check that A* heuristic search correctly solves the problem
planner = AStarPlanner(heuristic=HAdd())
plan, traj = planner(domain, state, goal)
println("== Plan ==")
display(plan)
anim = anim_traj(traj)

# Visualize full horizon probabilistic A* search
planner = ProbAStarPlanner(heuristic=HAdd(), search_noise=1)
plt = render(state)
tr = Gen.simulate(sample_plan, (planner, domain, state, goal))
# anim = anim_plan(tr, plt)

# Visualize distribution over trajectories induced by planner
trajs = [planner(domain, state, goal)[2] for i in 1:5]
anim = anim_traj(trajs; alpha=0.1)

# Visualize sample-based replanning search
astar = ProbAStarPlanner(heuristic=HAdd(), search_noise=0.1)
replanner = Replanner(planner=astar, persistence=(2, 0.95))
plt = render(state)
tr = Gen.simulate(sample_plan, (replanner, domain, state, goal))
# anim = anim_replan(tr, plt)

# Visualize distribution over trajectories induced by replanner
trajs = [replanner(domain, state, goal)[2] for i in 1:5]
anim = anim_traj(trajs; alpha=1/length(trajs))

#--- Goal Inference Setup ---#

# Read possible goal words from file
goal_words = sort(["draw", "crow", "rope", "power", "wade"])
    # readlines(joinpath(path, "goals.txt"))
goals = word_to_terms.(goal_words)

# Define uniform prior over possible goals
@gen function goal_prior()
    GoalSpec(word_to_terms(@trace(labeled_unif(goal_words), :goal)))
end
goal_strata = Dict((:goal_init => :goal) => goal_words)

# Assume either a planning agent or replanning agent as a model
heuristic = precompute(HAdd(), domain)
planner = ProbAStarPlanner(heuristic=heuristic, search_noise=0.1)
replanner = Replanner(planner=planner, persistence=(2, 0.95))
agent_planner = replanner # planner

# Sample a trajectory as the ground truth (no observation noise)
goal = goal_prior()
plan, traj = replanner(domain, state, goal)
traj = traj[1:min(length(traj), 7)]
anim = anim_traj(traj)

# Define observation noise model
obs_params = observe_params(domain, pred_noise=0.05; state=state)
obs_terms = collect(keys(obs_params))

# Initialize world model with planner, goal prior, initial state, and obs params
world_init = WorldInit(agent_planner, goal_prior, state)
world_config = WorldConfig(domain, agent_planner, obs_params)

#--- Offline Goal Inference ---#

# Run importance sampling to infer the likely goal
n_samples = 20
traces, weights, lml_est =
    world_importance_sampler(world_init, world_config,
                             traj, obs_terms, n_samples;
                             use_proposal=true, strata=goal_strata)

# Render distribution over goal states
plt = render(traj[end])
render_traces!(traces, weights, plt)

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
callback = (t, s, trs, ws) ->
    (multiplot_cb(t, s, trs, ws, plotters;
                  canvas=canvas, animation=anim, show=true,
                  goal_probs=goal_probs, goal_names=goal_words);
     print("t=$t\t");
     print_goal_probs(get_goal_probs(trs, ws, goal_words)))

# Run a particle filter to perform online goal inference
n_samples = 20
traces, weights =
    world_particle_filter(world_init, world_config, traj, obs_terms, n_samples;
                          resample=true, rejuvenate=nothing,
                          strata=goal_strata, callback=callback)
# Show animation of goal inference
gif(anim; fps=1)
