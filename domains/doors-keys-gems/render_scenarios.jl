using Julog, PDDL, Gen, Printf, JSON
using Plinf

include("render.jl")
include("generate.jl")
include("utils.jl")

# Specify problem number
problem_idx = "12"
problem_name = "problem-" * problem_idx * ".pddl"

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "doors-keys-gems")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problems", problem_name))
goals = parse_pddl.(readlines(joinpath(path, "goals", "goals_$(problem_idx).pddl")))

goal_colors = [colorant"#D41159", colorant"#FFC20A", colorant"#1A85FF"]
gem_terms = @julog [gem1, gem2, gem3]
gem_colors = Dict(zip(gem_terms, goal_colors))

init_state = initialize(problem)
start_pos = (init_state[:xpos], init_state[:ypos])
#plt = render(init_state; start=start_pos, gem_colors=gem_colors, show_objs=true)

gifs_path = mkpath(joinpath(path, "gifs"))
pics_path = mkpath(joinpath(path, "timesteps"))

"Load all observed trajectories for a given problem (i.e. initial state)."
function load_observations(obs_path::String, problem_idx::Int,
                           domain::Domain, init_state::State)
    "Extract goal and trajectory indices."
    function get_idx_from_fn(fn)
        m = match(r".*problem(\d+)_goal(\d+)_(\d+).*", fn)
        if m == nothing
            return parse(Int, match(r".*_goal(\d+).*", fn).captures[1])
        else
            return Tuple(parse.(Int, m.captures))
        end
    end

    # Load and sort plans
    filt_by_prob = fn -> occursin("problem_$(problem_idx)_", fn)
    plan_fns = filter!(filt_by_prob, readdir(obs_path))
    plan_fns = sort!(plan_fns; by=get_idx_from_fn)

    # Parse plans, produce trajectories from initial state + plans
    obs_plans = [parse_pddl.(readlines(joinpath(obs_path, fn)))
                 for fn in plan_fns]
    obs_trajs = [PDDL.simulate(domain, init_state, p) for p in obs_plans]
    return obs_plans, obs_trajs, plan_fns
end

obs_path = joinpath(path, "plans")
_, obs_trajs, obs_fns = load_observations(obs_path, parse(Int64, problem_idx),
                                              domain, init_state)


for (idx, (traj, fn)) in enumerate(zip(obs_trajs, obs_fns))
    # Get goal index from file name
    goal_idx = parse(Int, match(r".*_goal(\d+).*", fn).captures[1])
    goal = goals[goal_idx+1]
    idx = idx - 1 # Reindex trajectories to start at zero

    png_timestep = 0
    gif_timestep = 0
    temp_states = State[]
    png(render(init_state, start=start_pos, gem_colors=gem_colors, show_pos=true),
            joinpath(pics_path, problem_idx, string(idx), string(png_timestep)))

    traj_len = size(traj)[1]
    step = 6
    for i in 4:7
        if traj_len % i > 2
            step = i
        end
        if traj_len % i == 0
            step = i
        end
    end
    print("Length:", traj_len)
    print("Timestep:", step)
    print()
    for t in traj
        start_pos = (t[:xpos], t[:ypos])
        png_timestep += 1
        push!(temp_states, t)
        if png_timestep % step == 0
            gif(anim_traj(temp_states, gem_colors=gem_colors),
                joinpath(pics_path, problem_idx, string(idx), string(gif_timestep) * ".gif"), fps=3, loop=-1)
            gif_timestep += 1
            temp_states = State[]
            push!(temp_states, t)
        end
    end
    if size(temp_states)[1] > 1
        gif(anim_traj(temp_states, gem_colors=gem_colors),
            joinpath(pics_path, problem_idx, string(idx), string(gif_timestep) * ".gif"), fps=3, loop=-1)
    end

    anim = anim_traj(traj, gem_colors=gem_colors)
    file_name =  problem_idx * "_" * string(goal)[end-1] * "_" * string(idx) * ".gif"
    gif(anim, joinpath(gifs_path, file_name), fps=5)

end
