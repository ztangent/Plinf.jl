using InverseTAMP
using PDDL

path = joinpath(dirname(pathof(InverseTAMP)), "..", "domains", "tabletop")

domain = load_domain(joinpath(path, "domain.pddl"))
@test domain.name = Symbol("blocks")
@test domain.predicates[:handempty] == @julog(handempty())
@test @julog(handempty() <<= forall(X, not(holding(X))) in domain.axioms

problem = load_problem(joinpath(path, "problem.pddl"))
@test problem.name == Symbol("blocks-1")
@test problem.objects == @julog [table, block1]

state = initialize(problem)
state = execute(@julog(pickup(block1)), state, domain)
@test satisfy(@julog(holding(block1)), state, domain)[1] == true
@test satisfy(problem.goal, state, domain)[1] == true
