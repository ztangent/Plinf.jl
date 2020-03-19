using Julog, PDDL, Gen, Printf
using InverseTAMP

include("render.jl")
Gen.load_generated_functions()

# Load domain and problem
path = joinpath(dirname(pathof(InverseTAMP)), "..", "domains", "doors-keys-gems")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem-2.pddl"))

# Define helper function to convert x-y tuples to Julog term
pos_to_terms(pos) = @julog([xpos == $(pos[1]), ypos == $(pos[2])])

# Initialize state, set goal position
state = initialize(problem)
start_pos = (state[:xpos], state[:ypos])
goal = [problem.goal]

# Check that heuristic search correctly solves the problem
plan, _ = heuristic_search(goal, state, domain; heuristic=goal_count)
println("== Plan ==")
display(plan)
render(state; start=start_pos, plan=plan, show_pos=true)
end_state = execute(plan, state, domain)
@assert satisfy(goal, end_state, domain)[1] == true

# Visualize full horizon sample-based search
plt = render(state; start=start_pos)
@gif for i=1:20
    plan, _ = sample_search(goal, state, domain, 0.1, Inf, goal_count)
    plt = render!(plan, start_pos; alpha=0.05)
end
display(plt)

# Visualize sample-based replanning search
plt = render(state; start=start_pos)
@gif for i=1:20
    plan, _ = replan_search(goal, state, domain, 0.1, 0.95, 10, goal_count)
    plt = render!(plan, start_pos; alpha=0.05)
end
display(plt)

# Specify possible goals
goals = [@julog([has(gem1)]), @julog([has(gem2)])]
gem_colors = [:red, :blue]

# Sample a trajectory as the ground truth (no observation noise)
goal = goals[uniform_discrete(1, length(goals))]
_, traj = sample_search(goal, state, domain, 0.1, Inf, goal_count)
traj = traj[1:12]
plt = render(state; start=start_pos, gem_colors=gem_colors)
plt = render!(traj, plt; alpha=0.5)

# Infer likely goals of a gridworld agent
agent_args = (goals, state, domain, sample_search, (0.1, Inf, goal_count),
              @julog([has(key1), has(gem1), has(gem2)]), @julog([xpos, ypos]))
obs_terms = @julog([xpos, ypos, has(key1), has(gem1), has(gem2)])
method = :importance
n_samples = 20
if method == :importance
    # Run importance sampling to infer the likely goal
    observations = traj_choices(traj, obs_terms, :traj)
    traces, weights, _ =
        importance_sampling(task_agent, (length(traj), agent_args...),
                            observations, n_samples)
elseif method == :pf
    # Run a particle filter to perform online goal inference
    anim = Animation()
    plt = render(state; start=start_pos, goals=goal_set, goal_colors=goal_colors)
    render_cb = (t, s, trs, ws) ->
        render_pf!(t, s, trs, ws; tr_args=Dict(:goal_colors => goal_colors),
                   plt=plt, animation=anim, show=true)
    traces, weights =
        task_agent_pf(agent_args, traj, @julog([xpos, ypos]), n_samples;
                      callback=render_cb)
    gif(anim; fps=5)
end

# Plot sampled trajectory for each trace
plt = render(state; start=start_pos, gem_colors=gem_colors)
render_traces!(traces, weights, plt; goal_colors=gem_colors)
plt = render!(traj, plt; alpha=0.5) # Plot original trajectory on top

# Compute posterior probability of each goal
goal_probs = zeros(2)
for (tr, w) in zip(traces, weights)
    goal_probs[tr[:goal]] += exp(w)
end
println("Posterior probabilities:")
for (goal, prob) in zip(goals, goal_probs)
    @printf "Goal: %s\t Prob: %0.3f\n" goal prob
end
