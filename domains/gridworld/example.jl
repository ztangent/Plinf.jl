using Julog, PDDL, Gen, Printf
using InverseTAMP

include("render.jl")
Gen.load_generated_functions()

# Load domain and problem
path = joinpath(dirname(pathof(InverseTAMP)), "..", "domains", "gridworld")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem-3.pddl"))

# Define helper function to convert x-y tuples to Julog term
pos_to_terms(pos) = @julog([xpos == $(pos[1]), ypos == $(pos[2])])

# Initialize state, set goal position
state = initialize(problem)
start_pos = (state[:xpos], state[:ypos])
goal_pos = (7, 8)
goal = pos_to_terms(goal_pos)

# Check that A* heuristic search correctly solves the problem
planner = AStarPlanner(heuristic=manhattan)
plan, _ = planner(domain, state, goal)
println("== Plan ==")
display(plan)
render(state; start=start_pos, goals=goal_pos, plan=plan)
end_state = execute(plan, state, domain)
@assert satisfy(goal, end_state, domain)[1] == true

# Visualize full horizon probabilistic A* search
planner = ProbAStarPlanner(heuristic=manhattan, search_noise=0.1)
plt = render(state; start=start_pos, goals=goal_pos)
@gif for i=1:20
    plan, traj = planner(domain, state, goal)
    plt = render!(traj; alpha=0.05)
end
display(plt)

# Visualize sample-based replanning search
astar = ProbAStarPlanner(heuristic=manhattan, search_noise=0.5)
replanner = Replanner(planner=astar, persistence=0.95)
plt = render(state; start=start_pos, goals=goal_pos)
@gif for i=1:20
    plan, traj = replanner(domain, state, goal)
    plt = render!(traj; alpha=0.05)
end
display(plt)

# Specify possible goals
goal_set = [(1, 8), (8, 8), (8, 1)]
goals = [pos_to_terms(g) for g in goal_set]
goal_colors = [:orange, :magenta, :blue]

# Sample a trajectory as the ground truth (no observation noise)
likely_traj = true
if likely_traj
    # Construct a trajectory sampled from the prior
    goal = goals[uniform_discrete(1, length(goals))]
    _, traj = planner(domain, state, goal)
    traj = traj[1:10]
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

# Assume either a planning agent or replanning agent as a model
agent_model = plan_agent # replan_agent
if agent_model == plan_agent
    agent_args = (planner, domain, state, goals, Term[], @julog([xpos, ypos]))
else
    @gen observe_fn(state::State) =
        @trace(observe_state(state, Term[], @julog([xpos, ypos])))
    agent_args = (replanner, domain, state, goals, observe_fn)
end

# Infer likely goals of a gridworld agent
method = :pf # :importance
n_samples = 30
if method == :importance
    # Run importance sampling to infer the likely goal
    observations = traj_choices(traj, @julog([xpos, ypos]), :traj)
    traces, weights, _ =
        importance_sampling(agent_model, (length(traj), agent_args...),
                            observations, n_samples)
elseif method == :pf
    # Run a particle filter to perform online goal inference
    anim = Animation()
    plt = render(state; start=start_pos, goals=goal_set, goal_colors=goal_colors)
    render_cb = (t, s, trs, ws) ->
        render_pf!(t, s, trs, ws; tr_args=Dict(:goal_colors => goal_colors),
                   plt=plt, animation=anim, show=true)
    traces, weights =
        agent_pf(agent_model, agent_args, traj, @julog([xpos, ypos]),
                 n_samples; callback=render_cb)
    gif(anim; fps=5)
end

# Plot sampled trajectory for each trace
plt = render(state; start=start_pos, goals=goal_set, goal_colors=goal_colors)
render_traces!(traces, weights, plt; goal_colors=goal_colors)
plt = render!(traj, plt; alpha=0.5) # Plot original trajectory on top

# Compute posterior probability of each goal
goal_probs = zeros(3)
for (tr, w) in zip(traces, weights)
    goal_probs[tr[:goal]] += exp(w)
end
println("Posterior probabilities:")
for (goal, prob) in zip(goal_set, goal_probs)
    @printf "Goal: %s\t Prob: %0.3f\n" goal prob
end
