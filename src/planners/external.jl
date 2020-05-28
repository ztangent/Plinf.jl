export FastDownwardPlanner

"Wrapper to the FastDownward planning system."
@kwdef struct FastDownwardPlanner <: Planner
    domain_path::String
    problem_path::String
    heuristic::String = "add"
    h_params::Dict{String, String} = Dict()
    timeout::Float64 = 10
    verbose::Bool = false
end

set_max_resource(planner::FastDownwardPlanner, val) =
    @set planner.timeout = val

get_call(::FastDownwardPlanner)::GenerativeFunction = fast_downward_call

"Calls the FastDownward planning system to produce a plan."
@gen function fast_downward_call(planner::FastDownwardPlanner, domain::Domain,
                                 state::State, goal_spec::GoalSpec)
    if !haskey(ENV, "FD_PATH")
        error("FD_PATH not set to location of fast_downward.py") end
    @unpack domain_path, problem_path = planner
    @unpack heuristic, h_params, timeout, verbose = planner
    # Set up shell command to fast_downward.py
    fd_path = ENV["FD_PATH"]
    py_cmd = get(ENV, "PYTHON", "python")
    h_params = join(["$key=$val" for (key, val) in h_params], ", ")
    search_params = "astar($heuristic($h_params))"
    cmd = `$py_cmd $fd_path $domain_path $problem_path --search $search_params`
    # Run command up to timeout
    out = Pipe()
    proc = run(pipeline(cmd, stdout=out); wait=false)
    cb() = process_exited(proc)
    timedwait(cb, float(timeout))
    if process_running(proc)
        kill(proc); close(out.in); return nothing, nothing end
    # Read output and check if solution was found
    close(out.in)
    output = read(out, String)
    if verbose println(output) end
    if !occursin("Solution found", output)
        return nothing, nothing end
    # Read plan from file
    plan = readlines("./sas_plan")[1:end-1]
    Base.Filesystem.rm("./sas_plan")
    plan = parse_pddl.(plan)
    traj = PDDL.simulate(domain, state, plan)
    return plan, traj
end
