using DataStructures: OrderedDict

"Converts an (x, y) position to a corresponding goal term."
pos_to_terms(pos::Tuple{Int, Int}) =
    [parse_pddl("(== (xpos) $(pos[1]))"), parse_pddl("(== (ypos) $(pos[2]))")]

"Converts a goal term to an (x, y) position."
goal_to_pos(term::Term) =
    (term.args[1].args[2].name, term.args[2].args[2].name)

"""
    GridworldCombinedCallback(renderer, domain; kwargs...)

Convenience constructor for a combined particle filter callback that 
logs data and visualizes inference for a gridworld domain.

# Keyword Arguments

- `goal_addr`: Trace address of goal variable.
- `goal_names`: Names of goals.
- `goal_colors`: Colors of goals.
- `obs_trajectory = nothing`: Ground truth / observed trajectory.
- `print_goal_probs = true`: Whether to print goal probabilities.
- `render = true`: Whether to render the gridworld.
- `plot_goal_bars = false`: Whether to plot goal probabilities as a bar chart.
- `plot_goal_lines = false`: Whether to plot goal probabilities over time.
- `record = false`: Whether to record the figure.
- `sleep = 0.2`: Time to sleep between frames.
- `framerate = 5`: Framerate of recorded video.
- `format = "mp4"`: Format of recorded video.
"""    
function GridworldCombinedCallback(
    renderer::GridworldRenderer, domain::Domain;
    goal_addr = :init => :agent => :goal => :goal,
    goal_names = ["A", "B", "C"],
    goal_colors = [:orange, :magenta, :blue],
    obs_trajectory = nothing,
    print_goal_probs::Bool = true,
    render::Bool = true,
    plot_goal_bars::Bool = false,
    plot_goal_lines::Bool = false,
    record::Bool = false,
    sleep::Real = 0.2,
    framerate = 5,
    format = "mp4"
)
    callbacks = OrderedDict{Symbol, SIPSCallback}()
    n_goals = length(goal_names)
    # Construct data logger callback
    callbacks[:logger] = DataLoggerCallback(
        t = (t, pf) -> t::Int,
        goal_probs = pf -> probvec(pf, goal_addr, 1:n_goals)::Vector{Float64},
        lml_est = pf -> log_ml_estimate(pf)::Float64,
    )
    # Construct print callback
    if print_goal_probs
        callbacks[:print] = PrintStatsCallback(
            (goal_addr, 1:n_goals);
            header="t\t" * join(goal_names, "\t") * "\n"
        )
    end
    # Construct render callback
    if render
        figure = Figure(resolution=(600, 600))
        callbacks[:render] = RenderCallback(
            renderer, figure[1, 1], domain;
            trajectory=obs_trajectory, trail_length=10
        )
    end
    # Construct plotting callbacks
    if plot_goal_bars || plot_goal_lines
        if render
            resize!(figure, (1200, 600))
        else
            figure = Figure(resolution=(600, 600))
        end
        side_layout = GridLayout(figure[1, 2])
    end
    if plot_goal_bars
        callbacks[:goal_bars] = BarPlotCallback(
            side_layout[1, 1],
            pf -> probvec(pf, goal_addr, 1:n_goals)::Vector{Float64};
            color = goal_colors,
            axis = (xlabel="Goal", ylabel = "Probability",
                    limits=(nothing, (0, 1)), 
                    xticks=(1:length(goals), goal_names))
        )
    end
    if plot_goal_lines
        callbacks[:goal_lines] = SeriesPlotCallback(
            side_layout[2, 1],
            callbacks[:logger], 
            :goal_probs, # Look up :goal_probs variable
            ps -> reduce(hcat, ps); # Convert vectors to matrix for plotting
            color = goal_colors, labels=goal_names,
            axis = (xlabel="Time", ylabel = "Probability",
                    limits=((1, nothing), (0, 1)))
        )
    end
    # Construct recording callback
    if record
        callbacks[:record] = RecordCallback(figure, framerate=framerate,
                                            format=format)
    end
    # Display figure
    if render || plot_goal_bars || plot_goal_lines
        display(figure)
    end
    # Combine all callback functions
    callback = CombinedCallback(;sleep=sleep, callbacks...)
    return callback
end
