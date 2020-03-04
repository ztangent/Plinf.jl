"Observation noise for x-y position in a gridworld."
@gen function observe_pos(state::State, fact_noise=0.05, fluent_noise=0.25)
    return @trace(observe(state, Term[], @julog[xpos, ypos],
                  fact_noise, fluent_noise))
end

"Observation noise for x-y trajectory."
observe_traj = Map(observe_pos)

"Observation choice map for x-y position in a gridworld."
function pos_choicemap(state::State)
    return obs_choicemap(state, Term[], @julog[xpos, ypos])
end

"Model of an agent pursuing several possible goals in a gridworld."
@gen function model(goals, state::State, domain::Domain,
                    planner=sample_search, planner_args=())
    plan, traj = @trace(planner(goals[1], state, domain, planner_args...))
    obs_traj = @trace(observe_traj(traj), :traj)
    return Vector{State}(obs_traj)
end
