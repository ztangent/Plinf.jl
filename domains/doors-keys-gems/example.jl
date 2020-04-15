using Julog, PDDL, Gen, Printf
using Plinf

include("render.jl")

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "doors-keys-gems")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem-3.pddl"))

# Define helper function to convert x-y tuples to Julog term
pos_to_terms(pos) = @julog([xpos == $(pos[1]), ypos == $(pos[2])])

# Initialize state, set goal position
state = initialize(problem)
start_pos = (state[:xpos], state[:ypos])
goal = [problem.goal]
gem_colors = [:red, :gold, :blue]

# Check that A* heuristic search correctly solves the problem
planner = AStarPlanner(heuristic=goal_count)
plan, _ = planner(domain, state, goal)
println("== Plan ==")
display(plan)
render(state; start=start_pos, plan=plan, show_pos=true, gem_colors=gem_colors)
traj = PDDL.simulate(domain, state, plan)
@assert satisfy(goal, traj[end], domain)[1] == true

# Visualize full horizon probabilistic A* search
planner = ProbAStarPlanner(heuristic=goal_count, search_noise=10)
plt = render(state; start=start_pos, gem_colors=gem_colors)
@gif for i=1:20
    plan, traj = planner(domain, state, goal)
    plt = render!(traj; alpha=0.05)
end
display(plt)

# Visualize sample-based replanning search
astar = ProbAStarPlanner(heuristic=goal_count, search_noise=2)
replanner = Replanner(planner=astar, persistence=0.95)
plt = render(state; start=start_pos, gem_colors=gem_colors)
@gif for i=1:20
    plan, traj = replanner(domain, state, goal)
    plt = render!(traj; alpha=0.05)
end
display(plt)

# Specify possible goals
goals = [@julog([has(gem1)]), @julog([has(gem2)]), @julog([has(gem3)])]

# Sample a trajectory as the ground truth (no observation noise)
goal = goals[uniform_discrete(1, length(goals))]
_, traj = planner(domain, state, goal)
traj = traj[1:min(length(traj), 25)]
plt = render(state; start=start_pos, gem_colors=gem_colors)
plt = render!(traj, plt; alpha=0.5)

# Define observation noise model
obs_params = observe_params(
    (pddl"(xpos)", normal, 0.25), (pddl"(ypos)", normal, 0.25),
    (pddl"(door ?x ?y)", 0.05),
    (pddl"(forall (?obj - item) (has ?obj))", 0.05),
    (pddl"(forall (?obj - item) (at ?obj ?x ?y))", 0.05)
)
obs_terms = collect(keys(obs_params))

# Assume either a planning agent or replanning agent as a model
agent_model = replan_agent # replan_agent
if agent_model == plan_agent
    agent_args = (planner, domain, state, goals, obs_params)
else
    @gen observe_fn(state::State) = @trace(observe_state(state, obs_params))
    agent_args = (replanner, domain, state, goals, observe_fn)
end

# Infer likely goals of a gem-seeking agent
method = :pf # :importance
n_samples = 30
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
goal_probs = zeros(length(goals))
for (tr, w) in zip(traces, weights)
    goal_probs[tr[:goal]] += exp(w)
end
println("Posterior probabilities:")
for (goal, prob) in zip(goals, goal_probs)
    @printf "Goal: %s\t Prob: %0.3f\n" goal prob
end
