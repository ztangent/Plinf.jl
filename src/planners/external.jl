export FastDownwardPlanner

"FastDownward planner."
@kwdef struct FastDownwardPlanner <: Planner
    timeout::Int = 10
    max_nodes::Real = Inf
    domain_path::String
    problem_path::String
    heuristic::String = "add"
    heuristic_params::Dict{String, String} = Dict()
end

set_max_resource(planner::FastDownwardPlanner, val) =
    @set planner.max_nodes = val

get_call(::FastDownwardPlanner)::GenerativeFunction = fast_downward_call

"Calls the FastDownward planning system to produce a plan."
@gen function fast_downward_call(planner::FastDownwardPlanner, domain::Domain,
                                 state::State, goal_spec::GoalSpec)
    @unpack timeout, max_nodes, heuristic, heuristic_params = planner
    @unpack domain_path, problem_path = planner

    py"""
    import sys, os, subprocess
    def fd_wrapper(heuristic_with_params, timeout, domain_path, problem_path):
        if 'FD_PATH' not in os.environ:
            raise Exception((
                "Environment variable `FD_PATH` not found. Make sure "
                "FastDownward is installed and FD_PATH is set to the "
                "path of fast-downward.py."
            ))
        FD_PATH = os.environ['FD_PATH']
        timeout_cmd = "gtimeout" if sys.platform == "darwin" else "timeout"
        cmd_str = "{} {} {} {} {} --search 'astar({})'".\
            format(timeout_cmd, timeout, FD_PATH, domain_path,
                   problem_path, heuristic_with_params)
        output = subprocess.getoutput(cmd_str)
        if "Solution found" not in output:
            return None
        plan = []
        with open("sas_plan") as f:
            plan = f.readlines()[:-1]
        os.remove("sas_plan")
        return plan
    """

    params = join(["$key=$val" for (key, val) in heuristic_params], ", ")
    heuristic_with_params = "$heuristic($params)"
    plan = py"fd_wrapper"(heuristic_with_params, timeout,
                          domain_path, problem_path)

    if (plan == nothing) return nothing, nothing end
    plan = [(parse_pddl(act[1:end-1])) for act in plan]
    traj = PDDL.simulate(domain, state, plan)
    return plan, traj
end
