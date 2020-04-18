using Julog, PDDL, Gen, Printf
using Plinf

include("utils.jl")
include("render.jl")

#--- Initial Setup ---#

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "gridworld")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem-3.pddl"))

# Initialize state, set goal position
state = initialize(problem)
start_pos = (state[:xpos], state[:ypos])
goal_pos = (7, 8)
goal = pos_to_terms(goal_pos)

#--- Visualize Plans ---#

# Check that A* heuristic search correctly solves the problem
planner = AStarPlanner(heuristic=manhattan)
plan, _ = planner(domain, state, goal)
println("== Plan ==")
display(plan)
plt = render(state; start=start_pos, goals=goal_pos, plan=plan)
traj = PDDL.simulate(domain, state, plan)
@assert satisfy(goal, traj[end], domain)[1] == true

# Visualize full horizon probabilistic A* search
planner = ProbAStarPlanner(heuristic=manhattan, search_noise=10)
plt = render(state; start=start_pos, goals=goal_pos)
@gif for i=1:20
    plan, traj = planner(domain, state, goal)
    plt = render!(traj; alpha=0.05)
end
display(plt)

# Visualize sample-based replanning search
astar = ProbAStarPlanner(heuristic=manhattan, search_noise=2)
replanner = Replanner(planner=astar, persistence=0.95)
plt = render(state; start=start_pos, goals=goal_pos)
@gif for i=1:20
    plan, traj = replanner(domain, state, goal)
    plt = render!(traj; alpha=0.05)
end
display(plt)

#--- Goal Inference Setup ---#

# Specify possible goals
goal_set = [(1, 8), (8, 8), (8, 1)]
goals = [pos_to_terms(g) for g in goal_set]
goal_colors = [:orange, :magenta, :blue]
goal_names = [string(g) for g in goal_set]

# Sample a trajectory as the ground truth (no observation noise)
likely_traj = true
if likely_traj
    # Construct a trajectory sampled from the prior
    goal = goals[uniform_discrete(1, length(goals))]
    _, traj = planner(domain, state, goal)
    traj = traj[1:min(20, length(traj))]
else
    # Construct plan that is highly unlikely under the prior
    wp1 = @julog [xpos == 1, ypos == 8]
    _, seg1 = AStarPlanner()(domain, state, wp1)
    wp2 = @julog [xpos == 8, ypos == 1]
    _, seg2 = AStarPlanner()(domain, seg1[end], wp2)
    traj = [seg1; seg2[2:end]][1:end-3]
end
plt = render(state; start=start_pos, goals=goal_set, goal_colors=goal_colors)
plt = render!(traj, plt; alpha=0.5)

# Assume Gaussian observation noise around agent's location
obs_terms = @julog([xpos, ypos])
obs_params = observe_params([(t, normal, 0.25) for t in obs_terms]...)

# Assume either a planning agent or replanning agent as a model
agent_model = plan_agent # replan_agent
if agent_model == plan_agent
    agent_args = (planner, domain, state, goals, obs_params)
    rejuvenate = nothing
else
    @gen observe_fn(state::State) =
        @trace(observe_state(state, domain, obs_params))
    agent_args = (replanner, domain, state, goals, observe_fn)
    rejuvenate = replan_rejuvenate
end

#--- Offline Goal Inference ---#

# Run importance sampling to infer the likely goal
n_samples = 20
observations = traj_choices(traj, domain, @julog([xpos, ypos]), :traj)
traces, weights, _ =
    importance_sampling(agent_model, (length(traj), agent_args...),
                        observations, n_samples)

# Plot sampled trajectory for each trace
plt = render(state; start=start_pos, goals=goal_set, goal_colors=goal_colors)
render_traces!(traces, weights, plt; goal_colors=goal_colors)
plt = render!(traj, plt; alpha=0.5) # Plot original trajectory on top

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
n_samples = 20
traces, weights =
    agent_pf(agent_model, agent_args, traj, obs_terms, domain, n_samples;
             rejuvenate=rejuvenate, callback=callback)
# Show animation of goal inference
gif(anim; fps=3)
