# Test that planners correctly solve simple problems

@testset "Planners" begin

# Load domains and problems
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "gridworld")
gridworld = load_domain(joinpath(path, "domain.pddl"))
gw_problem = load_problem(joinpath(path, "problem-1.pddl"))
gw_state = initstate(gridworld, gw_problem)

path = joinpath(dirname(pathof(Plinf)), "..", "domains", "doors-keys-gems")
doors_keys_gems = load_domain(joinpath(path, "domain.pddl"))
dkg_problem = load_problem(joinpath(path, "problem-1.pddl"))
dkg_state = initstate(doors_keys_gems, dkg_problem)

path = joinpath(dirname(pathof(Plinf)), "..", "domains", "block-words")
blocksworld = load_domain(joinpath(path, "domain.pddl"))
bw_problem = load_problem(joinpath(path, "problem-0.pddl"))
bw_state = initstate(blocksworld, bw_problem)

@testset "BFS Planner" begin

planner = BFSPlanner()
plan, traj = planner(gridworld, gw_state, gw_problem.goal)
@test satisfy(gridworld, traj[end], gw_problem.goal) == true
@test plan == @pddl("down", "down", "right", "right", "up", "up")

# plan, traj = planner(doors_keys_gems, dkg_state, dkg_problem.goal)
# @test satisfy(doors_keys_gems, traj[end], dkg_problem.goal) == true
# @test plan == @pddl("(down)", "(pickup key1)", "(down)", "(unlock key1 right)",
#                     "(right)", "(right)", "(up)", "(up)", "(pickup gem1)")

plan, traj = planner(blocksworld, bw_state, bw_problem.goal)
@test satisfy(blocksworld, traj[end], bw_problem.goal) == true
@test plan == @pddl("(pick-up a)", "(stack a b)", "(pick-up c)", "(stack c a)")

end

@testset "A* Planner" begin

clear_heuristic_cache!()

planner = AStarPlanner(heuristic=ManhattanHeuristic(@julog[xpos, ypos]))
plan, traj = planner(gridworld, gw_state, gw_problem.goal)
@test satisfy(gridworld, traj[end], gw_problem.goal) == true
@test plan == @pddl("down", "down", "right", "right", "up", "up")

# planner = AStarPlanner(heuristic=GoalCountHeuristic())
# plan, traj = planner(doors_keys_gems, dkg_state, dkg_problem.goal)
# @test satisfy(doors_keys_gems, traj[end], dkg_problem.goal) == true
# @test plan == @pddl("(down)", "(pickup key1)", "(down)", "(unlock key1 right)",
#                     "(right)", "(right)", "(up)", "(up)", "(pickup gem1)")

planner = AStarPlanner(heuristic=HAdd())
plan, traj = planner(blocksworld, bw_state, bw_problem.goal)
@test satisfy(blocksworld, traj[end], bw_problem.goal) == true
@test plan == [pddl"(pick-up a)", pddl"(stack a b)",
               pddl"(pick-up c)", pddl"(stack c a)"]

end

@testset "Prob. A* Planner" begin

clear_heuristic_cache!()

planner = ProbAStarPlanner(heuristic=ManhattanHeuristic(@julog[xpos, ypos]))
plan, traj = planner(gridworld, gw_state, gw_problem.goal)
@test satisfy(gridworld, traj[end], gw_problem.goal) == true
@test plan == @pddl("down", "down", "right", "right", "up", "up")

# planner = ProbAStarPlanner(heuristic=GoalCountHeuristic())
# plan, traj = planner(doors_keys_gems, dkg_state, dkg_problem.goal)
# @test satisfy(doors_keys_gems, traj[end], dkg_problem.goal) == true
# @test plan == @pddl("(down)", "(pickup key1)", "(down)", "(unlock key1 right)",
#                     "(right)", "(right)", "(up)", "(up)", "(pickup gem1)")

planner = ProbAStarPlanner(heuristic=HAdd())
plan, traj = planner(blocksworld, bw_state, bw_problem.goal)
@test satisfy(blocksworld, traj[end], bw_problem.goal) == true
@test plan == [pddl"(pick-up a)", pddl"(stack a b)",
               pddl"(pick-up c)", pddl"(stack c a)"]

end

@testset "Backward Search Planner" begin

clear_heuristic_cache!()

planner = BackwardPlanner(heuristic=HAddR())
plan, traj = planner(blocksworld, bw_state, bw_problem.goal)
@test issubset(traj[1], bw_state) == true
@test plan == [pddl"(pick-up a)", pddl"(stack a b)",
               pddl"(pick-up c)", pddl"(stack c a)"]

end

end
