# This file generates new experimental stimuli for the Doors-Keys-Gems domain
# Segmented GIFs are generated from plans specified in PDDL syntax

using Julog, PDDL, Plinf
import JSON

DOM_PATH = joinpath(dirname(pathof(Plinf)), "..", "domains", "doors-keys-gems")
include(joinpath(DOM_PATH, "render.jl"))

GEM_COLORS = Dict(zip(
    @julog([gem1, gem2, gem3]),
    [colorant"#D41159", colorant"#FFC20A", colorant"#1A85FF"]
))

prob_goal_trial= Dict("6_1_0" => ("1","1"), "7_0_0" => ("1","2"), "4_0_0" => ("1","3"), "12_2_0" => ("1","4"),
                    "9_2_0" => ("2","1"), "5_0_0" => ("2","2"), "10_2_0" => ("2","3"), "11_0_0" => ("2","4"),
                    "6_0_0" => ("3","1"), "4_1_0" => ("3","2"), "11_1_0" => ("3","3"), "5_2_0" => ("3","4"),
                    "7_1_0" => ("4","1"), "5_2_1" => ("4","2"), "10_0_0" => ("4","3"), "12_2_1" => ("4","4"))


function get_ids_from_fn(fn)
    m = match(r".*problem_(\d+)_goal(\d+)_(\d+).*", fn)
    return Tuple(parse.(Int, m.captures))
end

function get_opt_from_fn(fn)
    m = match(r".*problem_(\d+)_goal(\d+)_(\d+).dat", fn)
    return m.captures[1] == "opt"
end

"Load plans and trajectories"
function load_plans(plan_dir)
    plan_fns = sort!(readdir(plan_dir); by=get_ids_from_fn)
    plan_ids, opts = get_ids_from_fn.(plan_fns), get_opt_from_fn.(plan_fns)
    domain = load_domain(joinpath(DOM_PATH, "domain.pddl"))
    problems = [load_problem(joinpath(DOM_PATH, "problems", "problem-$p.pddl"))
                for (p, _, _) in plan_ids]
    inits = initialize.(problems)
    plans = [parse_pddl.(readlines(joinpath(plan_dir, fn))) for fn in plan_fns]
    trajs = [PDDL.simulate(domain, s, p) for (s, p) in zip(inits, plans)]
    metadata = [Dict{Symbol,Any}(:problem => p, :goal => g, :trial => t, :optimal => o)
                for ((p, g, t), o) in zip(plan_ids, opts)]
    return plans, trajs, metadata, inits
end

"Generate GIF stimuli and JSON descriptors from folder of plans."
function generate_stimuli(plan_dir; seg_len=3)
    stim_path = "./domains/doors-keys-gems/stimuli"
    mkpath(stim_path)
    plans, trajs, metadata, inits = load_plans(plan_dir)
    for (i, (plan, traj, m, init)) in enumerate(zip(plans, trajs, metadata, inits))
        p, g, t = (m[:problem]), (m[:goal]), (m[:trial])
        scenario, number = prob_goal_trial[string(p)*"_"*string(g)*"_"*string(t)]
        # stim_name = "problem_$(m[:problem])_goal_$(m[:goal])_$(m[:trial])"
        stim_name = "scenario_$(scenario)_$(number)"
        start_pos = (traj[1][:xpos], traj[1][:ypos])
        png(render(init, start=start_pos, gem_colors=GEM_COLORS,
                show_pos=true, show_inventory=true), stim_path * "/$(stim_name).png")
        for i in 4:6
            if length(traj) % i > 2
                seg_len = i
            end
            if length(traj) % i == 0
                seg_len= i
            end
        end
        splitpoints = collect(1:seg_len:length(traj))
        if splitpoints[end] != length(traj) push!(splitpoints, length(traj)) end
        x = [traj[i:min(i + seg_len - 1, end)] for i in 1:seg_len:length(traj)]
        for (num, t) in enumerate(x)
            anim = anim_traj(t; gem_colors=GEM_COLORS, splitpoints=splitpoints,
                               start_pos=start_pos, plan=plan, show=false)
            gif(anim, stim_path * "/$(stim_name)_$(num-1).gif"; fps=3, loop=-1)
        end
        whole_anim = anim_traj(traj; gem_colors=GEM_COLORS, splitpoints=splitpoints,
                           start_pos=start_pos, plan=plan, show=true)
        gif(whole_anim, stim_path * "/$(stim_name).gif"; fps=3, loop=-1)
        m[:name] = stim_name
        m[:length] = length(splitpoints)
        m[:times] = splitpoints
        m[:images] = ["stimuli/$(scenario)/$(number)/$(j-1).gif" for j=1:m[:length]]
    end
    open(stim_path * "stimuli.json","w") do f
        JSON.print(f, metadata, 2)
    end
    return JSON.json(metadata, 2)
end
