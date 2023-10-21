using PDDL, Printf
using SymbolicPlanners, Plinf
using Gen, GenParticleFilters
using PDDLViz, GLMakie

include("utils.jl")

#--- Initial Setup ---#

# Load domain and problem
domain = load_domain(joinpath(@__DIR__, "domain.pddl"))
problem = load_problem(joinpath(@__DIR__, "problems", "problem-1.pddl"))

# Initialize state and construct goal specification
state = initstate(domain, problem)
spec = Specification(problem)

# Compile domain for faster performance
domain, state = PDDL.compiled(domain, state)

#--- Define Renderer ---#

# Construct blocksworld renderer
renderer = BlocksworldRenderer(resolution=(800, 800))

# Visualize initial state
canvas = renderer(domain, state)

#--- Visualize Plans ---#

# Check that A* heuristic search correctly solves the problem
planner = AStarPlanner(FFHeuristic(), save_search=true)
sol = planner(domain, state, spec)
@assert satisfy(domain, sol.trajectory[end], problem.goal) == true
display(sol)

# Visualize resulting plan
plan = collect(sol)
anim = anim_plan(renderer, domain, state, plan;
                 format="gif", move_speed=0.4, framerate=24)

#--- Model Configuration ---#

# Define possible goal words
goal_words = sort(["draw", "crow", "rope", "power", "wade"])
goals = word_to_terms.(goal_words)

# Define uniform prior over possible goals
@gen function goal_prior()
    goal ~ uniform_discrete(1, length(goals))
    return Specification(goals[goal])
end

# Construct iterator over goal choicemaps for stratified sampling
goal_addr = :init => :agent => :goal => :goal
goal_strata = choiceproduct((goal_addr, 1:length(goals)))

# Configure agent model with domain, planner, and goal prior
heuristic = precomputed(FFHeuristic(), domain, state)
planner = ProbAStarPlanner(heuristic, search_noise=0.1)
agent_config = AgentConfig(
    domain, planner;
    # Assume fixed goal over time
    goal_config = StaticGoalConfig(goal_prior),
    # Assume the agent randomly replans over time
    replan_args = (
        prob_replan = 0.1, # Probability of replanning at each timestep
        budget_dist = shifted_neg_binom, # Search budget distribution
        budget_dist_args = (2, 0.05, 1) # Budget distribution parameters
    ),
    # Assume a small amount of action noise
    act_epsilon = 0.05,
)

# Define observation noise model
obs_params = ObsNoiseParams(domain, state, pred_noise=0.05)
obs_terms = collect(keys(obs_params))

# Configure world model with planner, goal prior, initial state, and obs params
world_config = WorldConfig(
    agent_config = agent_config,
    env_config = PDDLEnvConfig(domain, state),
    obs_config = MarkovObsConfig(domain, obs_params)
)

#--- Test Trajectory Generation ---#

# Construct observed trajectory
likely_traj = false
if likely_traj
    # Sample a trajectory as the ground truth (no observation noise)
    goal = goal_prior()
    sol = planner(domain, state, spec)
    obs_traj = sol.trajectory[1:min(length(sol) + 1, 7)]
else
    # Use manually-specified trajectory
    plan = @pddl("(pick-up o)","(stack o w)","(unstack r p)","(stack r o)",
                 "(unstack d a)","(put-down d)","(unstack a c)","(put-down a)",
                 "(pick-up c)", "(stack c r)")
    obs_traj = PDDL.simulate(domain, state, plan)
end

# Visualize trajectory
anim = anim_plan(renderer, domain, state, plan;
                 format="gif", transition=PDDLViz.StepTransition(),
                 framerate=2)
storyboard = render_storyboard(
    anim, [1, 3, 5, 7],
    subtitles = ["(i) Initial state",
                 "(ii) 'o' is stacked on 'w'",
                 "(iii) 'r' is stacked on 'o'",
                 "(iv) 'd' is unstacked from 'a'"],
    xlabels = ["t = 1", "t = 3", "t = 5", "t = 7"],
    xlabelsize = 20, subtitlesize = 24
)

# Construct iterator over observation timesteps and choicemaps
t_obs_iter = state_choicemap_pairs(obs_traj, obs_terms; batch_size=1)

#--- Online Goal Inference ---#

# Construct callback for logging data and visualizing inference
callback = BlocksworldCombinedCallback(
    renderer, domain;
    goal_addr = goal_addr,
    goal_names = goal_words,
    obs_trajectory = obs_traj,
    print_goal_probs = true,
    plot_goal_bars = true,
    plot_goal_lines = true,
    render = true,
    record = true
)

# Configure SIPS particle filter
sips = SIPS(world_config, resample_cond=:ess, rejuv_cond=:periodic,
            rejuv_kernel=ReplanKernel(2), period=2)

# Run particle filter to perform online goal inference
n_samples = 50
pf_state = sips(
    n_samples, t_obs_iter;
    init_args=(init_strata=goal_strata,),
    callback=callback
);

# Extract animation
anim = callback.record.animation

# Create goal inference storyboard
storyboard = render_storyboard(
    anim, [1, 3, 5, 7],
    subtitles = ["(i) Initial state",
                 "(ii) 'o' is stacked on 'w'",
                 "(iii) 'r' is stacked on 'o'",
                 "(iv) 'd' is unstacked from 'a'"],
    xlabels = ["t = 1", "t = 3", "t = 5", "t = 7"],
    xlabelsize = 20, subtitlesize = 24,
    n_rows = 2
);
resize!(storyboard, 2000, 1200)
display(storyboard)
