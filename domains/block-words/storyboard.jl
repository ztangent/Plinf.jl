using Julog, PDDL, Gen, Printf
using Plinf, CSV

include("render.jl")
include("utils.jl")

#--- Initial Setup ---#

# Specify problem name
category = "4"
subcategory = "3"
experiment = "scenario-" * category * "-" * subcategory
problem_name = experiment * ".pddl"

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "doors-keys-gems")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "new-scenarios", problem_name))
file_name = category * "_" * subcategory * ".dat"
actions = parse_pddl.(readlines(joinpath(path, "new-scenarios", "actions" ,file_name)))
goals = @julog  [has(gem1), has(gem2), has(gem3)]

goal_colors = [colorant"#D41159", colorant"#FFC20A", colorant"#1A85FF"]
gem_terms = @julog [gem1, gem2, gem3]
gem_colors = Dict(zip(gem_terms, goal_colors))

# Initialize state
state = initialize(problem)
start_pos = (state[:xpos], state[:ypos])
goal = [problem.goal]

traj = PDDL.simulate(domain, state, actions)
anim = anim_traj(traj; gem_colors=gem_colors, start_pos=start_pos, plan=actions)

times = [1,5,8,10]
frames = [render(traj[t]) for t in times]

#I CANT TELL IF THESE ARE ACTUALLY RIGHT?????????????????
storyboard = plot_storyboard(frames, nothing, times,
                             titles=["Initial state",
                                     "Obtained key",
                                     "Unlock door",
                                     "Stuck"],
                            goal_colors=goal_colors)
png(storyboard, joinpath(path,"new-scenarios","storyboard",experiment*"-frames.png"))
