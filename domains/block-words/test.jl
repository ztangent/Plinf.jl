using PDDL
using Plinf

# Load domain and problem
path = joinpath(dirname(pathof(Plinf)), "..", "domains", "block-words")
domain = load_domain(joinpath(path, "domain.pddl"))
problem = load_problem(joinpath(path, "problem-1.pddl"))

# Initialize state
state = initialize(problem)

input = block_words_RNN_conversion(domain, state)
expected = [0, 0, 1, 1, 1, 0, 1, 1, #clear
            1, # handempty
            0, 0, 0, 0, 0, 0, 0, 0, # holding
            1, 0, 0, 0, 0, 0, 0, # a on
            0, 0, 0, 0, 0, 0, 0, # c on
            1, 0, 0, 0, 0, 0, 0, # d on
            0, 0, 0, 0, 0, 0, 0, # e on
            0, 0, 0, 0, 0, 0, 0, # o on
            0, 0, 0, 0, 0, 0, 0, # p on
            0, 0, 0, 0, 0, 1, 0, # r on
            0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 1, 1, 1, 0, 1] # ontable

differ = isequal.(input, expected)
