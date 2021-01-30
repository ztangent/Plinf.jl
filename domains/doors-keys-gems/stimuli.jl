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

# prob_goal_trial= Dict("6_1_0" => ("1","1"), "7_0_0" => ("1","2"), "4_0_0" => ("1","3"), "12_2_0" => ("1","4"),
#                     "9_2_0" => ("2","1"), "5_0_0" => ("2","2"), "10_2_0" => ("2","3"), "11_1_1" => ("2","4"),
#                     "6_0_0" => ("3","1"), "4_1_0" => ("3","2"), "11_1_0" => ("3","3"), "5_2_1" => ("3","4"),
#                     "7_1_0" => ("4","1"), "5_2_0" => ("4","2"), "10_0_0" => ("4","3"), "12_2_1" => ("4","4"),
#                     "8_1_0" => ("2", "4"), "8_2_0" => ("3", "4"))

splitpoints_dict = Dict("1_1" => [7,14,20], "1_2" => [9,14,17], "1_3" => [9,17,24], "1_4" => [7,14,23,32],
                        "2_1" => [6,11,21], "2_2" => [6,11], "2_3" => [5,8,13], "2_4" => [9,12,31,44],
                        "3_1" => [7,22,37], "3_2" => [14,24,29], "3_3" => [7,13,20], "3_4" => [6,11,47],
                        "4_1" => [8,14,18], "4_2" => [4,8], "4_3" => [5,8], "4_4" => [7,12,18])

function get_ids_from_fn(fn)
    m = match(r".*(\d+)_(\d+)_problem_(\d+)_goal(\d+)_(\d+).*", fn)
    return Tuple(parse.(Int, m.captures))
end

function get_opt_from_fn(fn)
    m = match(r".*(\d+)_(\d+)_problem_(\d+)_goal(\d+)_(\d+).dat", fn)
    return m.captures[3] == "opt"
end

"Load plans and trajectories"
function load_plans(plan_dir)
    plan_fns = sort!(readdir(plan_dir); by=get_ids_from_fn)
    plan_ids, opts = get_ids_from_fn.(plan_fns), get_opt_from_fn.(plan_fns)
    domain = load_domain(joinpath(DOM_PATH, "domain.pddl"))
    problems = [load_problem(joinpath(DOM_PATH, "problems", "problem-$p.pddl"))
                for (_, _, p, _, _) in plan_ids]
    inits = initialize.(problems)
    plans = [parse_pddl.(readlines(joinpath(plan_dir, fn))) for fn in plan_fns]
    trajs = [PDDL.simulate(domain, s, p) for (s, p) in zip(inits, plans)]
    metadata = [Dict{Symbol,Any}(:scenario => s, :number => n, :problem => p, :goal => g, :trial => t, :optimal => o)
                for ((s, n, p, g, t), o) in zip(plan_ids, opts)]
    return plans, trajs, metadata
end

"Generate GIF stimuli and JSON descriptors from folder of plans."
function generate_stimuli(plan_dir; seg_len=3)
    stim_path = "./domains/doors-keys-gems/stimuli"
    mkpath(stim_path)
    plans, trajs, metadata = load_plans(plan_dir)
    for (i, (plan, traj, m)) in enumerate(zip(plans, trajs, metadata))
        p, g, t = (m[:problem]), (m[:goal]), (m[:trial])
        scenario, number = (m[:scenario]), (m[:number])
        # stim_name = "problem_$(m[:problem])_goal_$(m[:goal])_$(m[:trial])"
        stim_name = "scenario_$(scenario)_$(number)"
        start_pos = (traj[1][:xpos], traj[1][:ypos])

        # for i in 4:7
        #     if length(traj) % i > 3
        #         seg_len = i
        #     end
        #     if length(traj) % i == 0
        #         seg_len= i
        #     end
        # end
        # splitpoints = collect(1:seg_len:length(traj))
        splitpoints = splitpoints_dict[string(scenario) * "_" * string(number)]
        pushfirst!(splitpoints, 1)
        print(splitpoints)
        # if splitpoints[end] != length(traj) push!(splitpoints, length(traj)) end

        # anims = anim_traj(traj; gem_colors=GEM_COLORS, splitpoints=splitpoints,
        #                           start_pos=start_pos, plan=plan, show=false)
        # for (j, a) in enumerate(anims)
        #     gif(a, stim_path * "/$(stim_name)_$(j-1).gif"; fps=3, loop=-1)
        # end
        #
        # anim = anim_traj(traj; gem_colors=GEM_COLORS, start_pos=start_pos,
        #                     plan=plan, show=false)
        # gif(anim, stim_path * "/$(stim_name).gif"; fps=3, loop=-1)

        # traj_split = [traj[i:min(i + seg_len - 1, end)] for i in 1:seg_len:length(traj)]
        # plan_split = [plan[i:min(i + seg_len - 1, end)] for i in 1:seg_len:length(plan)]
        # # print("The plan is:", plan)
        # for (num, tt) in enumerate(traj_split)
        #     pppp = plan_split[num]
        #     start = (tt[1][:xpos], tt[1][:ypos])
        #     anim = anim_traj(tt; gem_colors=GEM_COLORS, splitpoints=splitpoints,
        #                        start=start, plan=pppp , show=false)
        #     gif(anim, stim_path * "/$(stim_name)_$(num-1).gif"; fps=3, loop=-1)
        # end
        # whole_anim = anim_traj(traj; gem_colors=GEM_COLORS, splitpoints=splitpoints,
        #                    start=start_pos, plan=plan, show=true)
        # gif(whole_anim, stim_path * "/$(stim_name).gif"; fps=3, loop=-1)

        m[:name] = stim_name
        m[:length] = length(splitpoints)
        # if scenario == 4
        #     m[:length] = length(splitpoints)
        # else
        #     m[:length] = length(splitpoints)-1
        # end
        m[:times] = splitpoints
        m[:images] = ["stimuli/" * stim_name * "_$(j-1).gif" for j=1:m[:length]+1]
    end
    open(stim_path * "/stimuli.json","w") do f
        JSON.print(f, metadata, 2)
    end
    return JSON.json(metadata, 2)
end
