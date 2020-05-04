using Test
using InverseTAMP
using Julog
using PDDL
include(joinpath(dirname(pathof(InverseTAMP)), "scene-graph-utils.jl"))

function test1()
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

    save_path = joinpath(dirname(pathof(InverseTAMP)), "..", "examples", "blocksworld")
    scene_graph_before = pddl_to_scene_graph(state)
    visualize(scene_graph_before, save_path, "before")

    state = execute(@julog(pickup(table, block1)), state, domain)
    @test satisfy(@julog(holding(block1)), state, domain)[1] == true
    @test satisfy(problem.goal, state, domain)[1] == true

    scene_graph_after = pddl_to_scene_graph(state)
    visualize(scene_graph_after, save_path, "after")

    state = execute(@julog(putdown(table, block1, 3, 3)), state, domain)
    scene_graph_putdown = pddl_to_scene_graph(state)
    visualize(scene_graph_putdown, save_path, "putdown")
end

function test2()
    path = joinpath(dirname(pathof(InverseTAMP)), "..", "domains", "tabletop")
    @info "Path is $path"

    domain = load_domain(joinpath(path, "domain.pddl"))
    @test domain.name == Symbol("blocks")
    @test domain.predicates[:holding] == @julog(holding(X))
    @test @julog(handempty <<= forall(and(block(X)), not(holding(X)))) in domain.axioms

    problem = load_problem(joinpath(path, "problem-4.pddl"))
    @test problem.name == Symbol("blocks-4")
    @test problem.objects == @julog [table, block1, block2, block3, red, green, blue]

    state = initialize(problem)
    @test satisfy(@julog(on(table, block1)), state, domain)[1] == true
    @test satisfy(@julog(handempty), state, domain)[1] == true
    @test satisfy(@julog(amounton(block1) == 0), state, domain)[1] == true
    @test available(@julog(pickup(table, block1)), state, domain)[1] == true

    save_path = joinpath(dirname(pathof(InverseTAMP)), "..", "examples", "blocksworld", "block_tower")
    scene_graph_1 = pddl_to_scene_graph(state)
    visualize(scene_graph_1, save_path, "001")

    state = execute(@julog(pickup(table, block2)), state, domain)
    @test satisfy(@julog(holding(block2)), state, domain)[1] == true
    @test satisfy(@julog(fits(block1, block2)), state, domain)[1] == true
    @test available(@julog(putdown(block1, block2)), state, domain)[1] == true

    scene_graph_2 = pddl_to_scene_graph(state)
    visualize(scene_graph_2, save_path, "002")

    state = execute(@julog(putdown(block1, block2)), state, domain)
    @test satisfy(@julog(holding(block2)), state, domain)[1] == false

    scene_graph_3 = pddl_to_scene_graph(state)
    visualize(scene_graph_3, save_path, "003")

    state = execute(@julog(pickup(table, block3)), state, domain)
    @test satisfy(@julog(holding(block3)), state, domain)[1] == true

    scene_graph_4 = pddl_to_scene_graph(state)
    visualize(scene_graph_4, save_path, "004")

    state = execute(@julog(putdown(block2, block3)), state, domain)
    @test satisfy(@julog(holding(block3)), state, domain)[1] == false

    scene_graph_5 = pddl_to_scene_graph(state)
    visualize(scene_graph_5, save_path, "005")

    @test satisfy(problem.goal, state, domain)[1] == true
end
