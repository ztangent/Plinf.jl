"Online goal inference for a task planning agent using a particle filter."
function task_agent_pf(agent_args::Tuple, obs_traj::Vector{State},
                       obs_terms::Vector{<:Term}, n_particles::Int)
    # Initialize particle filter with initial observations
    init_obs = state_choices(obs_traj[1], obs_terms, (:traj => 1))
    pf_state = initialize_particle_filter(task_agent, (1, agent_args...),
                                          init_obs, n_particles)
    agent_argdiffs = fill(NoChange(), length(agent_args))
    # Feed new observations at each timestep
    for t=2:length(obs_traj)
        maybe_resample!(pf_state, ess_threshold=n_particles/2)
        obs = state_choices(obs_traj[t], obs_terms, (:traj => t))
        particle_filter_step!(pf_state, (t, agent_args...),
            (UnknownChange(), agent_argdiffs...), obs)
    end
    # Return particles and their weights
    weights = get_log_weights(pf_state)
    weights = weights .- logsumexp(weights)
    return get_traces(pf_state), weights
end

"Propose a plan constrained to be an extension of a partial trajectory."
@gen function propose_extension(
    goals::Vector{<:Term}, traj::Vector{State}, domain::Domain,
    search_noise::Float64=0.1, max_nodes::Number=Inf,
    heuristic::Function=manhattan)
    # Remove conjunctions in goals
    goals = reduce(vcat, map(g -> (g.name == :and) ? g.args : Term[g], goals))
    # Propose an extension from the final state to the goal
    _, extension = @trace(sample_search(goals, traj[end], domain, search_noise,
                                        max_nodes, heuristic), :extension)
    # for s in extension println("($(s[:xpos], s[:ypos]))") end
    traj = [traj; extension]
    # Initialize state and various counters
    state, node_count, trial_count, traj_count = traj[1], 0, 0, 0
    choices = Dict{Pair,State}()
    # Initialize path costs and priority queue
    parents = Dict{State,Tuple{State,Term}}()
    path_costs = Dict{State,Int64}(state => 0)
    queue = OrderedDict{State,Int64}(state => heuristic(goals, state, domain))
    while length(queue) > 0
        # Sample state from queue, biased towards states in proposed trajectory
        if @trace(bernoulli(0.9), (:from_traj, trial_count))
            state = traj[traj_count+1]
        else
            probs = softmax([-search_noise*v for v in values(queue)])
            state = @trace(labeled_cat(collect(keys(queue)), probs),
                           (:from_queue, trial_count))
        end
        choices[:node => node_count] = state
        @debug "State: $((state[:xpos], state[:ypos]))"
        # Update counters
        trial_count += 1
        node_count += 1
        traj_count += state == traj[traj_count+1] ? 1 : 0
        # Return plan if end of proposed trajectory is reached
        if traj_count == length(traj)
            for (addr, s) in choices
                @trace(labeled_cat([s], [1.0]), addr)
            end
            return reconstruct_plan(state, parents)
        end
        # Get successors of current state
        actions = available(state, domain)
        successors = [transition(domain, state, act) for act in actions]
        path_cost = path_costs[state] + 1
        cost_diffs = [get(path_costs, s, Inf) - path_cost for s in successors]
        # Backtrack if the current state shortcuts the proposed trajectory
        if (state != traj[traj_count] &&
            any([d > 0 && s in traj for (d, s) in zip(cost_diffs, successors)]))
            @debug "Backtracking..."
            delete!(choices, :node => node_count)
            node_count -= 1
            continue
        end
        delete!(queue, state)
        # Iterate through successors
        for (next_state, act, cost_diff) in zip(successors, actions, cost_diffs)
            if cost_diff <= 0 continue end
            @debug "Extending to $((next_state[:xpos], next_state[:ypos]))"
            # Update path costs and backpointers
            parents[next_state] = (state, act)
            path_costs[next_state] = path_cost
            # Update estimated cost from next state to goal
            if !(next_state in keys(queue))
                est_cost = path_cost + heuristic(goals, state, domain)
                queue[next_state] = est_cost
            else
                queue[next_state] -= cost_diff
            end
        end
    end
    return nothing, nothing
end
