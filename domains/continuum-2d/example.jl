using Julog, PDDL, Gen, Printf
using Plinf

# include("render.jl")

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "continuum-2d")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem-1.pddl"))

# Define helper function to convert x-y tuples to Julog term
pos_to_terms(pos) = @julog([xpos == $(pos[1]), ypos == $(pos[2])])

# Initialize state, set goal position
state = initstate(domain, problem)
start_pos = (state[:xpos], state[:ypos])
goal = [problem.goal]

# Check that we can only move into free space and not walls
# TODO : Check for line collisions, not just point collisions
@assert available(domain, state, @julog(move(3.5, 5))) == false
@assert available(domain, state, @julog(move(5, 2))) == true

# Manually execute a motion plan
state = execute(domain, state, @julog(move(5, 2)))
state = execute(domain, state, @julog(move(5, 8)))
state = execute(domain, state, @julog(move(8, 8)))

# Check that goal is reached (i.e. agent is in goal area)
@assert satisfy(domain, state, problem.goal) == true
