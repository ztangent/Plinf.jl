using PDDL
using DataStructures: OrderedDict

"Converts a word to a list of terms representing a tower of blocks."
function word_to_terms(word::String)
    top = Const(Symbol(word[1]))
    bottom = Const(Symbol(word[end]))
    terms = Term[Compound(:clear, [top]), Compound(:ontable, [bottom])]
    for (c1, c2) in zip(word[1:end-1], word[2:end])
        c1, c2 = Const(Symbol(c1)), Const(Symbol(c2))
        push!(terms, Compound(:on, [c1, c2]))
    end
    return terms
end

"""
    BlocksworldCombinedCallback(renderer, domain; kwargs...)

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
function BlocksworldCombinedCallback(
    renderer::GraphworldRenderer, domain::Domain;
    goal_addr = :init => :agent => :goal => :goal,
    goal_names = ["Goal $i" for i in 1:5],
    goal_colors = Makie.colorschemes[:plasma][1:32:32*length(goal_names)],
    goal_support = 1:length(goal_names), 
    obs_trajectory = nothing,
    print_goal_probs::Bool = true,
    render::Bool = true,
    plot_goal_bars::Bool = false,
    plot_goal_lines::Bool = false,
    record::Bool = false,
    sleep::Real = 0.2,
    framerate = 2,
    format = "mp4"
)
    callbacks = OrderedDict{Symbol, SIPSCallback}()
    # Helper function to get goal probabilities
    function get_goal_probs(t::Int, pf_state)
        addr = goal_addr isa Function ? goal_addr(t, pf_state) : goal_addr
        return probvec(pf_state, addr, goal_support)::Vector{Float64}
    end
    # Construct data logger callback
    callbacks[:logger] = DataLoggerCallback(
        t = (t, pf) -> t::Int,
        goal_probs = get_goal_probs,
        lml_est = pf -> log_ml_estimate(pf)::Float64,
    )
    # Construct print callback
    if print_goal_probs
        callbacks[:print] = PrintStatsCallback(
            (goal_addr, goal_support);
            header="t\t" * join(goal_names, "\t") * "\n"
        )
    end
    # Construct render callback
    if render
        figure = Figure(resolution=(600, 600))
        callbacks[:render] = RenderCallback(
            renderer, figure[1, 1], domain;
            trajectory=obs_trajectory,
            transition=PDDLViz.StepTransition()
        )
    end
    # Construct plotting callbacks
    if plot_goal_bars || plot_goal_lines
        if render
            resize!(figure, 1200, 600)
        else
            figure = Figure(resolution=(600, 600))
        end
        side_layout = GridLayout(figure[1, 2])
    end
    if plot_goal_bars
        callbacks[:goal_bars] = BarPlotCallback(
            side_layout[1, 1], get_goal_probs;
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
            color = goal_colors, labels = goal_names,
            axis = (xlabel="Time", ylabel = "Probability",
                    limits=((1, nothing), (0, 1))),
            legend_title = "Goals",
            legend_args = (framevisible=false, position=:rt)
        )
    end
    # Construct recording callback
    if record && (render || plot_goal_bars || plot_goal_lines)
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
