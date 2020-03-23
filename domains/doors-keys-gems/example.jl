using Julog, PDDL, Gen, Printf
using InverseTAMP

include("render.jl")
Gen.load_generated_functions()

# Load domain and problem
path = joinpath(dirname(pathof(InverseTAMP)), "..", "domains", "doors-keys-gems")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem-3.pddl"))

# Define helper function to convert x-y tuples to Julog term
pos_to_terms(pos) = @julog([xpos == $(pos[1]), ypos == $(pos[2])])

# Initialize state, set goal position
state = initialize(problem)
start_pos = (state[:xpos], state[:ypos])
goal = [problem.goal]
gem_colors = [:red, :gold, :blue]

# Check that heuristic search correctly solves the problem
plan, _ = heuristic_search(goal, state, domain; heuristic=goal_count)
println("== Plan ==")
display(plan)
render(state; start=start_pos, plan=plan, show_pos=true, gem_colors=gem_colors)
end_state = execute(plan, state, domain)
@assert satisfy(goal, end_state, domain)[1] == true

# Visualize full horizon sample-based search
plt = render(state; start=start_pos, gem_colors=gem_colors)
@gif for i=1:20
    plan, traj = sample_search(goal, state, domain, 0.1, Inf, goal_count)
    plt = render!(traj; alpha=0.05)
end
display(plt)

# Visualize sample-based replanning search
plt = render(state; start=start_pos, gem_colors=gem_colors)
@gif for i=1:20
    plan, traj = replan_search(40, goal, state, domain, 0.1, 0.95, goal_count)
    plt = render!(traj; alpha=0.05)
end
display(plt)

# Specify possible goals
goals = [@julog([has(gem1)]), @julog([has(gem2)]), @julog([has(gem3)])]

# Sample a trajectory as the ground truth (no observation noise)
goal = goals[uniform_discrete(1, length(goals))]
_, traj = sample_search(goal, state, domain, 0.1, Inf, goal_count)
traj = traj[1:15]
plt = render(state; start=start_pos, gem_colors=gem_colors)
plt = render!(traj, plt; alpha=0.5)

# Infer likely goals of a gem-seeking agent
obs_facts = @julog [has(key1), has(key2), has(gem1), has(gem2), has(gem3)]
obs_fluents = @julog [xpos, ypos]
obs_terms = [obs_facts; obs_fluents]
agent_model = plan_agent
agent_args = (goals, state, domain, sample_search, (0.1, Inf, goal_count),
              obs_facts, obs_fluents)
method = :pf # :importance
n_samples = 20
if method == :importance
    # Run importance sampling to infer the likely goal
    observations = traj_choices(traj, obs_terms, :traj)
    traces, weights, _ =
        importance_sampling(agent_model, (length(traj), agent_args...),
                            observations, n_samples)
elseif method == :pf
    # Run a particle filter to perform online goal inference
    anim = Animation()
    plt = render(state; start=start_pos, show_objs=false)
    render_cb = (t, s, trs, ws) ->
        render_pf!(t, s, trs, ws; plt=plt, animation=anim, show=true,
                   obj_args=Dict(:gem_colors => gem_colors),
                   tr_args=Dict(:goal_colors => gem_colors))
    traces, weights =
        agent_pf(agent_model, agent_args, traj, obs_terms, n_samples;
                 callback=render_cb)
    gif(anim; fps=3)
end

# Plot sampled trajectory for each trace
plt = render(state; start=start_pos, gem_colors=gem_colors)
render_traces!(traces, weights, plt; goal_colors=gem_colors)
plt = render!(traj, plt; alpha=0.5) # Plot original trajectory on top

# Compute posterior probability of each goal
goal_probs = zeros(3)
for (tr, w) in zip(traces, weights)
    goal_probs[tr[:goal]] += exp(w)
end
println("Posterior probabilities:")
for (goal, prob) in zip(goals, goal_probs)
    @printf "Goal: %s\t Prob: %0.3f\n" goal prob
end
