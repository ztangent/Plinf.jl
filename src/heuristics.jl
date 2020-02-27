"Heuristic that counts the number of goals unsatisfied in the domain."
function goal_count(goals, state, domain)
    count = 0
    for g in goals
        sat, _ = satisfy(g, state, domain)
        count += sat ? 0 : 1
    end
    return count
end

"Manhattan distance heuristic."
function manhattan(goals, state, domain; fluents=@julog([xpos, ypos]))
    goal = PDDL.clauses_to_state(Vector{Clause}(goals))
    goal_vals = [evaluate(f, goal, domain) for f in fluents]
    curr_vals = [evaluate(f, state, domain) for f in fluents]
    dist = sum(abs(g.name - c.name) for (g, c) in zip(goal_vals, curr_vals))
    return dist
end
