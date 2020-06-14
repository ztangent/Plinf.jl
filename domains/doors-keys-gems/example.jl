using Julog, PDDL, Gen, Printf
using Plinf

include("utils.jl")
include("generate.jl")
include("render.jl")

#--- Initial Setup ---#

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "doors-keys-gems")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem-6.pddl"))

# Initialize state, set goal and goal colors
state = initialize(problem)
start_pos = (state[:xpos], state[:ypos])
goal = [problem.goal]
goal_colors = [colorant"#D41159", colorant"#FFC20A", colorant"#1A85FF"]
gem_terms = @julog [gem1, gem2, gem3]
gem_colors = Dict(zip(gem_terms, goal_colors))

#--- Visualize Plans ---#

# Check that A* heuristic search correctly solves the problem
planner = AStarPlanner(heuristic=GemManhattan())
plan, traj = planner(domain, state, goal)
println("== Plan ==")
display(plan)
plt = render(state; start=start_pos, plan=plan, gem_colors=gem_colors)
anim = anim_traj(traj; gem_colors=gem_colors)
@assert satisfy(goal, traj[end], domain)[1] == true

# Visualize full horizon probabilistic A* search
planner = ProbAStarPlanner(heuristic=GemManhattan(), trace_states=true)
plt = render(state; start=start_pos, gem_colors=gem_colors, show_objs=true)
tr = Gen.simulate(sample_plan, (planner, domain, state, goal))
anim = anim_plan(tr, plt)

# Visualize distribution over trajectories induced by planner
trajs = [planner(domain, state, goal)[2] for i in 1:20]
plt = render(state; start=start_pos, gem_colors=gem_colors, show_objs=false)
anim = anim_traj(trajs, plt; alpha=0.1, gem_colors=gem_colors)

# Visualize sample-based replanning search
astar = ProbAStarPlanner(heuristic=GemManhattan(), trace_states=true)
replanner = Replanner(planner=astar, persistence=(2, 0.95))
plt = render(state; start=start_pos, gem_colors=gem_colors, show_objs=true)
tr = Gen.simulate(sample_plan, (replanner, domain, state, goal))
anim = anim_replan(tr, plt; gem_colors=gem_colors, show_objs=false)

# Visualize distribution over trajectories induced by replanner
trajs = [replanner(domain, state, goal)[2] for i in 1:20]
anim = anim_traj(trajs, plt; alpha=0.1, gem_colors=gem_colors)

#--- Goal Inference Setup ---#

# Specify possible goals
goals = [@julog([has(gem1)]), @julog([has(gem2)]), @julog([has(gem3)])]
goal_idxs = collect(1:length(goals))
goal_names = [repr(t[1]) for t in goals]

# Define uniform prior over possible goals
@gen function goal_prior()
    GoalSpec(goals[@trace(uniform_discrete(1, length(goals)), :goal)])
end
goal_strata = Dict((:goal_init => :goal) => goal_idxs)

# Assume either a planning agent or replanning agent as a model
planner = ProbAStarPlanner(heuristic=GemManhattan(), search_noise=0.1)
replanner = Replanner(planner=planner, persistence=(2, 0.95))
agent_planner = replanner # planner

# Construct a trajectory with backtracking to perform inference on
plan1, traj = planner(domain, state, @julog(has(key2)))
plan2, traj = planner(domain, traj[end], @julog(not(door(8, 5))))
plan3, traj = planner(domain, traj[end], @julog(has(key1)))
plan4, traj = planner(domain, traj[end], @julog(has(gem3)))
plan = [plan1; plan2; plan3; plan4]
traj = PDDL.simulate(domain, state, plan)

# Define observation noise model
obs_params = observe_params(
    (@julog(xpos), normal, 0.25), (@julog(ypos), normal, 0.25),
    (@julog(forall(doorloc(X, Y), door(X, Y))), 0.05),
    (@julog(forall(item(Obj),has(Obj))), 0.05),
    (@julog(forall(and(item(Obj), itemloc(X, Y)), at(Obj, X, Y))), 0.05)
)
obs_terms = collect(keys(obs_params))

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
plt = render(state; start=start_pos, gem_colors=gem_colors)
render_traces!(traces, weights, plt; goal_colors=goal_colors)
plt = render!(traj, plt; alpha=0.5) # Plot original trajectory on top

# Compute posterior probability of each goal
goal_probs = get_goal_probs(traces, weights, 1:length(goals))
println("Posterior probabilities:")
for (goal, prob) in zip(goal_names, values(sort(goal_probs)))
    @printf "Goal: %s\t Prob: %0.3f\n" goal prob
end

# Plot bar chart of goal probabilities
plot_goal_bars!(goal_probs, goal_names, goal_colors)

#--- Online Goal Inference ---#

# Set up visualization and logging callbacks for online goal inference

anim = Animation() # Animation to store each plotted frame
keytimes = [4, 9, 17, 21] # Timesteps to save keyframes
keyframes = [] # Buffer of keyframes to plot as a storyboard
goal_probs = [] # Buffer of goal probabilities over time
plotters = [ # List of subplot callbacks:
    render_cb,
    # goal_lines_cb,
    # goal_bars_cb,
    # plan_lengths_cb,
    # particle_weights_cb,
]
canvas = render(state; start=start_pos, show_objs=false)
callback = (t, s, trs, ws) ->
    (goal_probs_t = collect(values(sort!(get_goal_probs(trs, ws, goal_idxs))));
     push!(goal_probs, goal_probs_t);
     multiplot_cb(t, s, trs, ws, plotters;
                  trace_future=true, plan=plan,
                  start_pos=start_pos, start_dir=:down,
                  canvas=canvas, animation=anim, show=true,
                  keytimes=keytimes, keyframes=keyframes,
                  gem_colors=gem_colors, goal_colors=goal_colors,
                  goal_probs=goal_probs, goal_names=goal_names);
     print("t=$t\t"); print_goal_probs(get_goal_probs(trs, ws, goal_idxs)))

# Set up rejuvenation moves
goal_rejuv! = pf -> pf_goal_move_accept!(pf, goals)
plan_rejuv! = pf -> pf_replan_move_accept!(pf)
mixed_rejuv! = pf -> pf_mixed_move_accept!(pf, goals; mix_prob=0.25)

# Run a particle filter to perform online goal inference
n_samples = 30
traces, weights =
    world_particle_filter(world_init, world_config, traj, obs_terms, n_samples;
                          resample=true, rejuvenate=mixed_rejuv!,
                          callback=callback, strata=goal_strata)
# Show animation of goal inference
gif(anim; fps=2)

## Plot storyboard of keyframes ##

storyboard = plot_storyboard(
    keyframes, goal_probs, keytimes;
    time_lims=(1, 27), legend=false,
    titles=["Initially ambiguous goal",
            "Red eliminated upon key pickup",
            "Yellow most likely upon unlock",
            "Switch to blue upon backtracking"],
    goal_names=["Red Gem", "Yellow Gem", "Blue Gem"],
    goal_colors=goal_colors)
