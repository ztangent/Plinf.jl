using Julog, PDDL, Gen, Printf
using Plinf

include("generate.jl")

struct GemHeuristic <: Heuristic end

function Plinf.compute(heuristic::GemHeuristic,
                       domain::Domain, state::State, goal_spec::GoalSpec)
    goals = goal_spec.goals
    goal_objs = [g.args[1] for g in goals if g.name == :has]
    queries = [@julog(at(:obj, L)) for obj in goal_objs]
    _, subst = satisfy(Compound(:or, queries), state, domain, mode=:all)
    locs = [string(s[Var(:L)].name) for s in subst]
    locs = [(parse(Int, l[2]), parse(Int, l[4])) for l in locs]
    _, subst = satisfy(@julog(pos(L)), state, domain)
    pos = string(subst[1][Var(:L)].name)
    pos = (parse(Int, pos[2]), parse(Int, pos[4]))
    dists = [sum(abs.(pos .- l)) for l in locs]
    min_dist = length(dists) > 0 ? minimum(dists) : 0
    return min_dist + GoalCountHeuristic()(domain, state, goal_spec)
end

#--- Initial Setup ---#

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "dkg-no-fluents")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_ascii_problem(joinpath(path, "problem-5.txt"))

# Initialize state, set goal and goal colors
state = initialize(problem)
goal = [problem.goal]
goal_colors = [:red, :gold, :blue]
gem_terms = @julog [gem1, gem2, gem3]
gem_colors = Dict(zip(gem_terms, goal_colors))

#--- Visualize Plans ---#

# Check that A* heuristic search correctly solves the problem
h = GemHeuristic()
h(domain, state, goal)
planner = AStarPlanner(heuristic=GemHeuristic())
plan, traj = planner(domain, state, goal)
println("== Plan ==")
display(plan)
