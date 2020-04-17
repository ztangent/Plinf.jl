export agent_pf, replan_rejuvenate

"Online goal inference for a task planning agent using a particle filter."
function agent_pf(agent_model::GenerativeFunction, agent_args::Tuple,
                  obs_traj::Vector{State}, obs_terms::Vector{<:Term},
                  domain::Domain, n_particles::Int;
                  rejuvenate=nothing, callback=nothing)
    # Initialize particle filter with initial observations
    init_obs = state_choices(obs_traj[1], obs_terms, (:traj => 1))
    pf_state = initialize_particle_filter(agent_model, (1, agent_args...),
                                          init_obs, n_particles)
    agent_argdiffs = fill(NoChange(), length(agent_args))
    # Run callback with initial state
    if callback != nothing
        trs, ws = get_traces(pf_state), lognorm(get_log_weights(pf_state))
        callback(1, obs_traj[1], trs, ws)
    end
    # Feed new observations at each timestep
    for t=2:length(obs_traj)
        obs = state_choices(obs_traj[t], domain, obs_terms, (:traj => t));
        particle_filter_step!(pf_state, (t, agent_args...),
            (UnknownChange(), agent_argdiffs...), obs)
        resampled = maybe_resample!(pf_state, ess_threshold=n_particles/4)
        if resampled
            if rejuvenate != nothing rejuvenate(pf_state) end
        end
        if callback != nothing
            trs, ws = get_traces(pf_state), lognorm(get_log_weights(pf_state))
            callback(t, obs_traj[t], trs, ws)
        end
    end
    # Return particles and their weights
    return get_traces(pf_state), lognorm(get_log_weights(pf_state))
end

"Rejuvenation MCMC move for replanning agent models."
function replan_rejuvenate(pf_state::Gen.ParticleFilterState,
                           n_rejuv_steps::Int=1, rejuv_temp::Real=log(1.25))
    # Potentially rejuvenate each trace
    for (i, trace) in enumerate(pf_state.traces)
        # Resample everything with some low probability
        if bernoulli(0.1)
            for k = 1:n_rejuv_steps
                trace, _ = mh(trace, select(:goal, :traj))
            end
            pf_state.new_traces[i] = trace
            continue
        end
        # Get last step at which replanning occurred
        rp_states = trace[:traj]
        t, _ = get_last_plan_step(rp_states)
        last_plan_length = length(rp_states) - t + 1
        # Resample final plan with probability decreasing in plan length
        resample_last_plan = bernoulli(exp(-rejuv_temp * last_plan_length))
        if resample_last_plan
            selection = select(:traj => t => :max_resource, :traj => t => :plan)
            for k = 1:n_rejuv_steps
                trace, _ = mh(trace, selection)
            end
            pf_state.new_traces[i] = trace
        end
    end
    # Swap references
    tmp = pf_state.traces
    pf_state.traces = pf_state.new_traces
    pf_state.new_traces = tmp
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
