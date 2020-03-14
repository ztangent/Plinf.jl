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

# Check that heuristic search correctly solves the problem
plan, _ = heuristic_search(goal, state, domain; heuristic=manhattan)
println("== Plan ==")
display(plan)
render(state; start=start_pos, goals=goal_pos, plan=plan)
end_state = execute(plan, state, domain)
@assert satisfy(goal, end_state, domain)[1] == true

# Visualize full horizon sample-based search
plt = render(state; start=start_pos, goals=goal_pos)
@gif for i=1:20
    plan, _ = sample_search(goal, state, domain, 0.1)
    plt = render!(plan, start_pos; alpha=0.05)
end
display(plt)

# Visualize sample-based replanning search
plt = render(state; start=start_pos, goals=goal_pos)
@gif for i=1:20
    plan, _ = replan_search(goal, state, domain, 0.1, 0.95)
    plt = render!(plan, start_pos; alpha=0.05)
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
    _, traj = sample_search(goal, state, domain, 0.1)
    traj = traj[1:10]
else
    # Construct plan that is highly unlikely under the prior
    wp1 = @julog [xpos == 1, ypos == 8]
    _, seg1 = heuristic_search(wp1, state, domain; heuristic=manhattan)
    wp2 = @julog [xpos == 8, ypos == 1]
    _, seg2 = heuristic_search(wp2, seg1[end], domain; heuristic=manhattan)
    traj = [seg1; seg2][1:end-3]
end
plt = render(state; start=start_pos, goals=goal_set, goal_colors=goal_colors)
plt = render!(traj, plt; alpha=0.5)

# Infer likely goals of a gridworld agent
agent_args = (goals, state, domain, sample_search, (0.1,),
              Term[], @julog([xpos, ypos]))
method = :pf # :importance
n_samples = 30
if method == :importance
    # Run importance sampling to infer the likely goal
    observations = traj_choices(traj, @julog([xpos, ypos]), :traj)
    traces, weights, _ =
        importance_sampling(task_agent, (length(traj), agent_args...),
                            observations, n_samples)
elseif method == :pf
    # Run a particle filter to perform online goal inference
    traces, weights =
        task_agent_pf(agent_args, traj, @julog([xpos, ypos]), n_samples)
end

# Plot sampled trajectory for each trace
plt = render(state; start=start_pos, goals=goal_set, goal_colors=goal_colors)
for (tr, w) in zip(traces, weights)
    traj_smp = get_retval(tr)
    color = goal_colors[tr[:goal]]
    render!(traj_smp; alpha=0.5*exp(w), color=color, radius=0.15)
end
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
