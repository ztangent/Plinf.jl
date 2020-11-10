using Julog, PDDL, Gen, Printf
using Plinf

include("utils.jl")
include("generate.jl")
include("render.jl")

#--- Initial Setup ---#

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "ai2thor-2d")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "mcs-eval3-map1-goal1.pddl"))

# Initialize state, set goal and goal colors
state = initialize(problem)
start_pos = (state[:xpos], state[:ypos])
goal = [problem.goal]

#--- Visualize Plans ---#

# Check that A* heuristic search correctly solves the problem
planner = AStarPlanner(heuristic=GoalManhattan())
plan, traj = planner(domain, state, goal)
println("== Plan ==")
display(plan)
plt = render(state; start=start_pos)
anim = anim_traj(traj)

#--- Goal Inference Setup ---#

# Specify possible goals
goals = @pddl("(retrieve cylinder1)", "(retrieve block1)")
goal_idxs = collect(1:length(goals))
goal_names = ["Cylinder", "Block"]
goal_colors= [cgrad(:plasma)[1], cgrad(:plasma)[128]]

# Define uniform prior over possible goals
@gen function goal_prior()
    GoalSpec(goals[@trace(uniform_discrete(1, length(goals)), :goal)])
end
goal_strata = Dict((:goal_init => :goal) => goal_idxs)

# Assume either a planning agent or replanning agent as a model
planner = ProbAStarPlanner(heuristic=GoalManhattan(), search_noise=0.5)
replanner = Replanner(planner=planner, persistence=(2, 0.95))
agent_planner = replanner # planner

# Construct a trajectory for the transfer task
astar = AStarPlanner(heuristic=GoalManhattan())
plan, traj = astar(domain, state, goals[1])

# Define observation noise model
obs_params = observe_params(
    (@julog(handsfree), 0.05),
    (@julog(xpos), normal, 1.0), (@julog(ypos), normal, 1.0),
    (@julog(forall(item(Obj), xitem(Obj))), normal, 1.0),
    (@julog(forall(item(Obj), yitem(Obj))), normal, 1.0)
)
obs_terms = collect(keys(obs_params))

# Initialize world model with planner, goal prior, initial state, and obs params
world_init = WorldInit(agent_planner, goal_prior, state)
world_config = WorldConfig(domain, agent_planner, obs_params)

#--- Online Goal Inference ---#

# Set up visualization and logging callbacks for online goal inference

anim = Animation() # Animation to store each plotted frame
keytimes = Int[] # Timesteps to save keyframes
keyframes = [] # Buffer of keyframes to plot as a storyboard
goal_probs = [] # Buffer of goal probabilities over time
plotters = [ # List of subplot callbacks:
    render_cb,
    # goal_lines_cb,
    goal_bars_cb,
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
                  goal_colors=goal_colors, goal_probs=goal_probs,
                  goal_names=goal_names);
     print("t=$t\t"); print_goal_probs(get_goal_probs(trs, ws, goal_idxs)))

# Set up rejuvenation moves
# goal_rejuv! = pf -> pf_goal_move_accept!(pf, goals)
# plan_rejuv! = pf -> pf_replan_move_accept!(pf)
# mixed_rejuv! = pf -> pf_mixed_move_accept!(pf, goals; mix_prob=0.25)

# Run a particle filter to perform online goal inference
n_samples = 30
traces, weights =
    world_particle_filter(world_init, world_config, traj, obs_terms, n_samples;
                          resample=true, rejuvenate=nothing,
                          callback=callback, strata=goal_strata)
# Show animation of goal inference
gif(anim; fps=2)

#--- Testing ASCII state conversion ---#
# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "mcs-eval3")

# Testing on scene with one block
# Initialize state from problem
problem = load_ascii_problem(joinpath(path, "agent_grid_outputs", "0000_0000_0000.txt"))
state = initialize(problem)

# Get state vectors
scene_num = 0
states = load_scene(scene_num, joinpath(path, "agent_grid_outputs"))
@assert states[1][1] == state
@assert states[1][2] != state

# Testing on scene with one cylinder
# Initialize state from problem
problem = load_ascii_problem(joinpath(path, "agent_grid_outputs", "0010_0000_0000.txt"))
state = initialize(problem)

# Get state vectors
scene_num = 10
states = load_scene(scene_num, joinpath(path, "agent_grid_outputs"))
@assert states[1][1] == state
@assert states[1][2] != state

# Testing on scene with two bblocks (this is scene 3 of the multi-object dataset)
# Initialize state from problem
problem = load_ascii_problem(joinpath(path, "agent_grid_outputs", "0016_0001_0000.txt"))
state = initialize(problem)

# Get state vectors
scene_num = 16
states = load_scene(scene_num, joinpath(path, "agent_grid_outputs"))
@assert states[2][1] == state
@assert states[2][2] != state
