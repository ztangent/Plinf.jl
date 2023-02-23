using Julog, PDDL, Printf
using SymbolicPlanners, Plinf
using Gen, GenParticleFilters

include("utils.jl")
include("ascii.jl")
include("render.jl")

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

#--- Visualize Plans ---#

# Set up Manhattan heuristic on x and y positions
manhattan = ManhattanHeuristic(@pddl("xpos", "ypos"))

# Check that A* heuristic search correctly solves the problem
planner = AStarPlanner(manhattan)
sol = planner(domain, state, goal)

plan = collect(sol)
plt = render(state; start=start_pos, goals=goal_pos, plan=plan)
anim = anim_traj(sol.traj, plt)
@assert satisfy(domain, traj[end], goal) == true

#--- Goal Inference Setup ---#

# Specify possible goals
goal_set = [(1, 1), (8, 1), (8, 8)]
goals = [pos_to_terms(g) for g in goal_set]
goal_colors = [:orange, :magenta, :blue]
goal_names = [string(g) for g in goal_set]

# Define uniform prior over possible goals
@gen function goal_prior()
    Specification(goals[@trace(uniform_discrete(1, length(goals)), :goal)])
end
goal_strata = Dict((:init=>:agent=>:goal=>:goal) => collect(1:length(goals)))

# Cache domain for faster performance
domain = CachedDomain(domain)

# Configure agent model with domain, planner, and goal prior
manhattan = ManhattanHeuristic(@pddl("xpos", "ypos"))
planner = ProbAStarPlanner(manhattan, search_noise=0.1)
agent_config = AgentConfig(
    domain, planner;
    goal_config = StaticGoalConfig(goal_prior), # Assume fixed goal over time
    replan_args = (budget_dist_args=(2, 0.05, 1),), # Assume random search budget
    act_epsilon = 0.05,  # Assume a small amount of action noise
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

# Sample a trajectory as the ground truth (no observation noise)
likely_traj = true
if likely_traj
    # Construct a trajectory sampled from the prior
    goal = goals[uniform_discrete(1, length(goals))]
    world_states = world_model(20, world_config)
    obs_traj = getproperty.(world_states, :env_state)
else
    # Construct plan that is highly unlikely under the prior
    astar = AStarPlanner(manhattan)
    sol1 = astar(domain, state, pos_to_terms((4, 5)))
    sol2 = astar(domain, sol1.trajectory[end], pos_to_terms((3, 5)))
    sol3 = astar(domain, sol2.trajectory[end], pos_to_terms((5, 1)))
    obs_traj = [sol1.trajectory[2:end]; sol2.trajectory[2:end]; sol3.trajectory[2:end]]
end
plt = render(state; start=start_pos, goals=goal_set, goal_colors=goal_colors)
plt = render!(obs_traj, plt; alpha=0.5)
anim = anim_traj(obs_traj, plt)

#--- Online Goal Inference ---#

callback = (t, obs, pf_state) -> begin
    print("t=$t\t")
    print_goal_probs(get_goal_probs(pf_state, 1:length(goal_set)))
end

obs_choices = state_choicemap_vec(obs_traj, obs_terms; batch_size=3)

# Configure SIPS particle filter
sips = SIPS(world_config, resample_cond=:ess)

# Run a particle filter to perform online goal inference
n_samples = 60
pf_state = sips(
    n_samples, obs_choices;
    init_args=(init_strata=goal_strata,),
    callback=callback
)
