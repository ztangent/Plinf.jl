# Code to precompile domains

COMPILED_DOMAINS = Dict{String,Dict{Int,Domain}}()

function load_uncompiled_problem(path::String, domain_name::String, problem_idx::Int)
    # Load problem and domain
    domain_dir = joinpath(path, "domains")
    domain = load_domain(joinpath(domain_dir, "$(domain_name).pddl"))
    problem_dir = joinpath(path, "problems", domain_name)
    problem_fn = filter(fn -> occursin("problem_$(problem_idx).pddl", fn),
                        readdir(problem_dir))[1]
    problem = load_problem(joinpath(problem_dir, problem_fn))
    return domain, problem
end

# Loop and precompile domains
for dname in ["block-words", "doors-keys-gems"]
    c_domains = get!(COMPILED_DOMAINS, dname, Dict{Int,Domain}())
    problem_fns = filter(fn -> occursin(r"problem_(\d+).pddl", fn),
                         readdir(joinpath(EXPERIMENTS_PATH, "problems", dname)))
    problem_idxs = [parse(Int, match(r".*problem_(\d+).pddl", fn).captures[1])
                    for fn in problem_fns]
    heuristic = get(HEURISTICS, dname, HAdd)()
    planner = AStarPlanner(heuristic=heuristic, cache_actions=false)
    for idx in problem_idxs
        domain, problem = load_uncompiled_problem(EXPERIMENTS_PATH, dname, idx)
        domain, state = compiled(domain, problem)
        c_domains[idx] = domain
        planner(domain, state, problem.goal) # Warm up planner
    end
end
