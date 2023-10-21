@testset "Observations" begin

# Load domains and problems
path = joinpath(@__DIR__, "..", "examples", "gridworld")
gridworld = load_domain(joinpath(path, "domain.pddl"))
gw_problem = load_problem(joinpath(path, "problems", "problem-1.pddl"))
gw_state = initstate(gridworld, gw_problem)

path = joinpath(@__DIR__, "..", "examples", "doors-keys-gems")
doors_keys_gems = load_domain(joinpath(path, "domain.pddl"))
dkg_problem = load_problem(joinpath(path, "problems", "problem-1.pddl"))
dkg_state = initstate(doors_keys_gems, dkg_problem)

path = joinpath(@__DIR__, "..", "examples", "block-words")
blocksworld = load_domain(joinpath(path, "domain.pddl"))
bw_problem = load_problem(joinpath(path, "problems", "problem-0.pddl"))
bw_state = initstate(blocksworld, bw_problem)

@testset "Observed Facts" begin

# Test lifted observation model
bw_params = ObsNoiseParams(
    (pddl"(forall (?x - block ?y - block) (on ?x ?y))", 0.05),
    (pddl"(forall (?x - block) (clear ?x))", 0.05),
    (pddl"(forall (?x - block) (ontable ?x))", 0.05),
    (pddl"(handempty)", 0.05)
)
bw_terms = collect(keys(bw_params))

obs_choices = state_choicemap(bw_state, bw_terms; domain=blocksworld)
@test obs_choices[pddl"(handempty)"] == true
@test obs_choices[pddl"(ontable a)"] == true
@test obs_choices[pddl"(clear b)"] == true
@test obs_choices[pddl"(on c a)"] == false
@test obs_choices[pddl"(on a b)"] == false

# Test grounded observation model
bw_params = ground_obs_params(bw_params, blocksworld, bw_state)
bw_terms = collect(keys(bw_params))

obs_choices = state_choicemap(bw_state, bw_terms)
@test obs_choices[pddl"(handempty)"] == true
@test obs_choices[pddl"(ontable a)"] == true
@test obs_choices[pddl"(clear b)"] == true
@test obs_choices[pddl"(on c a)"] == false
@test obs_choices[pddl"(on a b)"] == false

# Test automatically generated observation model
bw_params = ObsNoiseParams(blocksworld, bw_state, pred_noise=0.05)
bw_terms = collect(keys(bw_params))

obs_choices = state_choicemap(bw_state, bw_terms)
@test obs_choices[pddl"(handempty)"] == true
@test obs_choices[pddl"(ontable a)"] == true
@test obs_choices[pddl"(clear b)"] == true
@test obs_choices[pddl"(on c a)"] == false
@test obs_choices[pddl"(on a b)"] == false

# Test constrained observations
obs_choices[pddl"(handempty)"] = false
trace, weight =
    generate(observe_state, (blocksworld, bw_state, bw_params), obs_choices)
obs_state = get_retval(trace)
expected_weight = log(0.05) + (length(bw_terms) - 1) * log(1 - 0.05)

@test trace[pddl"(handempty)"] == false
@test obs_state[pddl"(handempty)"] == false
@test isapprox(weight, expected_weight)

end

@testset "Observed Fluents" begin

# Test fluent observation model
gw_params = ObsNoiseParams(
    (pddl"(xpos)", normal, 0.25), (pddl"(ypos)", normal, 0.25)
)
gw_terms = collect(keys(gw_params))

obs_choices = state_choicemap(gw_state, gw_terms)
@test obs_choices[pddl"(xpos)"] == 1
@test obs_choices[pddl"(ypos)"] == 1

# Test constrained observations
obs_choices[pddl"(ypos)"] = 2
trace, weight =
    generate(observe_state, (gridworld, gw_state, gw_params), obs_choices)
obs_state = get_retval(trace)
expected_weight = logpdf(normal, 1, 1, 0.25) + logpdf(normal, 2, 3, 0.25)

@test trace[pddl"(ypos)"] == 2
@test obs_state[pddl"(ypos)"] == 2
@test isapprox(weight, expected_weight)

end

end
