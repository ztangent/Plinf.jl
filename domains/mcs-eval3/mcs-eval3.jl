using Julog, PDDL, Gen, Printf
using Plinf

include("utils.jl")
include("generate.jl")
include("render.jl")

#--- Initial Setup ---#

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "mcs-eval3")
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
    GoalSpec(goals[{:goal} ~ categorical([0.5, 0.5])])
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
callback = (t, s, trs, ws, _) ->
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

#--- Hierarchical Online Goal Inference ---#

function hierarchical_goal_inference(plans_and_trajs, n_samples::Int,
                                     anim=Animation())
    n_heads, n_tails = 1.0, 1.0
    goal_probs = nothing
    for (i, (plan, traj)) in enumerate(plans_and_trajs)
        # Compute posterior mean, assuming a Beta(1, 1) hyperprior
        if i > 1
            n_heads += goal_probs[2]
            n_tails += goal_probs[1]
        end
        p = n_heads / (n_heads + n_tails)
        prior_probs = [1-p, p]

        @gen goal_prior() = GoalSpec(goals[{:goal} ~ categorical(prior_probs)])
        state = traj[1]
        start_pos = (state[:xpos], state[:ypos])
        world_init = WorldInit(agent_planner, goal_prior, state)

        println("== Trial $i ==")
        println("Prior: ", prior_probs)

        goal_probs = [] # Buffer of goal probabilities over time
        prev_lml = 0 # Previous log marginal likelihood estimate
        plotters = [ # List of subplot callbacks:
            render_cb,
            goal_lines_cb,
            # goal_bars_cb,
            # plan_lengths_cb,
            # particle_weights_cb,
        ]
        canvas = render(state; start=start_pos, show_objs=false)
        callback = (t, s, trs, ws, pf) -> begin
            lml = log_ml_estimate(pf)
            goal_probs_t = sort!(get_goal_probs(trs, ws, goal_idxs))
            push!(goal_probs, goal_probs_t |> values |> collect)
            multiplot_cb(t, s, trs, ws, plotters;
                         trace_future=true, plan=plan,
                         start_pos=start_pos, start_dir=:down,
                         canvas=canvas, animation=anim, show=true,
                         goal_colors=goal_colors, goal_probs=goal_probs,
                         goal_names=goal_names);
             print("t=$t\t")
             for (_, prob) in goal_probs_t @printf("%.3f\t", prob) end
             tv = total_variation(goal_probs[1], goal_probs[end])
             ll = lml - prev_lml # Log likelihood for current observation
             unexpected = ll <= -6.5 # Unexpected if highly unlikely
             confidence = threshold_confidence(ll, -6.5, 0.2)
             @printf("Log. Likelihood: %.3f\t", ll)
             @printf("TV: %.3f\t", tv)
             @printf("Unexpected: %s\t", unexpected)
             @printf("Confidence: %.2f\t", confidence)
             println()
             prev_lml = lml
        end

        traces, weights =
            world_particle_filter(world_init, world_config, traj, obs_terms,
                                  n_samples; resample=true, rejuvenate=nothing,
                                  callback=callback, strata=goal_strata)

        goal_probs = get_goal_probs(traces, weights)
    end
    return anim
end

# Generate state from problem with randomized object locations
function randomized_state(problem::Problem)
    state = init_state(problem)
    width, height = state[:width], state[:height]
    free_loc = state -> begin
        while true # Rejection sample for free location
            x, y = rand(1:width), rand(1:height)
            if state[:(wall($x, $y))]
                continue end
            if (state[:(xitem(block1))], state[:(yitem(block1))]) == (x, y)
                continue end
            if (state[:(xitem(cylinder1))], state[:(yitem(cylinder1))]) == (x, y)
                continue end
            return x, y
        end
    end
    state[:(xitem(block1))], state[:(yitem(block1))] = free_loc(state)
    state[:(xitem(cylinder1))], state[:(yitem(cylinder1))] = free_loc(state)
    state[:xpos], state[:ypos] = free_loc(state)
    return state
end

# Generate gridworld trajectories demonstrating agent efficiency
function generate_efficiency_trajs(problem::Problem, n::Int,
                                   params=fill((0.1, 4, 0.95), n))
    states = [randomized_state(problem) for i in 1:n]
    plans_and_trajs = map(zip(states, params)) do (state, (γ, r, q))
        planner = ProbAStarPlanner(heuristic=GoalManhattan(), search_noise=γ)
        replanner = Replanner(planner=planner, persistence=(r, q))
        plan, traj = replanner(domain, state, pddl"(retrieve cylinder1)")
    end
    return plans_and_trajs
end

# Generate gridworld trajectories demonstrating object preference
function generate_preference_trajs(problem::Problem, n::Int,
                                   goals=fill(pddl"(retrieve cylinder1)", n))
    states = [randomized_state(problem) for i in 1:n]
    astar = AStarPlanner(heuristic=GoalManhattan())
    plans_and_trajs = map(zip(states, goals)) do (state, goal)
        plan, traj = astar(domain, state, goal)
    end
    return plans_and_trajs
end

# Detect violation of expectations for agent efficiency
plans_and_trajs = generate_efficiency_trajs(problem, 7)
test_plan = @julog Term[right, up, up, left, left, up, up,
                        left, left, down, pickup(cylinder1)]
test_traj = PDDL.simulate(domain, state, strange_plan)
push!(plans_and_trajs, (test_plan, test_traj))
n_samples = 50
anim = hierarchical_goal_inference(plans_and_trajs, n_samples)

# Detect violation of expectations for object preference
true_goals = [fill(pddl"(retrieve cylinder1)", 7); pddl"(retrieve block1)"]
plans_and_trajs = generate_preference_trajs(problem, 8, true_goals)
n_samples = 50
anim = hierarchical_goal_inference(plans_and_trajs, n_samples)
