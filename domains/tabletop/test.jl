using Test
using InverseTAMP
using Julog
using PDDL

function test()
    path = joinpath(dirname(pathof(InverseTAMP)), "..", "domains", "tabletop")
    @info "Path is $path"

    domain = load_domain(joinpath(path, "domain.pddl"))
    @test domain.name == Symbol("blocks")
    @test domain.predicates[:holding] == @julog(holding(X))
    @test @julog(handempty <<= forall(and(block(X)), not(holding(X)))) in domain.axioms

    problem = load_problem(joinpath(path, "problem-1.pddl"))
    @test problem.name == Symbol("blocks-1")
    @test problem.objects == @julog [table, block1]

    state = initialize(problem)
    @test satisfy(@julog(on(table, block1)), state, domain)[1] == true
    @test satisfy(@julog(handempty), state, domain)[1] == true
    @test satisfy(@julog(amounton(block1) == 0), state, domain)[1] == true
    @test available(@julog(pickup(table, block1)), state, domain)[1] == true
    state = execute(@julog(pickup(table, block1)), state, domain)
    @test satisfy(@julog(holding(block1)), state, domain)[1] == true
    @test satisfy(problem.goal, state, domain)[1] == true
end
