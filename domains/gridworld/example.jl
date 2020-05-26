using Julog, PDDL, Gen, Printf
using Plinf

include("utils.jl")
include("generate.jl")
include("render.jl")

#--- Initial Setup ---#

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "gridworld")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem-3.pddl"))

# Initialize state, set goal position
state = initialize(problem)
goal = [problem.goal]
goal_pos = goal_to_pos(problem.goal)
start_pos = (state[:xpos], state[:ypos])

#--- Visualize Plans ---#

# Set up Manhattan heuristic on x and y positions
manhattan = ManhattanHeuristic(@julog[xpos, ypos])

# Check that A* heuristic search correctly solves the problem
planner = AStarPlanner(heuristic=manhattan)
plan, traj = planner(domain, state, goal)
println("== Plan ==")
display(plan)
plt = render(state; start=start_pos, goals=goal_pos, plan=plan)
anim = anim_traj(traj, plt)
@assert satisfy(goal, traj[end], domain)[1] == true

# Visualize full horizon probabilistic A* search
planner = ProbAStarPlanner(heuristic=manhattan, trace_states=true)
plt = render(state; start=start_pos, goals=goal_pos)
tr = Gen.simulate(sample_plan, (planner, domain, state, goal))

# Visualize distribution over trajectories induced by planner
trajs = [planner(domain, state, goal)[2] for i in 1:20]
anim = anim_traj(trajs, plt; alpha=0.1)

# Visualize sample-based replanning search
astar = ProbAStarPlanner(heuristic=manhattan, trace_states=true)
replanner = Replanner(planner=astar, persistence=(2, 0.95))
plt = render(state; start=start_pos, goals=goal_pos)
tr = Gen.simulate(sample_plan, (replanner, domain, state, goal))
anim = anim_replan(tr, plt)

# Visualize distribution over trajectories induced by replanner
trajs = [replanner(domain, state, goal)[2] for i in 1:20]
anim = anim_traj(trajs, plt; alpha=0.1)

#--- Goal Inference Setup ---#

# Specify possible goals
goal_set = [(1, 8), (8, 8), (8, 1)]
goals = [pos_to_terms(g) for g in goal_set]
goal_colors = [:orange, :magenta, :blue]
goal_names = [string(g) for g in goal_set]

# Define uniform prior over possible goals
@gen function goal_prior()
    GoalSpec(goals[@trace(uniform_discrete(1, length(goals)), :goal)])
end
goal_strata = Dict((:goal_init => :goal) => collect(1:length(goals)))

# Assume either a planning agent or replanning agent as a model
manhattan = ManhattanHeuristic(@julog[xpos, ypos])
planner = ProbAStarPlanner(heuristic=manhattan, search_noise=0.1)
replanner = Replanner(planner=planner, persistence=(2, 0.95))
agent_planner = replanner # planner
rejuvenate = agent_planner == planner ? nothing : pf_replan_move_mh!

# Sample a trajectory as the ground truth (no observation noise)
likely_traj = false
if likely_traj
    # Construct a trajectory sampled from the prior
    goal = goals[uniform_discrete(1, length(goals))]
    _, traj = replanner(domain, state, goal)
    traj = traj[1:min(20, length(traj))]
else
    # Construct plan that is highly unlikely under the prior
    _, seg1 = AStarPlanner()(domain, state, pos_to_terms((4, 4)))
    _, seg2 = AStarPlanner()(domain, seg1[end], pos_to_terms((3, 4)))
    _, seg3 = AStarPlanner()(domain, seg2[end], pos_to_terms((5, 8)))
    traj = [seg1; seg2[2:end]; seg3[2:end]][1:end]
end
plt = render(state; start=start_pos, goals=goal_set, goal_colors=goal_colors)
plt = render!(traj, plt; alpha=0.5)
anim = anim_traj(traj, plt)

# Assume Gaussian observation noise around agent's location
obs_terms = @julog([xpos, ypos])
obs_params = observe_params([(t, normal, 0.25) for t in obs_terms]...)

# Initialize world model with planner, goal prior, initial state, and obs params
world_init = WorldInit(agent_planner, goal_prior, state)
world_config = WorldConfig(domain, agent_planner, obs_params)

#--- Offline Goal Inference ---#

# Run importance sampling to infer the likely goal
n_samples = 30
traces, weights, lml_est =
    world_importance_sampler(world_init, world_config,
                             traj, obs_terms, n_samples;
                             use_proposal=true, strata=goal_strata)

# Plot sampled trajectory for each trace
plt = render(state; start=start_pos, goals=goal_set, goal_colors=goal_colors)
render_traces!(traces, weights, plt; goal_colors=goal_colors)
plt = render!(traj[1:9], plt; alpha=0.5) # Plot original trajectory on top

# Compute posterior probability of each goal
goal_probs = get_goal_probs(traces, weights, 1:length(goal_set))
println("Posterior probabilities:")
for (goal, prob) in zip(goal_set, values(sort(goal_probs)))
    @printf "Goal: %s\t Prob: %0.3f\n" goal prob
end

# Plot bar chart of goal probabilities
plot_goal_bars!(goal_probs, goal_names, goal_colors)

#--- Online Goal Inference ---#

# Set up visualization and logging callbacks for online goal inference
anim = Animation() # Animation to store each plotted frame
goal_probs = [] # Buffer of goal probabilities over time
plotters = [ # List of subplot callbacks:
    render_cb,
    goal_lines_cb,
    # goal_bars_cb,
    # plan_lengths_cb,
    # particle_weights_cb,
]
canvas = render(state; start=start_pos, goals=goal_set, goal_colors=goal_colors)
callback = (t, s, trs, ws) ->
    (multiplot_cb(t, s, trs, ws, plotters;
                  canvas=canvas, animation=anim, show=true,
                  goal_colors=goal_colors, goal_probs=goal_probs,
                  goal_names=goal_names);
     print("t=$t\t");
     print_goal_probs(get_goal_probs(trs, ws, 1:length(goal_set))))

# Run a particle filter to perform online goal inference
n_samples = 30
traces, weights =
    world_particle_filter(world_init, world_config, traj, obs_terms, n_samples;
                          rejuvenate=rejuvenate, callback=callback,
                          strata=goal_strata)
# Show animation of goal inference
gif(anim; fps=3)
