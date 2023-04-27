using PDDL, Printf
using SymbolicPlanners, Plinf
using Gen, GenParticleFilters
using PDDLViz, GLMakie

include("utils.jl")

#--- Initial Setup ---#

# Register PDDL array theory
PDDL.Arrays.@register()

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "gridworld")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem-3.pddl"))

# Initialize state, set goal position
state = initstate(domain, problem)
goal = [problem.goal]
goal_pos = goal_to_pos(problem.goal)
start_pos = (state[pddl"xpos"], state[pddl"ypos"])

#--- Define Renderer ---#

# Construct gridworld renderer
loc_colors = PDDLViz.colorschemes[:vibrant]
renderer = PDDLViz.GridworldRenderer(
    agent_renderer = (d, s) -> HumanGraphic(color=:black),
    locations = [
        (start_pos..., "start", loc_colors[1]),
        (goal_pos..., "goal", loc_colors[3]),
    ]
)

# Visualize initial state
canvas = renderer(domain, state)

#--- Visualize Plans ---#

# Set up Manhattan heuristic on x and y positions
manhattan = ManhattanHeuristic(@pddl("xpos", "ypos"))

# Check that A* heuristic search correctly solves the problem
planner = AStarPlanner(manhattan, save_search=true, save_search_order=true)
sol = planner(domain, state, goal)

# Visualize resulting plan
plan = collect(sol)
canvas = renderer(canvas, domain, state, plan)
@assert satisfy(domain, sol.trajectory[end], goal) == true

# Visualise search tree
canvas = renderer(canvas, domain, state, sol, show_trajectory=false)

# Animate plan
anim = anim_plan(renderer, domain, state, plan;
                 format="gif", framerate=5, trail_length=10)

#--- Model Configuration ---#

# Specify possible goals
goal_set = [(1, 1), (8, 1), (8, 8)]
goals = [pos_to_terms(g) for g in goal_set]
goal_colors = [:orange, :magenta, :blue]
goal_names = ["A", "B", "C"]

# Update renderer to include goal locations
renderer.locations = [
    [(start_pos..., "start", loc_colors[1])];
    [(g..., goal_names[i], goal_colors[i]) for (i, g) in enumerate(goal_set)]
]

# Define uniform prior over possible goals
@gen function goal_prior()
    goal ~ uniform_discrete(1, length(goals))
    return Specification(goals[goal])
end
# Construct iterator over goal choicemaps for stratified sampling
goal_addr = :init => :agent => :goal => :goal
goal_strata = choiceproduct((goal_addr, 1:length(goals)))

# Compile and cache domain for faster performance
domain, state = PDDL.compiled(domain, state)
domain = CachedDomain(domain)

# Configure agent model with domain, planner, and goal prior
manhattan = ManhattanHeuristic(@pddl("xpos", "ypos"))
planner = ProbAStarPlanner(manhattan, search_noise=0.1)
agent_config = AgentConfig(
    domain, planner;
    # Assume fixed goal over time
    goal_config = StaticGoalConfig(goal_prior),
    # Assume random replanning, random search budget
    replan_args = (prob_replan=0.1, budget_dist_args=(2, 0.05, 1),),
    # Assume a small amount of action noise
    act_epsilon = 0.05,
)

# Assume Gaussian observation noise around agent's location
obs_terms = @pddl("(xpos)", "(ypos)")
obs_params = ObsNoiseParams([(t, normal, 0.25) for t in obs_terms]...)

# Configure world model with planner, goal prior, initial state, and obs params
world_config = WorldConfig(
    agent_config = agent_config,
    env_config = PDDLEnvConfig(domain, state),
    obs_config = MarkovObsConfig(domain, obs_params)
)

#--- Online Goal Inference ---#

# Generate a trajectory as the ground truth (no observation noise)
likely_traj = true
if likely_traj
    # Construct an optimal trajectory to goal B
    astar = AStarPlanner(manhattan)
    sol = astar(domain, state, pos_to_terms((8, 1)))
    obs_traj = sol.trajectory
else
    # Construct suboptimal trajectory that is highly unlikely under the prior
    astar = AStarPlanner(manhattan)
    sol1 = astar(domain, state, pos_to_terms((4, 5)))
    sol2 = astar(domain, sol1.trajectory[end], pos_to_terms((3, 5)))
    sol3 = astar(domain, sol2.trajectory[end], pos_to_terms((5, 1)))
    obs_traj = [sol1.trajectory; sol2.trajectory[2:end]; sol3.trajectory[2:end]]
end
canvas = renderer(domain, obs_traj)
anim = anim_trajectory!(canvas, renderer, domain, obs_traj;
                        format="gif", framerate=5)

# Define callback functions for printing and logging data
print_cb = PrintStatsCallback(
    (goal_addr, 1:length(goals));
    header="t\tP(A)\tP(B)\tP(C)\n"
)
logger_cb = DataLoggerCallback(
    t = (t, pf) -> t::Int,
    goal_probs = pf -> probvec(pf, goal_addr, 1:length(goals))::Vector{Float64},
    lml_est = pf -> log_ml_estimate(pf)::Float64,
)

# Define callback functions for plotting
figure = Figure(resolution=(800, 400))
goal_bars_cb = BarPlotCallback(
    figure[1, 1],
    (t, pf) -> probvec(pf, goal_addr, 1:length(goals))::Vector{Float64};
    color = goal_colors,
    axis = (xlabel="Goal", ylabel = "Probability", limits=(nothing, (0, 1)), 
            xticks=(1:length(goals), goal_names))
)
goal_lines_cb = SeriesPlotCallback(
    figure[1, 2],
    logger_cb, :goal_probs, # Look up :goal_probs variable from data logger
    ps -> reduce(hcat, ps); # Convert list of vectors to matrix for plotting
    color = goal_colors,
    axis = (xlabel="Time", ylabel = "Probability", limits=(nothing, (0, 1)))
)

# Combine all callback functions
callback = CombinedCallback(
    print_cb, logger_cb, goal_bars_cb, goal_lines_cb; sleep=0.1
)

# Construct iterator over observation timesteps and choicemaps 
t_obs_iter = state_choicemap_pairs(obs_traj, obs_terms; batch_size=1)

# Configure SIPS particle filter
sips = SIPS(world_config, resample_cond=:none, rejuv_cond=:periodic,
            rejuv_kernel=ReplanKernel(2), period=5)

# Empty logger of data
empty!(logger_cb)

# Run particle filter to perform online goal inference
n_samples = 60
pf_state = sips(
    n_samples, t_obs_iter;
    init_args=(init_strata=goal_strata,),
    callback=callback
);
