export goal_count, manhattan

"Heuristic that counts the number of goals unsatisfied in the domain."
function goal_count(goals, state, domain)
    count = sum([state[domain, g] for g in goals])
    return count
end

"Manhattan distance heuristic."
function manhattan(goals, state, domain; fluents=@julog([xpos, ypos]))
    goal = State(goals)
    goal_vals = [goal[domain, f] for f in fluents]
    curr_vals = [state[domain, f] for f in fluents]
    dist = sum(abs.(goal_vals - curr_vals))
    return dist
end
