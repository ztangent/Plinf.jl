export FastDownwardPlanner

"FastDownward planner."
@kwdef struct FastDownwardPlanner <: Planner
    timeout::Int = 10
    max_nodes::Real = Inf
    domain_path::String
    problem_path::String
    heuristic::String
    heuristic_params::Dict{String, String} = Dict()
end

set_max_resource(planner::FastDownwardPlanner, val) = @set planner.max_nodes = val

get_call(::FastDownwardPlanner)::GenerativeFunction = fastdownward_call

"FastDownward search for a plan. Currently assumes A* search"
@gen function fastdownward_call(planner::FastDownwardPlanner,
                                domain::Domain, state::State, goal_spec::GoalSpec)
    @unpack timeout, max_nodes, domain_path, problem_path, heuristic, heuristic_params = planner
    params = join(["$key=$val" for (key, val) in heuristic_params], ", ")
    heuristic_with_params = "$heuristic($params)"

    py"""
    import sys
    import os
    import re
    import subprocess

    def fastdownward_wrapper(heuristic_with_params, timeout, domain_path, problem_path):
        if 'FD_PATH' not in os.environ:
            raise Exception((
                "Environment variable `FD_PATH` not found. Make sure fd is installed "
                "and FF_PATH is set to the path of fast-downward.py"
            ))
        FD_PATH = os.environ['FD_PATH']
        timeout_cmd = "gtimeout" if sys.platform == "darwin" else "timeout"
        cmd_str = "{} {} {} {} {} --search 'astar({})'".format(timeout_cmd, timeout,
                                                                FD_PATH, domain_path,
                                                                problem_path, heuristic_with_params)
        output = subprocess.getoutput(cmd_str)
        if "Solution found" not in output:
            return None
        steps = []
        with open("sas_plan") as f:
            steps = f.readlines()[:-1]
        os.remove("sas_plan")
        return steps
    """

    plan = py"fastdownward_wrapper"(heuristic_with_params, timeout, domain_path, problem_path)
    if plan == nothing
        return nothing, nothing
    end
    plan = [(parse_pddl(step[1:(length(step) - 1)])) for step in plan]
    println(plan)
    traj = [state]
    for step in plan
        push!(traj, transition(domain, traj[length(traj)], step))
    end
    return plan, traj
end
