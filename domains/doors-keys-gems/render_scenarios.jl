using Julog, PDDL, Gen, Printf, JSON
using Plinf
include("render.jl")
include("utils.jl")
include("problem_actions.jl")

# Specify problem name
problem_name =  "problem-2.pddl"

actions = get_action("2-sub-1")

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "doors-keys-gems")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, problem_name))

save_image_path = path

# Initialize problem and visualize initial state
state = initialize(problem)
goal = problem.goal
plt = render(state)


# Execute list of actions and generate intermediate states
function execute_plan(state, domain, actions)
    states = State[]
    # temp_states = State[]
    #
    # push!(states, state)
    # push!(temp_states, state)
    #
    # png_timestep = 0
    # gif_timestep = 0
    # json_dict[string(png_timestep)] = state
    # png(render(state), joinpath(save_image_path, string(png_timestep)))

    for action in actions
        print(action)
        action = parse_pddl(action)
        state = execute(action, state, domain)

        # png_timestep += 1
        # json_dict[string(png_timestep)] = state
        # png(render(state), joinpath(save_image_path, string(png_timestep)))

        push!(states, state)
        # push!(temp_states, state)

        # if png_timestep % 2 == 0
        #     gif(anim_traj(temp_states), joinpath(save_image_path, string(gif_timestep) * ".gif"), fps=20, loop=-1)
        #     gif_timestep += 1
        #     temp_states = State[]
        #     push!(temp_states, state)
        # end
    end
    return states
end


traj_s = execute_plan(state, domain, actions)
anim = anim_traj(traj_s)

gif(anim, joinpath(save_image_path, "3.gif"), fps=10)
