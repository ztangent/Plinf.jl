using DataStructures: OrderedDict
using Distributions: Normal, cdf

pos_to_terms(pos) = @julog([xpos == $(pos[1]), ypos == $(pos[2])])

"Manhattan distance heuristic to location of goal."
struct GoalManhattan <: Heuristic end

function Plinf.compute(heuristic::GoalManhattan,
                       domain::Domain, state::State, goal_spec::GoalSpec)
    goal = goal_spec.goals[1]
    cur_loc = [state[:xpos], state[:ypos]]
    dist = 0
    # Compute subgoal location based on task
    if goal.name == :reach # Reach a certain location
        goal_loc = [goal.args[1].name, goal.args[2].name]
    elseif goal.name == :retrieve # Retrieve a certain object
        obj = goal.args[1]
        goal_loc = [state[@julog(xitem(:obj))], state[@julog(yitem(:obj))]]
    elseif goal.name == :transfer # Transfer a certain object
        obj = goal.args[1]
        if !state[@julog(has(:obj))]
            goal_loc = [state[@julog(xitem(:obj))], state[@julog(yitem(:obj))]]
            dist += sum(abs.(cur_loc - goal_loc))
            cur_loc = goal_loc
        end
        goal_loc = [goal.args[2].name, goal.args[3].name]
    else # Default to goal count heuristic
        return GoalCountHeuristic()(domain, state, goal_spec)
    end
    dist += sum(abs.(cur_loc - goal_loc))
    return dist
end

function get_goal_probs(traces, weights, goal_idxs=[])
    goal_probs = OrderedDict{Any,Float64}(g => 0.0 for g in goal_idxs)
    for (tr, w) in zip(traces, weights)
        goal_idx = tr[:goal_init => :goal]
        prob = get(goal_probs, goal_idx, 0.0)
        goal_probs[goal_idx] = prob + exp(w)
    end
    return goal_probs
end

function print_goal_probs(goal_probs)
    for (goal, prob) in sort(goal_probs)
        @printf("%.3f\t", prob)
    end
    print("\n")
end

function kl_divergence(probs_1, probs_2)
    return sum(p1 * (log(p1) - log(p2)) for (p1, p2) in zip(probs_1, probs_2))
end

function total_variation(probs_1, probs_2)
    return 0.5 * sum(abs(p1-p2) for (p1, p2) in zip(probs_1, probs_2))
end

function threshold_confidence(val, threshold, std)
    z_score = (val - threshold) / std
    return cdf(Normal(), abs(z_score))
end

"Get predicted locations given a particular trace."
function get_predicted_locs(trace::Trace, t_start=nothing, t_stop=nothing)
    world_traj = get_retval(trace)
    if length(world_traj) == 0 return [] end
    traj = extract_traj([ws.plan_state for ws in world_traj])
    t_start = isnothing(t_start) ? 1 : max(t_start, 1)
    t_stop = isnothing(t_stop) ? length(traj) : min(t_stop, length(traj))
    return [(t, traj[t][:xpos], traj[t][:ypos]) for t in t_start:t_stop]
end

"Get future predicted locations (including present) given a particular trace."
function get_future_locs(trace::Trace, offset::Int=0)
    t, _, _ = Gen.get_args(trace) # Get current time
    return get_predicted_locs(trace, t+offset)
end

"Get past predicted locations (including present) given a particular trace."
function get_past_locs(trace::Trace, offset::Int=0)
    t, _, _ = Gen.get_args(trace) # Get current time
    return get_predicted_locs(trace, 1, t+offset)
end

"Get array of predicted locations."
function get_predicted_grid(trace::Trace, t_start=nothing, t_stop=nothing)
    _, world_init, _ = Gen.get_args(trace)
    state = world_init.env_init
    width, height = state[:width], state[:height]
    grid = zeros(Float64, width, height)
    locs = get_predicted_locs(trace, t_start, t_stop)
    for (_, x, y) in locs grid[x, y] = 1 end
    return grid
end

"Get array of future predicted locations."
function get_future_grid(trace::Trace, offset::Int=0)
    t, _, _ = Gen.get_args(trace) # Get current time
    return get_predicted_grid(trace, t+offset)
end

function get_future_grid(traces, weights, offset::Int=0)
    sum(get_future_grid(tr, offset) .* exp(w) for (tr, w) in zip(traces, weights))
end

"Get array of past predicted locations."
function get_past_grid(trace::Trace, offset::Int=0)
    t, _, _ = Gen.get_args(trace) # Get current time
    return get_predicted_grid(trace, 1, t+offset)
end

function get_past_grid(traces, weights, offset::Int=0)
    sum(get_past_grid(tr, offset) .* exp(w) for (tr, w) in zip(traces, weights))
end

"Get weighted array of past locations which violated expectations."
function get_past_voe_grid(trace::Trace)
    world_traj = get_retval(trace)
    obs_traj = [ws.obs_state for ws in world_traj]
    obs_locs = [(s[:xpos], s[:ypos]) for s in obs_traj]
    width, height = obs_traj[1][:width], obs_traj[1][:height]
    grid = zeros(Float64, width, height)
    past_locs = get_past_locs(trace)
    for ((_, x, y), (obs_x, obs_y)) in zip(past_locs, obs_locs)
        if (x, y) == (obs_x, obs_y) continue end
        grid[x, y] = 1
        grid[obs_x, obs_y] = 1
    end
    return grid
end

function get_past_voe_grid(traces, weights)
    return sum(get_past_voe_grid(tr) .* exp(w) for (tr, w) in zip(traces, weights))
end

"Get weighted array of future locations which violated expectations."
function get_future_voe_grid(cur_future_grid::Matrix, prev_future_grid::Matrix)
    return abs.(cur_future_grid - prev_future_grid)
end
