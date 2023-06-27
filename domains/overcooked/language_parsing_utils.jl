using PDDL, SymbolicPlanners
using Gen, GenGPT3
using DataFrames, CSV

using GenParticleFilters: softmax
using GenGPT3: randboltzmann

include("trie.jl")

## Writing Utilities ##

"Removes numeric identifiers in a string."
remove_numbers(str::String) = replace(str, r"\d+" => "")

"Returns a plan annotated with the provided annotations."
function write_annotated_plan(
    plan::Vector{<:Term},
    annotations::Vector{<:AbstractString},
    times::Vector{Int};
    act_prefix = "", act_separator = "\n", act_suffix = "\n",
    ann_first = false, ann_prefix = "; ", ann_suffix = "\n",
    no_numbers = true
)
    annotated_plan = ""
    prev_t = 0
    for (t, ann) in zip(times, annotations)
        if ann_first
            annotated_plan *= ann_prefix * ann * ann_suffix
        end
        acts = write_pddl.(plan[prev_t+1:t])
        if no_numbers
            acts = remove_numbers.(acts)
        end
        annotated_plan *= act_prefix
        annotated_plan *= join(acts, act_separator)
        annotated_plan *= act_suffix
        if !ann_first
            annotated_plan *= ann_prefix * ann * ann_suffix
        end
        prev_t = t
    end
    return annotated_plan
end

"Returns a subgoal sequence annotated with the provided annotations."
function write_annotated_subgoals(
    subgoals::Vector{<:Vector{<:Term}},
    annotations::Vector{<:AbstractString};
    sg_prefix = "", sg_separator = "\n", sg_suffix = "\n",
    ann_first = true, ann_prefix = "; ", ann_suffix = "\n",
    no_numbers = true, include_count = true
)
    annotated_subgoals = ""
    prev_t = 0
    for (terms, ann) in zip(subgoals, annotations)
        n_subgoals = length(terms)
        if ann_first
            annotated_subgoals *= ann_prefix * ann * ann_suffix
            if include_count
                count_str = "Number of subgoals: $n_subgoals"
                annotated_subgoals *= ann_prefix * count_str * ann_suffix
            end
        end
        terms = write_pddl.(terms)
        if no_numbers
            terms = remove_numbers.(terms)
        end
        annotated_subgoals *= sg_prefix
        annotated_subgoals *= join(terms, sg_separator)
        annotated_subgoals *= sg_suffix
        if !ann_first
            annotated_subgoals *= ann_prefix * ann * ann_suffix
            if include_count
                count_str = "Number of subgoals: $n_subgoals"
                annotated_subgoals *= ann_prefix * count_str * ann_suffix
            end
        end
    end
    return annotated_subgoals
end

## Actions Sequence Decoding ##

"Returns the logprobs of each available action given a prompt."
function llm_action_logprobs(
    domain::Domain, state::State, prompt::AbstractString;
    llm::MultiGPT3GF = MultiGPT3GF(model="babbage"),
    stop_str = ";", stop_bias = 0.0, no_numbers = true
)
    actions = collect(available(domain, state))
    action_strs = write_pddl.(actions)
    if no_numbers
        action_strs = remove_numbers.(action_strs)
    end
    prompt_tokens = GenGPT3.tokenize(prompt)
    action_tokens = [GenGPT3.tokenize(act_str) for act_str in action_strs]
    max_tokens = maximum(length.(action_tokens)) + length(prompt_tokens)
    if max_tokens > 2048
        prompt_tokens = prompt_tokens[end-(max_tokens-2048):end]
        prompt = GenGPT3.detokenize(prompt_tokens)
    end
    choices = MultiGPT3ChoiceMap(push!(action_strs, stop_str))
    trace, _ = generate(llm, (length(actions) + 1, prompt), choices)
    logprobs = trace.scores
    act_logprobs = Dict(zip(actions, logprobs[1:end-1]))
    act_logprobs[Compound(:stop, Term[])] = logprobs[end] + stop_bias
    return act_logprobs
end

"Propose a executable sequence of actions via constrained LLM decoding."
function propose_action_sequence_constrained(
    domain::Domain, state::State, prompt::AbstractString;
    llm::MultiGPT3GF = MultiGPT3GF(model="babbage"),
    stop_str = ";", stop_bias = 0.0, temperature = 0.0,
    min_length = 1, max_length = 15, no_numbers = true
)
    actions = Term[]
    score = 0.0
    for i in 1:max_length
        # Evaluate log probabilities of available actions
        act_logprobs = llm_action_logprobs(
            domain, state, prompt;
            llm, stop_str, stop_bias, no_numbers
        )
        if i <= min_length # Prevent early termination
            delete!(act_logprobs, Compound(:stop, Term[]))
        end
        if temperature == 0.0 # Propose most probable action
            act = argmax(act_logprobs)
            score += act_logprobs[act]
        else # Propose action according to normalized logprobs
            actions = collect(keys(act_logprobs))
            rescaled_logprobs = collect(values(act_logprobs)) ./ temperature
            rescaled_logprobs .-= logsumexp(rescaled_logprobs)
            act_idx = randboltzmann(1:length(actions), rescaled_logprobs)
            act = actions[act_idx]
            score += rescaled_logprobs[act_idx]
        end
        if act.name == :stop
            break
        end
        push!(actions, act)
        prompt *= write_pddl(act) * "\n"
        state = transition(domain, state, act)
    end
    return actions, state, score
end

"Propose multiple executable action sequences via constrained LLM decoding."
function multi_propose_action_sequence_constrained(
    domain::Domain, state::State, prompt::AbstractString, n_seqs::Int;
    kwargs...
)
    actions = Vector{Term}[]
    end_states = Vector{typeof(state)}[]
    scores = Float64[]
    for i in 1:n_seqs
        acts, end_state, score = propose_action_sequence_constrained(
            domain, state, prompt; kwargs...
        )
        push!(actions, acts)
        push!(end_states, end_state)
        push!(scores, score)
    end
    return actions, end_states, scores
end

"Propose an executable sequence of actions via rejection sampling an LLM."
function propose_action_sequence_rejection(
    domain::Domain, state::State, prompt::AbstractString;
    kwargs...
)
    actions, end_states, scores, _ = propose_action_sequences_rejection(
        domain, state, prompt, 1; kwargs...
    )
    return actions[1], end_states[1], scores[1]
end

"Propose multiple executable sequences of actions via rejection sampling an LLM."
function multi_propose_action_sequences_rejection(
    domain::Domain, state::State, prompt::AbstractString, n_seqs::Int;
    llm::MultiGPT3GF = MultiGPT3GF(model="text-davinci-002", stop=";", max_tokens=256),
    min_length = 1, max_length = 15, verbose = false
)
    # Define validator
    function is_valid(completion::AbstractString)
        # Try to parse completion to PDDL
        actions = try
            strs = string.(strip.(split(completion, "\n")))
            strs = filter(s -> !isempty(s), strs)
            [parse_pddl(strip(s)) for s in strs]
        catch
            nothing
        end
        if actions === nothing
            if verbose println("Cannot parse completion to PDDL.") end
            return false
        end
        if verbose display(actions) end
        # Check if completion has valid length
        if length(actions) < min_length || length(actions) > max_length
            if verbose println("Completion has invalid length.") end
            return false
        end
        # Check if completion is executable
        s = state
        for act in actions
            if !(act.name in keys(PDDL.get_actions(domain)))
                if verbose println("$(write_pddl(act)) not in domain.") end
                return false
            end
            if !available(domain, s, act)
                if verbose println("$(write_pddl(act)) not available.") end
                return false
            end
            s = transition(domain, s, act, check=false)
        end
        return true
    end

    # Perform alive importance sampling until `n_seqs` valid samples are found
    llm_importance_sampler = GPT3IS(model_gf=llm, validator=is_valid)
    trace = simulate(llm_importance_sampler, (n_seqs, prompt))
    n_sampled = length(trace.valid)

    # Convert outputs of each valid sample to action sequences
    valid_idxs = findall(trace.valid)
    completions = trace.model_trace.outputs[valid_idxs]
    scores = trace.model_trace.scores[valid_idxs] .- trace.log_z_est
    actions = Vector{Term}[]
    end_states = Vector{typeof(state)}[]
    for completion in completions
        strs = string.(strip.(split(completion, "\n")))
        strs = filter(s -> !isempty(s), strs)
        acts = [parse_pddl(strip(s)) for s in strs]
        end_state = PDDL.simulate(EndStateSimulator(), domain, state, acts)
        push!(actions, acts)
        push!(end_states, end_state)
    end
 
    return actions, end_states, scores, n_sampled
end

"Enumerate top-k action sequences via beam search with constrained decoding."
function enumerate_top_action_sequences(
    domain::Domain, states::Vector{<:State},
    prompts::Vector{<:AbstractString}, scores::Vector{Float64};
    llm::MultiGPT3GF = MultiGPT3GF(model="babbage"),
    n_candidates = length(states),
    stop_str = ";", stop_bias = 0.0,
    min_length = 1, max_length = 15, no_numbers = true, verbose = false
)
    @assert length(states) == length(prompts) == length(scores)
    action_seqs = [Term[] for _ in 1:min(n_candidates, length(states))]
    # Iterate until maxium sequence length
    for i in 1:max_length
        if verbose println("-- Step $i --") end
        # Allocate space for next candidates
        next_action_seqs = Vector{Term}[]
        next_states = Vector{eltype(states)}()
        next_prompts = Vector{eltype(prompts)}()
        next_scores = Float64[]
        for j in eachindex(states)
            # Do not extend candidate if it has already terminated
            if i > (min_length + 1) && action_seqs[j][end].name == :stop
                next_score = scores[j]
                # Skip if worse than top k candidates
                if (length(next_scores) == n_candidates &&
                    next_score < next_scores[end])
                    continue
                end
                # Otherwise add this back to the candidate list
                next_idx = isempty(next_scores) ?
                    1 : searchsortedfirst(next_scores, next_score, rev=true)
                insert!(next_scores, next_idx, next_score)
                insert!(next_action_seqs, next_idx, action_seqs[j])
                insert!(next_states, next_idx, states[j])
                insert!(next_prompts, next_idx, prompts[j])
                # Remove last candidate if neccessary
                if length(next_scores) > n_candidates
                    pop!(next_action_seqs)
                    pop!(next_scores)
                    pop!(next_states)
                    pop!(next_prompts)
                end
                continue
            end
            # Evaluate log probabilities of available actions
            act_logprobs = llm_action_logprobs(
                domain, states[j], prompts[j];
                llm, stop_str, stop_bias, no_numbers
            )
            # Prevent early termination
            if i <= min_length
                delete!(act_logprobs, Compound(:stop, Term[]))
            end
            # Find top k actions
            actions = collect(keys(act_logprobs))
            logprobs = collect(values(act_logprobs))
            logprobs .-= logsumexp(logprobs)
            n_top = min(n_candidates, length(actions))
            top_idxs = partialsortperm(logprobs, 1:n_top, rev=true)
            # Extend previous candidates with top k actions
            for k in top_idxs
                next_score = scores[j] + logprobs[k]
                # Terminate early if no sequence is better
                if (length(next_scores) == n_candidates &&
                    next_score < next_scores[end])
                    break
                end
                # Compute extensions
                next_action_seq = push!(copy(action_seqs[j]), actions[k])
                if actions[k].name == :stop
                    next_state = states[j]
                    next_prompt = prompts[j]
                else
                    next_state = transition(domain, states[j], actions[k])
                    act_str = write_pddl(actions[k])
                    if no_numbers
                        act_str = remove_numbers(act_str)
                    end
                    next_prompt = prompts[j] * act_str * "\n"
                end
                # Add candidate to list of next candidates in sorted order
                next_idx = isempty(next_scores) ?
                    1 : searchsortedfirst(next_scores, next_score, rev=true)
                insert!(next_action_seqs, next_idx, next_action_seq)
                insert!(next_scores, next_idx, next_score)
                insert!(next_states, next_idx, next_state)
                insert!(next_prompts, next_idx, next_prompt)
                # Remove last candidate if neccessary
                if length(next_scores) > n_candidates
                    pop!(next_action_seqs)
                    pop!(next_scores)
                    pop!(next_states)
                    pop!(next_prompts)
                end
            end
        end
        # Update candidates
        action_seqs = next_action_seqs
        states = next_states
        prompts = next_prompts
        scores = next_scores
        if verbose
            for acts in action_seqs
                println(join(write_pddl.(acts), " "))
            end
        end
        # Terminate if all candidates end in stop
        if all([seq[end].name == :stop for seq in action_seqs])
            break
        end
    end
    # Remove stops from action sequences
    for i in eachindex(action_seqs)
        if action_seqs[i][end].name == :stop
            pop!(action_seqs[i])
        end
    end
    return action_seqs, states, scores, prompts
end

function enumerate_top_action_sequences(
    domain::Domain, state::State, prompt::AbstractString, n_seqs::Int = 1;
    kwargs...
)
    return enumerate_top_action_sequences(
        domain, [state], [prompt], [0.0]; n_candidates=n_seqs, kwargs...
    )
end

## Plan Decoding ##

PLAN_DECODING_PROMPT_HEADER = 
    ";; Below is a PDDL plan annotated with English descriptions.\n\n"
PLAN_DECODING_PROMPT_FOOTER = 
    "\n;; Below is another PDDL plan annotated with English descriptions.\n\n"

"Propose a complete plan given language annotations via constrained decoding."
function propose_plan_constrained(
    domain::Domain, state::State, annotations::Vector{<:AbstractString};
    llm::MultiGPT3GF = MultiGPT3GF(model="babbage"),
    prompt::AbstractString = "",
    stop_str = ";", stop_bias = 0.0, temperature = 0.0,
    min_seq_length=1, max_seq_length = 15, no_numbers = true, verbose = false
)
    plan = Term[]
    subplans = Vector{Term}[]
    score = 0.0
    # Iterate over annotations
    for sentence in annotations
        if verbose
            println("; " * sentence)
        end
        prompt = prompt * "; " * sentence * "\n"
        # Propose action sequence given prompt and sentence
        act_seq, state, seq_score = propose_action_sequence_constrained(
            domain, state, prompt;
            llm, stop_str, stop_bias, temperature, no_numbers,
            min_length=min_seq_length, max_length=max_seq_length
        )
        score += seq_score
        append!(plan, act_seq)
        push!(subplans, act_seq)
        # Extend prompt with proposed action sequence
        act_strs = string.(act_seq)
        if no_numbers
            act_strs = remove_numbers.(act_strs)
        end
        prompt = prompt * join(act_strs, "\n")
        if verbose
            for act in act_seq
                println(write_pddl(act))
            end
        end
    end
    return plan, subplans, state, score, prompt
end

"Enumerate top k complete plans given language annotations via beam search."
function enumerate_top_plans(
    domain::Domain, state::State, annotations::Vector{<:AbstractString},
    n_plans::Int = 1, n_seqs::Int = 5;
    proposal_lm::MultiGPT3GF = MultiGPT3GF(model="babbage", max_tokens=64),
    proposal_store::Union{DataFrame, Nothing} = nothing,
    proposal_store_filter = nothing,
    n_proposal_examples::Int = 2,
    model_lm::MultiGPT3GF = MultiGPT3GF(model="babbage", max_tokens=128),
    model_prompt::AbstractString = "",
    use_instruction::Bool = true,
    instruction_lm::GPT3GF = GPT3GF(model="text-davinci-003", max_tokens=128,
                                    temperature=0.0, stop="\n"),
    stop_str = ";", stop_bias = 0.0, no_numbers = true,
    min_seq_length=1, max_seq_length = 15, verbose = false
)
    plans = [Term[]]
    states = [state]
    scores = Float64[0.0]
    seq_lengths = [Int[]]
    m_prompts = [string(model_prompt)]
    instructions = [String[]]
    # Iterate over annotations
    for (t, sentence) in enumerate(annotations)
        if verbose
            println("; " * sentence)
        end
        # Allocate space for next candidates
        next_plans = Vector{Vector{Term}}()
        next_states = Vector{eltype(states)}()
        next_scores = Float64[]
        next_seq_lengths = Vector{Vector{Int}}()
        next_m_prompts = String[]
        next_instructions = Vector{Vector{String}}()
        # Extend each candidate plan
        for i in eachindex(plans)
            if verbose println("Extending plan $i...") end
            # Construct proposal prompt context
            if isnothing(proposal_store)
                proposal_prompt = PLAN_DECODING_PROMPT_HEADER
            else
                proposal_prompt = construct_action_proposal_prompt(
                    annotations[max(t-1,1):t], max(t-1,1):t,
                    proposal_store, n_proposal_examples;
                    filter_fn = proposal_store_filter
                )
            end
            # Add proposed actions for previous annotation to prompt
            if t > 1
                proposal_prompt *= "; " * annotations[t-1]
                if use_instruction
                    proposal_prompt *= instructions[i][end] * instruction_lm.stop
                else
                    proposal_prompt *= "\n"
                end
                last_seq_length = seq_lengths[i][end]
                last_seq = plans[i][end-last_seq_length+1:end]
                act_strs = write_pddl.(last_seq)
                if no_numbers
                    act_strs = remove_numbers.(act_strs)
                end
                proposal_prompt *= join(act_strs, "\n") * "\n"
            end
            # Add current annotation to prompt
            proposal_prompt *= "; " * sentence
            if use_instruction
                # Generate instruction for chain-of-thought guidance
                proposal_prompt *= " This involves"
                instruction = instruction_lm(proposal_prompt)
                # Append instruction to proposal prompt
                proposal_prompt *= instruction * instruction_lm.stop
                instruction = " This involves" * instruction
                if verbose
                    println(";" * instruction)
                end
            else
                proposal_prompt *= "\n"
                instruction = ""
            end
            if verbose
                println("\n== Proposal Prompt ==")
                println(proposal_prompt)
                println()
            end
            # Enumerate top action sequences (given sentence) via beam search
            act_seqs, end_states, _, _ = enumerate_top_action_sequences(
                domain, states[i], proposal_prompt, n_seqs;
                llm=proposal_lm, stop_str, stop_bias,
                min_length=min_seq_length, max_length=max_seq_length,
                no_numbers, verbose
            )
            # Score action sequences under model
            model_prompts = map(act_seqs) do act_seq
                act_strs = join(write_pddl.(act_seq), "\n")
                if no_numbers
                    act_strs = remove_numbers(act_strs)
                end
                m_prompts[i] * act_strs * "\n"
            end
            if use_instruction
                model_output = "; " * sentence * "\n"
                # model_output = "; " * sentence * instruction * "\n"
            else
                model_output = "; " * sentence * "\n"
            end
            choices = MultiGPT3ChoiceMap(fill(model_output, length(act_seqs)))
            model_trace, _ = generate(model_lm, (model_prompts,), choices)
            # Score according to how likely the observed sentence was
            model_scores = model_trace.scores
            # Penalize longer action sequences
            model_scores .+= log(0.95) .* length.(act_seqs)
            # Add to previous score
            model_scores .+= scores[i]
            model_prompts .*= model_output
            # Add candidates in sorted order
            for (j, act_seq) in enumerate(act_seqs)
                # Skip if worse than top k candidates
                if (length(next_scores) == n_plans &&
                    model_scores[j] < next_scores[end])
                    continue
                end
                # Insert candidate
                next_idx = isempty(next_scores) ?
                    1 : searchsortedfirst(next_scores, model_scores[j], rev=true)
                next_plan = vcat(plans[i], act_seq)
                next_seq_length = [seq_lengths[i]; length(act_seq)]
                next_instruction = [instructions[i]; instruction]
                insert!(next_plans, next_idx, next_plan)
                insert!(next_scores, next_idx, model_scores[j])
                insert!(next_states, next_idx, end_states[j])
                insert!(next_seq_lengths, next_idx, next_seq_length)
                insert!(next_m_prompts, next_idx, model_prompts[j])
                insert!(next_instructions, next_idx, next_instruction)
                # Remove last candidate if neccessary
                if length(next_scores) > n_plans
                    pop!(next_plans)
                    pop!(next_scores)
                    pop!(next_states)
                    pop!(next_seq_lengths)
                    pop!(next_m_prompts)
                    pop!(next_instructions)
                end
            end
        end
        # Print best plan extensions
        if verbose
            println()
            for (i, plan) in enumerate(next_plans)
                println("== Plan $i ==")
                act_idx = 0
                for (sentence_idx, n_acts) in enumerate(next_seq_lengths[i])
                    println("; " * annotations[sentence_idx])
                    for _ in 1:n_acts
                        act_idx += 1
                        println(write_pddl(plan[act_idx]))
                    end
                end
                println()
            end
        end
        # Update candidates
        plans = next_plans
        states = next_states
        scores = next_scores
        seq_lengths = next_seq_lengths
        m_prompts = next_m_prompts
        instructions = next_instructions
    end
    return plans, states, scores, seq_lengths, instructions, m_prompts
end

"Constructs prompts for decoding instructions into PDDL plans."
function construct_plan_decoding_prompt(
    example_plans::Vector{<:AbstractString};
    header = PLAN_DECODING_PROMPT_HEADER,
    footer = PLAN_DECODING_PROMPT_FOOTER,
    separator = footer
)
    prompt = join(example_plans, separator)
    prompt = header * prompt * footer
    return prompt
end

"Constructs model prompt for decoding instructions into PDDL plans."
function construct_plan_model_prompt(
    test_annotations::Vector{<:AbstractString},
    annotation_store::DataFrame, k::Int;
    filter_fn = nothing, reversed = true, verbose=false, kwargs...
)
    model_examples, _, n_model, _ =
        select_annotated_plan_examples(
            test_annotations, annotation_store, k;
            filter_fn, reversed
        )
    if verbose
        n_model_total = sum(n_model)
        println("Using $n_model_total tokens for the model prompt.")
    end
    return construct_plan_decoding_prompt(model_examples, ; kwargs...)    
end

"Constructs proposal prompt for decoding instructions into PDDL plans."
function construct_plan_proposal_prompt(
    test_annotations::Vector{<:AbstractString},
    annotation_store::DataFrame, k::Int;
    filter_fn = nothing, reversed = true, verbose=false, kwargs...
)
    _, proposal_examples, _, n_proposal =
        select_annotated_plan_examples(
            test_annotations, annotation_store, k;
            filter_fn, reversed
        )
    if verbose
        n_proposal_total = sum(n_proposal)
        println("Using $n_proposal_total tokens for the proposal prompt.")
    end
    return construct_plan_decoding_prompt(proposal_examples, ; kwargs...)    
end


"Construct proposal prompt for decoding instructions into action sequences."
function construct_action_proposal_prompt(
    test_annotations::Vector{<:AbstractString}, steps,
    annotated_action_store::DataFrame, k::Int;
    filter_fn = nothing, reversed = true, verbose=false, kwargs...
)
    _, proposal_examples =
        select_annotated_action_examples(
            test_annotations, steps, annotated_action_store, k;
            filter_fn, reversed
        )
    return construct_plan_decoding_prompt(proposal_examples; kwargs...)
end

## Subgoal Decoding ##

RELEVANT_PREDICATES = 
    Symbol.(["object-at-loc", "in-receptacle", "holding",
             "prepared", "cooked", "combined"])

"Returns subgoal logprobs given a prompt."
function llm_subgoal_logprobs(
    domain::Domain, state::State, prompt::AbstractString;
    subgoal_strs = write_pddl.(list_possible_subgoals(domain, state)),
    llm::MultiGPT3GF = MultiGPT3GF(model="babbage"), no_numbers = true,
    verbose = false
)
    if verbose
        println("Request logprobabilities for each subgoal...")
    end
    if no_numbers
        subgoal_strs = remove_numbers.(subgoal_strs)
    end
    n = length(subgoal_strs)
    trace, _ = generate(llm, (n, prompt), MultiGPT3ChoiceMap(subgoal_strs))
    return trace.scores
end

"Constrained sampling of a subgoal given a prompt."
function llm_subgoal_sample(
    domain::Domain, state::State, prompt;
    llm::MultiGPT3GF = MultiGPT3GF(model="babbage", max_tokens=0),
    no_numbers = true, temperature = 1.0,
    subgoal_trie = construct_subgoal_trie(domain, state; no_numbers)
)
    if prompt isa AbstractString
        prompt = GenGPT3.id_tokenize(prompt)
    else
        prompt = copy(prompt)
    end
    logprobs = 0.0
    tokens = Int[]
    trie = subgoal_trie
    # Recursively descend trie until we reach a leaf
    while !isempty(trie.children)
        # Descend to next level if no choices are available
        if length(trie.children) == 1
            token = first(keys(trie.children))
            trie = trie.children[token]
            push!(tokens, token)
            push!(prompt, token)
            continue
        end
        # Otherwise sample from available choices
        choices = collect(keys(trie.children))
        inputs = [vcat(prompt, c) for c in choices]
        outputs = GenGPT3.gpt3_multi_prompt_api_call(
            inputs, model = llm.model, max_tokens = 0, echo = true
        )
        choice_lps = [o.logprobs.token_logprobs[end] for o in outputs]
        if temperature != 0.0
            choice_lps ./= temperature
            choice_lps .-= logsumexp(choice_lps)
            choice_idx = randboltzmann(1:length(choices), choice_lps)
        else
            choice_idx = argmax(choice_lps)
        end
        token = choices[choice_idx]
        trie = trie.children[token]
        push!(tokens, token)
        push!(prompt, token)
        logprobs += choice_lps[choice_idx]
    end
    # Randomly sample from leaf
    result = rand(trie.value)
    logprobs -= log(length(trie.value))
    return result, logprobs, tokens
end

"Constrained sampling of a subgoal sequence given a prompt."
function llm_subgoal_seq_sample(
    domain::Domain, state::State, prompt;
    llm::MultiGPT3GF = MultiGPT3GF(model="babbage", max_tokens=0),
    num_subgoal_model = llm.model,
    n_subgoals_prompt = "; Number of subgoals:", n_subgoals_range = 1:5,
    temperature = 1.0, kwargs...
)
    if prompt isa AbstractString
        prompt = GenGPT3.id_tokenize(prompt)
    else
        prompt = copy(prompt)
    end
    # Sample number of subgoals
    append!(prompt, GenGPT3.id_tokenize(n_subgoals_prompt))
    inputs = [vcat(prompt, GenGPT3.id_tokenize(" $k\n"))
               for k in n_subgoals_range]
    outputs = GenGPT3.gpt3_multi_prompt_api_call(
        inputs, model = num_subgoal_model, max_tokens = 0, echo = true
    )
    choice_lps = [sum(o.logprobs.token_logprobs[end-1:end]) for o in outputs]
    if temperature != 0.0
        choice_lps ./= temperature
        choice_lps .-= logsumexp(choice_lps)
        choice_idx = randboltzmann(1:length(n_subgoals_range), choice_lps)
    else
        choice_idx = argmax(choice_lps)
    end
    n_subgoals = n_subgoals_range[choice_idx]
    prompt = inputs[choice_idx]
    logprobs = choice_lps[choice_idx]
    # Sample subgoals
    subgoals = Term[]
    for k in 1:n_subgoals
        subgoal, subgoal_logprobs, tokens = llm_subgoal_sample(
            domain, state, prompt; llm, temperature, kwargs...
        )
        logprobs += subgoal_logprobs
        push!(subgoals, subgoal)
        append!(prompt, tokens)
        append!(prompt, GenGPT3.id_tokenize("\n"))
    end
    return subgoals, logprobs, GenGPT3.id_detokenize(prompt)
end

"Constrained sampling of a subgoal sequence with automatic prompt selection."
function llm_subgoal_seq_sample(
    domain::Domain, state::State,
    annotation::String, store::DataFrame, k::Int = 3;
    filter_fn = nothing, lift = false, reversed = true, verbose = false,
    instruction = "", kwargs...
)
    # Select top-k relevant subgoal examples
    annotated_subgoal_examples, _, _ = 
        select_subgoal_examples(annotation, store, k; filter_fn, lift, reversed)
    # Construct prompt from examples
    prompt = join(annotated_subgoal_examples, "\n")
    prompt *= "\n; " * annotation * "\n"
    prompt = instruction * prompt
    subgoals, logprobs, prompt =
        llm_subgoal_seq_sample(domain, state, prompt; kwargs...)
    if verbose println(prompt) end
    return subgoals, logprobs, prompt    
end

"Propose a sequence of subgoals given a set of annotations."
function propose_subgoal_plan(
    domain::Domain, state::State, annotations::Vector{<:AbstractString};
    llm::MultiGPT3GF = MultiGPT3GF(model="babbage", max_tokens=0),
    n_subgoals_prompt = "; Number of subgoals:",
    n_subgoals_range = 1:5,
    temperature = 1.0,
    no_numbers = true,
    subgoal_store = nothing,
    n_subgoal_examples = 3,
    filter_fn = nothing, lift = false, reversed = true,
    default_prompt = "",
    subgoal_trie = construct_subgoal_trie(domain, state; no_numbers),
    verbose = false, kwargs...
)
    subgoal_plan = Vector{Term}[]
    total_logprobs = 0.0
    all_logprobs = Float64[]
    # Iterate over annotations and sample subgoal sequences
    for annotation in annotations
        if verbose
            println("; " * annotation)
        end
        # Construct prompt if necessary 
        if isnothing(subgoal_store)
            prompt = default_prompt * "\n; " * annotation * "\n"
            subgoals, logprobs, new_prompt =
                llm_subgoal_seq_sample(
                    domain, state, prompt;
                    llm, temperature,
                    n_subgoals_prompt, n_subgoals_range,
                    no_numbers, subgoal_trie, kwargs...
                )
        else
            subgoals, logprobs, new_prompt =
                llm_subgoal_seq_sample(
                    domain, state, annotation,
                    subgoal_store, n_subgoal_examples;
                    filter_fn, lift, reversed,
                    llm, temperature,
                    n_subgoals_prompt, n_subgoals_range,
                    no_numbers, subgoal_trie, kwargs...
                )
        end
        if verbose
            println("; Number of subgoals: ", length(subgoals))
            for goal in subgoals
                println(write_pddl(goal))
            end
            println()
        end
        push!(subgoal_plan, subgoals)
        push!(all_logprobs, logprobs)
        total_logprobs += logprobs
    end
    return subgoal_plan, total_logprobs, all_logprobs
end

"Infer a plan by incrementally proposing subgoals from a set of annotations."
function infer_plan_via_subgoals(
    domain::Domain, state::State, annotations::Vector{<:AbstractString};
    proposal_llm::MultiGPT3GF = MultiGPT3GF(model="babbage", max_tokens=0),
    model_llm = GPT3GF(model="text-davinci-003", max_tokens=256, stop="\n"),
    n_subgoals_prompt = "; Number of subgoals:",
    n_subgoals_range = 1:5,
    temperature = 1.0,
    no_numbers = true,
    subgoal_store = nothing,
    n_subgoal_examples = 3,
    n_particles = 1,
    filter_fn = nothing, lift = false,
    reversed = true,
    default_prompt = "",
    model_prompt = "",
    discount = 0.95,
    subgoal_trie = construct_subgoal_trie(domain, state; no_numbers),
    heuristic = memoized(precomputed(FFHeuristic(), domain, state)),
    planner = AStarPlanner(heuristic, max_time=3.0),
    is_segmented = false,
    segmentation_store = nothing,
    n_segmentation_examples = 3,
    verbose = false, kwargs...
)
    plan = Term[]
    subgoal_plan = Vector{Term}[]
    split_idxs = Int[]
    total_model_weight = 0.0
    lml_est = 0.0
    lml_est_per_step = Float64[]
    sir_weight = 0.0
    sir_weight_per_step = Float64[]
    # Segment annotations
    if !is_segmented
        segmented = segment_annotations(
            annotations, segmentation_store, n_segmentation_examples;
            filter_fn
        )
    else
        segmented = [[annotation] for annotation in annotations]
    end
    for (annotation, seg_annotations) in zip(annotations, segmented)
        if verbose
            println("; " * annotation)
        end
        log_total_weight = -Inf
        cand_actions = nothing
        cand_subgoals = nothing
        cand_model_prompt = nothing
        cand_model_weight = nothing
        for i in 1:n_particles
            tmp_state = copy(state)
            actions = Term[]
            subgoals = Term[]
            prop_weight = 0.0
            for (k, seg_ann) in enumerate(seg_annotations)
                if verbose && !is_segmented
                    println("; $k. " * seg_ann)
                end    
                # Propose subgoals given natural language annotations
                if isnothing(subgoal_store)
                    # Construct prompt if necessary 
                    p_prompt = default_prompt * "\n; " * seg_ann * "\n"
                    subgoals_seg, prop_weight_seg, _ =
                        llm_subgoal_seq_sample(
                            domain, tmp_state, p_prompt;
                            llm = proposal_llm, temperature,
                            n_subgoals_prompt, n_subgoals_range,
                            no_numbers, subgoal_trie, kwargs...
                        )
                else
                    subgoals_seg, prop_weight_seg, _ =
                        llm_subgoal_seq_sample(
                            domain, tmp_state, seg_ann,
                            subgoal_store, n_subgoal_examples;
                            filter_fn, lift, reversed,
                            llm = proposal_llm, temperature,
                            n_subgoals_prompt, n_subgoals_range,
                            no_numbers, subgoal_trie, kwargs...
                        )
                end
                # Print proposed subgoals
                if verbose && n_particles == 1
                    println("; Number of subgoals: ", length(subgoals_seg))
                    for goal in subgoals_seg
                        println(write_pddl(goal))
                    end
                    println()
                end
                append!(subgoals, subgoals_seg)
                prop_weight += prop_weight_seg
                # Ground forall-imply subgoals
                subgoals_seg =
                    [ground_forall_subgoal(domain, tmp_state, g)
                     for g in subgoals_seg]
                # Construct action plan to achieve subgoals
                sol = planner(domain, tmp_state, subgoals_seg)
                if sol.status == :success
                    seg_actions = collect(Term, sol)
                    tmp_state = sol.trajectory[end]
                    append!(actions, seg_actions)
                else
                    seg_actions = Term[]
                end
                if verbose && n_particles == 1
                    println("; Actions")
                    for act in seg_actions
                        println(write_pddl(act))
                    end
                end
            end
            # Append actions to model prompt
            model_prompt_tmp = model_prompt * join(write_pddl.(actions), "\n")
            # Score natural language annotation under model
            model_prompt_tmp = model_prompt_tmp * "\n;"
            _, model_weight = generate(model_llm, (model_prompt_tmp,),
                                       choicemap(:output => " " * annotation))
            model_weight += log(discount) * length(actions)
            # Compute importance weight
            log_weight = model_weight - prop_weight
            if verbose
                println()
                println("Proposal weight: ", prop_weight)
                println("Model weight: ", model_weight)
                println("Importance weight: ", log_weight)
                println()
            end
            # Decide whether to keep this sample
            log_total_weight = logsumexp(log_total_weight, log_weight)
            if isnothing(cand_actions) || rand() < exp(log_weight - log_total_weight)
                cand_actions = actions
                cand_subgoals = subgoals
                cand_model_prompt = model_prompt_tmp * " " * annotation * "\n"
                cand_model_weight = model_weight
                if verbose && n_particles > 1
                    println("Kept sample $i")
                    println()
                end
            end
        end
        # Update weight estimates
        total_model_weight += cand_model_weight
        log_mean_weight = log_total_weight - log(n_particles)
        lml_est += log_mean_weight
        push!(lml_est_per_step, lml_est)
        sir_weight += cand_model_weight - log_mean_weight
        push!(sir_weight_per_step, cand_model_weight - log_mean_weight)
        # Append actions to plan
        append!(plan, cand_actions)
        push!(subgoal_plan, cand_subgoals)
        push!(split_idxs, length(plan))
        # Execute actions
        for act in cand_actions
            state = transition(domain, state, act)
        end
        # Update model prompt
        model_prompt = cand_model_prompt
        if verbose && n_particles > 1
            println("; Number of subgoals: ", length(cand_subgoals))
            for goal in cand_subgoals
                println(write_pddl(goal))
            end
            println()
            println("; Actions")
            for action in cand_actions
                println(write_pddl(action))
            end
            println()
        end
    end
    return (plan, split_idxs, subgoal_plan,
            total_model_weight, lml_est, lml_est_per_step,
            sir_weight, sir_weight_per_step)
end

"Constructs a subgoal trie from a list of subgoals."
function construct_subgoal_trie(subgoals::Vector{<:Term}; no_numbers=true)
    subgoal_strs = write_pddl.(subgoals)
    if no_numbers
        subgoal_strs = remove_numbers.(subgoal_strs)
    end
    subgoal_tokens = GenGPT3.id_tokenize.(subgoal_strs)
    subgoal_trie = Trie{Int, Vector{Term}}()
    for (tokens, goal) in zip(subgoal_tokens, subgoals)
        terms = get(subgoal_trie, tokens, nothing)
        if isnothing(terms)
            subgoal_trie[tokens] = Term[goal]
        else
            push!(terms, goal)
        end
    end
    return subgoal_trie
end

function construct_subgoal_trie(
    domain::Domain, state::State;
    no_numbers=true, kwargs...
)
    subgoals = list_possible_subgoals(domain, state; kwargs...)
    return construct_subgoal_trie(subgoals; no_numbers)
end

"List all possible subgoals for a given state."
function list_possible_subgoals(
    domain::Domain, state::State; kwargs...
)
    subgoals = list_primitive_subgoals(domain, state; kwargs...)
    forall_subgoals = list_forall_subgoals(domain, state)
    return append!(subgoals, forall_subgoals)
end

"List primitive subgoals for a given state."
function list_primitive_subgoals(
    domain::Domain, state::State;
    relevant_predicates = RELEVANT_PREDICATES,
    relevant_neg_predicates = [:holding]
)
    subgoals = Term[]
    for pred in relevant_predicates
        for args in PDDL.groundargs(domain, state, pred)
            push!(subgoals, Compound(pred, collect(Term, args)))
        end
    end
    neg_subgoals = Term[Compound(:not, Term[cond]) for cond in subgoals
                        if cond.name in relevant_neg_predicates]
    return [subgoals; neg_subgoals]
end

"List forall subgoals for a given state."
function list_forall_subgoals(domain::Domain, state::State)
    receptacles = PDDL.get_objects(domain, state, Symbol("receptacle"))
    combine_methods = PDDL.get_objects(state, Symbol("combine-method"))
    cook_methods = PDDL.get_objects(state, Symbol("cook-method"))
    # Construct transfer subgoals
    formula = pddl"(forall (?f - food) (imply (is-prepared ?f) (in-receptacle ?f ?r)))"
    prepare_transfer_subgoals = map(receptacles) do r
        PDDL.substitute(formula, pddl"(?r)" , r)
    end
    formula = pddl"(forall (?f - food) (imply (combined ?m ?f) (in-receptacle ?f ?r)))"
    combine_transfer_subgoals = map(Iterators.product(combine_methods, receptacles)) do (m, r)
        PDDL.substitute(formula, PDDL.Subst(pddl"(?m)" => m, pddl"(?r)" => r))
    end
    formula = pddl"(forall (?f - food) (imply (cooked ?m ?f) (in-receptacle ?f ?r)))"
    cook_transfer_subgoals = map(Iterators.product(cook_methods, receptacles)) do (m, r)
        PDDL.substitute(formula, PDDL.Subst(pddl"(?m)" => m, pddl"(?r)" => r))
    end
    transfer_subgoals = vcat(
        prepare_transfer_subgoals,
        vec(combine_transfer_subgoals),
        vec(cook_transfer_subgoals)
    )
    # Construct combine subgoals
    r_formula = pddl"(and (receptacle-type ?rt ?r) (has-combine-method ?m ?rt ?at))"
    formula = pddl"(forall (?f - food) (imply (in-receptacle ?f ?r) (combined ?m ?f)))"
    combine_subgoals = map(combine_methods) do m
        m_r_formula = PDDL.substitute(r_formula, pddl"(?m)", m)
        rs = unique!([subst[Var(:R)] for subst in
                      PDDL.satisfiers(domain, state, m_r_formula)])
        map(rs) do r
            PDDL.substitute(formula, PDDL.Subst(pddl"(?m)" => m, pddl"(?r)" => r))
        end
    end
    combine_subgoals = reduce(vcat, combine_subgoals, init=Term[])
    # Construct cook subgoals
    r_formula = pddl"(and (receptacle-type ?rt ?r) (has-cook-method ?m ?rt ?at))"
    formula = pddl"(forall (?f - food) (imply (in-receptacle ?f ?r) (cooked ?m ?f)))"
    cook_subgoals = map(cook_methods) do m
        m_r_formula = PDDL.substitute(r_formula, pddl"(?m)", m)
        rs = unique!([subst[Var(:R)] for subst in
                      PDDL.satisfiers(domain, state, m_r_formula)])
        isempty(rs) && return Term[]
        map(rs) do r
            PDDL.substitute(formula, PDDL.Subst(pddl"(?m)" => m, pddl"(?r)" => r))
        end
    end
    cook_subgoals = reduce(vcat, cook_subgoals, init=Term[])
    return vcat(
        transfer_subgoals,
        vec(combine_subgoals),
        vec(cook_subgoals)
    )
end

"Ground forall-imply subgoal specifications to avoid loopholes."
function ground_forall_subgoal(domain::Domain, state::State, term::Term)
    if term.name != :forall || term.args[2].name != :imply
        return term
    end
    typecond = term.args[1]
    precond = term.args[2].args[1]
    body = term.args[2].args[2]
    conds = PDDL.flatten_conjs(Term[typecond, precond])
    substs = PDDL.satisfiers(domain, state, conds)
    ground_terms = map(substs) do subst
        PDDL.substitute(body, subst)::Term
    end
    if length(ground_terms) == 1
        return ground_terms[1]
    else
        return Compound(:and, ground_terms)
    end
end

## Annotation Segmentation ##

SEGMENTATION_INSTRUCTION = replace("""
For each of the following sentences, repeat the original sentence if it
describes an action that can be performed simultaneously on multiple objects.
Otherwise, if the sentence describes acting sequentially on multiple objects,
rewrite the sentence as multiple sentences (up to four), with one sentence per
line. The following actions *can* be performed simultaneously on multiple
objects: transferring everything from one receptacle to another,
pouring from a receptacle, combining, mixing, or blending multiple
ingredients together, and cooking multiple ingredients in the same
receptacle. In addition, mentions of "everything" should be treated as 
single objects. Keep each rewritten sentence concise, and only mention objects
that are in the original sentence.""", "\n" => " ")

# Replace above with a series of strings concatenated with "*"
SEGMENTATION_INSTRUCTION = 
    "For each of the following sentences, repeat the original sentence if it " *
    "describes an action that can be performed simultaneously on multiple objects.\n\n" *
    "Otherwise, if the sentence describes acting sequentially on multiple objects, " *
    "rewrite the sentence as multiple sentences (up to four), with one sentence " *
    "per line, and with pronouns replaced by the objects they refer to.\n\n" *
    "The following actions *can* be performed simultaneously on multiple objects:\n\n" *
    "  - transferring everything from one receptacle to another\n" *
    "  - pouring from a receptacle\n" *
    "  - combining, mixing, or blending multiple ingredients together\n" *
    "  - cooking multiple ingredients in the same receptacle\n\n" *
    "In addition, mentions of \"everything\" should be treated as a single object.\n\n" *
    "Keep each rewritten sentence concise, and only mention objects that are in " *
    "the original sentence."

"Align segmented annotations with their original annotations."
function align_segmented_annotations(
    seg_annotations::Vector{<:AbstractString},
    orig_times::Vector{Int}, seg_times::Vector{Int}
)
    segments = Vector{eltype(seg_annotations)}[]
    prev_t = 0
    for t in orig_times
        seg = Vector{eltype(seg_annotations)}()
        for (seg_t, seg_annotation) in zip(seg_times, seg_annotations)
            if seg_t > prev_t && seg_t <= t
                push!(seg, seg_annotation)
            end
        end
        push!(segments, seg)
        prev_t = t
    end
    return segments
end
    
"Construct a prompt for segmentation of natural language annotations."
function construct_segmentation_prompt(
    original_examples::Vector{<:AbstractString},
    segmented_examples::Vector{<:Vector{<:AbstractString}},
    test_example = nothing;
    instruction = SEGMENTATION_INSTRUCTION,
    original_label = "Original:",
    segmented_label = "Rewritten:",
    line_break = "\r\n"
)
    prompt = instruction * line_break^2
    for (original, segmented) in zip(original_examples, segmented_examples)
        prompt *= original_label * line_break
        prompt *= " " * original * line_break
        prompt *= segmented_label * line_break
        for s in segmented
            prompt *= " " * s * line_break
        end
        prompt *= line_break
    end
    if !isnothing(test_example)
        prompt *= original_label * line_break
        prompt *= " " * test_example * line_break
        prompt *= segmented_label * line_break
    end
    return prompt
end

"Segment natural language annotations into multiple sentences."
function segment_annotations(
    annotations::Vector{<:AbstractString},
    original_examples::Vector{<:AbstractString},
    segmented_examples::Vector{<:Vector{<:AbstractString}};
    original_label = "Original:",
    segmented_label = "Rewritten:",
    line_break = "\r\n",
    llm = MultiGPT3GF(model="text-davinci-003", temperature=0,
                      stop=original_label, max_tokens=256),
    kwargs...
)
    example_prompt = construct_segmentation_prompt(
        original_examples, segmented_examples;
        original_label, segmented_label, line_break, kwargs...
    )
    prompts = map(annotations) do annotation
        prompt = example_prompt
        prompt *= original_label * line_break
        prompt *= " " * annotation * line_break
        prompt *= segmented_label * line_break
        return prompt
    end
    outputs = llm(prompts)
    delims = unique!(['\n'; collect(line_break)])
    segmented = map(outputs) do output
        split_output = split(output, delims)
        strs = string.(strip.(split_output))
        return filter!(s -> !isempty(s), strs)
    end
    return segmented
end

# Separate examples for each annotation
function segment_annotations(
    annotations::Vector{<:AbstractString},
    original_examples::Vector{<:Vector{<:AbstractString}},
    segmented_examples::Vector{<:Vector{<:Vector{<:AbstractString}}};
    original_label = "Original:",
    segmented_label = "Rewritten:",
    line_break = "\r\n",
    llm = MultiGPT3GF(model="text-davinci-003", temperature=0,
                      stop=original_label, max_tokens=128),
    kwargs...
)
    @assert length(annotations) == length(original_examples)
    @assert length(annotations) == length(segmented_examples)
    prompts = map(enumerate(annotations)) do (i, annotation)
        construct_segmentation_prompt(
            original_examples[i], segmented_examples[i], annotation;
            original_label, segmented_label, line_break, kwargs...
        )
    end
    outputs = llm(prompts)
    delims = unique!(['\n'; collect(line_break)])
    segmented = map(outputs) do output
        split_output = split(output, delims)
        strs = string.(strip.(split_output))
        return filter!(s -> !isempty(s), strs)
    end
    return segmented
end

# Looks up k nearest neighbors in a store as examples
function segment_annotations(
    annotations::Vector{<:AbstractString},
    segmentation_store::DataFrame, k::Int;
    filter_fn = x -> true, reversed = true, kwargs...
)
    original_examples, segmented_examples = select_segmentation_examples(
        annotations, segmentation_store, k; filter_fn, reversed
    )
    return segment_annotations(
        annotations, original_examples, segmented_examples; kwargs...
    )
end

## Embeddings and Prompt Selection ##

LIFT_INSTRUCTION = replace("""
Rewrite the following sentence so that every food or beverage ingredient is
replaced with the placeholder [INGREDIENT]:""", "\n" => " ")

"Construct a store of segmentation examples and their text embeddings."
function construct_segmentation_store(
    original_examples::Vector{<:AbstractString},
    segmented_examples::Vector{<:Vector{<:AbstractString}};
    kitchen_id = -1, problem_id = -1, instance_id = -1
)
    # Convert to vectors
    if !(kitchen_id isa Vector)
        kitchen_id = fill(kitchen_id, length(original_examples))
    end
    if !(problem_id isa Vector)
        problem_id = fill(problem_id, length(original_examples))
    end
    if !(instance_id isa Vector)
        instance_id = fill(instance_id, length(original_examples))
    end
    # Join segmented strings
    segmented_examples = map(segmented_examples) do segmented
        return join(segmented, "\r\n")
    end
    # Compute embeddings
    embedder = GenGPT3.Embedder()
    original_embeddings = embedder(original_examples)
    segmented_embeddings = embedder(segmented_examples)
    # Construct dataframe store
    store = DataFrame(
        kitchen_id = kitchen_id,
        problem_id = problem_id,
        instance_id = instance_id,
        original = original_examples,
        segmented = segmented_examples,
        original_embedding = original_embeddings,
        segmented_embedding = segmented_embeddings
    )
    return store
end

"Read a segmentation store from a CSV file."
function read_segmentation_store(path::AbstractString)
    store = CSV.read(path, DataFrame)
    store.original_embedding = map(store.original_embedding) do str
        parse.(Float64, split(chop(str, head=1),','))
    end
    store.segmented_embedding = map(store.segmented_embedding) do str
        parse.(Float64, split(chop(str, head=1),','))
    end
    return store
end 

"Select k nearest examples to an annotation from a segmentation store."
function select_segmentation_examples(
    annotation::AbstractString, store::DataFrame, k::Int = 5;
    lift = true, lift_instruction = LIFT_INSTRUCTION,
    lift_lm = GPT3GF(model="text-davinci-003", temperature=0,
                     stop="\n", max_tokens=128),
    filter_fn = nothing, reversed = true, deduplicate = true
)
    # Filter rows
    if !isnothing(filter_fn)
        store = filter(filter_fn, store)
    end
    # Lift annotation
    if lift
        prompt = lift_instruction * "\n\n" * annotation * "\n\n"
        prompt *= "Rewritten:" * "\n\n"
        annotation = lift_lm(prompt)
        annotation = strip(annotation)
    end
    # Compute similarity to stored original annotations
    embedder = GenGPT3.Embedder()
    e = embedder(annotation)
    sims = GenGPT3.similarity(e, store.original_embedding)
    idxs = sortperm(sims, rev=true)
    top_k = Int[]
    for i in idxs
        if !deduplicate || store.original[i] ∉ store.original[top_k]
            push!(top_k, i)
        end
        length(top_k) == k && break
    end
    top_k = reversed ? reverse(top_k) : top_k
    original_examples = store.original[top_k]
    segmented_examples = map(store.segmented[top_k]) do s
        split(s, "\r\n")
    end
    return original_examples, segmented_examples
end

"Select k nearest examples to an annotation from a segmentation store."
function select_segmentation_examples(
    annotations::Vector{<:AbstractString},
    store::DataFrame, k::Int = 5;
    lift = true, lift_instruction = LIFT_INSTRUCTION,
    lift_lm = MultiGPT3GF(model="text-davinci-003", temperature=0,
                          stop="\n", max_tokens=128),
    filter_fn = nothing, reversed = true, deduplicate = true
)
    # Filter rows
    if !isnothing(filter_fn)
        store = filter(filter_fn, store)
    end
    # Lift annotations
    if lift
        lift_prompts = map(annotations) do ann
            lift_instruction * "\n\n" * ann * "\n\n" * "Rewritten:" * "\n\n"
        end
        annotations = lift_lm(lift_prompts)
        annotations = strip.(annotations)
    end
    # Compute similarity to stored original annotations
    embedder = GenGPT3.Embedder()
    embeddings = embedder(annotations)
    original_examples = Vector{String}[]
    segmented_examples = Vector{Vector{String}}[]
    for e in embeddings
        sims = GenGPT3.similarity(e, store.original_embedding)
        idxs = sortperm(sims, rev=true)
        top_k = Int[]
        for i in idxs
            if !deduplicate || store.original[i] ∉ store.original[top_k]
                push!(top_k, i)
            end
            length(top_k) == k && break
        end
        top_k = reversed ? reverse(top_k) : top_k
        original = store.original[top_k]
        segmented = map(store.segmented[top_k]) do s
            split(s, "\r\n")
        end
        push!(original_examples, original)
        push!(segmented_examples, segmented)
    end
    return original_examples, segmented_examples
end

"Construct a store of annotated plan examples and their text embeddings."
function construct_annotated_plan_store(
    paths::Vector{<:AbstractString}, verbose_paths::Vector{<:AbstractString};
    kitchen_id = -1, problem_id = -1, instance_id = -1, ann_first = false
)
    # Convert to vectors
    if !(kitchen_id isa Vector)
        kitchen_id = fill(kitchen_id, length(paths))
    end
    if !(problem_id isa Vector)
        problem_id = fill(problem_id, length(paths))
    end
    if !(instance_id isa Vector)
        instance_id = fill(instance_id, length(paths))
    end
    annotations = String[]
    verbose_annotations = String[]
    annotated_plans = String[]
    verbose_annotated_plans = String[]
    for (path, verbose_path) in zip(paths, verbose_paths)
        # Load and construct original annotated plan.
        plan, anns, times = load_plan(path)
        annotated_plan = write_annotated_plan(plan, anns, times)
        push!(annotations, join(anns, "\n"))
        push!(annotated_plans, annotated_plan)
        # Load and construct verbose annotated plan.
        v_plan, v_anns, v_times = load_plan(verbose_path)
        verbose_annotated_plan =
            write_annotated_plan(v_plan, v_anns, v_times, ann_first=true)
        push!(verbose_annotations, join(v_anns, "\n"))
        push!(verbose_annotated_plans, verbose_annotated_plan)
    end
    # Compute embeddings
    embedder = GenGPT3.Embedder()
    embeddings = embedder(annotations)
    verbose_embeddings = embedder(verbose_annotations)
    # Count tokens for annotated plans
    n_plan_tokens = map(annotated_plans) do plan
        length(GenGPT3.tokenize(plan))
    end
    n_verbose_plan_tokens = map(verbose_annotated_plans) do plan
        length(GenGPT3.tokenize(plan))
    end
    # Construct dataframe store
    store = DataFrame(
        kitchen_id = kitchen_id,
        problem_id = problem_id,
        instance_id = instance_id,
        annotations = annotations,
        verbose_annotations = verbose_annotations,
        annotated_plan = annotated_plans,
        verbose_annotated_plan = verbose_annotated_plans,
        annotation_embedding = embeddings,
        verbose_annotation_embedding = verbose_embeddings,
        n_plan_tokens = n_plan_tokens,
        n_verbose_plan_tokens = n_verbose_plan_tokens
    )
    return store
end

"Read a annotated plan store from a CSV file."
function read_annotated_plan_store(path::AbstractString)
    store = CSV.read(path, DataFrame)
    store.annotation_embedding = map(store.annotation_embedding) do str
        parse.(Float64, split(chop(str, head=1),','))
    end
    store.verbose_annotation_embedding = map(store.verbose_annotation_embedding) do str
        parse.(Float64, split(chop(str, head=1),','))
    end
    return store
end 

"Select k nearest examples to a list of annotations from an annotated plan store."
function select_annotated_plan_examples(
    annotations::Vector{<:AbstractString}, store::DataFrame, k::Int = 2;
    filter_fn = nothing, reversed = true
)
    # Filter rows
    if !isnothing(filter_fn)
        store = filter(filter_fn, store)
    end
    # Compute similarity to original annotations
    embedder = GenGPT3.Embedder()
    embedding = embedder(join(annotations, "\n"))
    sims = GenGPT3.similarity(embedding, store.annotation_embedding)
    top_k = sortperm(sims, rev=true)[1:k]
    top_k = reversed ? reverse(top_k) : top_k
    examples = store.annotated_plan[top_k]
    verbose_examples = store.verbose_annotated_plan[top_k]
    n_tokens = store.n_plan_tokens[top_k]
    n_verbose_tokens = store.n_verbose_plan_tokens[top_k]
    return examples, verbose_examples, n_tokens, n_verbose_tokens
end

"Construct a store of annotated action examples and their text embeddings."
function construct_annotated_action_store(
    paths::Vector{<:AbstractString}, verbose_paths::Vector{<:AbstractString};
    kitchen_id = -1, problem_id = -1, instance_id = -1,
    n_annotations_per_sequence = 2
)
    # Convert to vectors
    if !(kitchen_id isa Vector)
        kitchen_id = fill(kitchen_id, length(paths))
    end
    if !(problem_id isa Vector)
        problem_id = fill(problem_id, length(paths))
    end
    if !(instance_id isa Vector)
        instance_id = fill(instance_id, length(paths))
    end
    kitchen_ids = Int[]
    problem_ids = Int[]
    instance_ids = Int[]
    actions = String[]
    annotated_actions = String[]
    verbose_actions = String[]
    annotations = String[]
    verbose_annotations = String[]
    for (k, (path, verbose_path)) in enumerate(zip(paths, verbose_paths))
        # Load original annotated plan.
        plan, anns, times = load_plan(path)
        # Load verbose annotated plan.
        v_plan, v_anns, v_times = load_plan(verbose_path)
        @assert plan == v_plan && times == v_times "Plans must match."
        # Iterate over action sequences (i.e. plan segments)
        for (idx, t) in enumerate(times)
            start_idx = max(idx - n_annotations_per_sequence + 1, 1)
            start_t = start_idx > 1 ? (times[start_idx - 1] + 1) : 1
            sub_plan = plan[start_t:t]
            sub_anns = anns[start_idx:idx]
            sub_v_anns = v_anns[start_idx:idx]
            sub_times = times[start_idx:idx] .- start_t .+ 1
            sub_ann_plan =
                write_annotated_plan(sub_plan, sub_anns, sub_times)
            sub_v_plan =
                write_annotated_plan(sub_plan, sub_v_anns, sub_times, ann_first=true)
            sub_anns = map(start_idx:idx) do i
                "Step $i: " * anns[i]
            end
            sub_v_anns = map(start_idx:idx) do i
                "Step $i: " * v_anns[i]
            end
            push!(actions, join(write_pddl.(sub_plan), "\n"))
            push!(annotated_actions, sub_ann_plan)
            push!(verbose_actions, sub_v_plan)
            push!(annotations, join(sub_anns, "\n"))
            push!(verbose_annotations, join(sub_v_anns, "\n"))
            push!(kitchen_ids, kitchen_id[k])
            push!(problem_ids, problem_id[k])
            push!(instance_ids, instance_id[k])
        end
    end
    # Compute embeddings
    embedder = GenGPT3.Embedder()
    embeddings = embedder(annotations)
    verbose_embeddings = embedder(verbose_annotations)
    # Construct dataframe store
    store = DataFrame(
        kitchen_id = kitchen_ids,
        problem_id = problem_ids,
        instance_id = instance_ids,
        annotations = annotations,
        verbose_annotations = verbose_annotations,
        actions = actions,
        annotated_actions = annotated_actions,
        verbose_actions = verbose_actions,
        annotation_embedding = embeddings,
        verbose_annotation_embedding = verbose_embeddings,
    )
    return store
end

"Read annotated action store from a CSV file."
function read_annotated_action_store(path::AbstractString)
    store = CSV.read(path, DataFrame)
    store.annotation_embedding = map(store.annotation_embedding) do str
        parse.(Float64, split(chop(str, head=1),','))
    end
    store.verbose_annotation_embedding = map(store.verbose_annotation_embedding) do str
        parse.(Float64, split(chop(str, head=1),','))
    end
    return store
end 

"Select k nearest examples to a set of annotations from an annotated action store."
function select_annotated_action_examples(
    annotations::Vector{<:AbstractString}, store::DataFrame, k::Int = 2;
    lift = false, lift_instruction = LIFT_INSTRUCTION,
    lift_lm = MultiGPT3GF(model="text-davinci-003", temperature=0,
                          stop="\n", max_tokens=128),
    filter_fn = nothing, reversed = true
)
    # Filter rows
    if !isnothing(filter_fn)
        store = filter(filter_fn, store)
    end
    # Lift annotations
    if lift
        lift_prompts = map(annotations) do ann
            lift_instruction * "\n\n" * ann * "\n\n" * "Rewritten:" * "\n\n"
        end
        annotations = lift_lm(lift_prompts)
        annotations = strip.(annotations)
    end
    # Compute similarity to stored original annotations
    embedder = GenGPT3.Embedder()
    embedding = embedder(join(annotations, "\n"))
    sims = GenGPT3.similarity(embedding, store.annotation_embedding)
    top_k = sortperm(sims, rev=true)[1:k]
    top_k = reversed ? reverse(top_k) : top_k
    examples = store.annotated_actions[top_k]
    verbose_examples = store.verbose_actions[top_k]
    return examples, verbose_examples
end

"Select k nearest examples to a set of annotations from an annotated action store."
function select_annotated_action_examples(
    annotations::Vector{<:AbstractString}, steps,
    store::DataFrame, k::Int = 2;
    lift = false, lift_instruction = LIFT_INSTRUCTION,
    lift_lm = MultiGPT3GF(model="text-davinci-003", temperature=0,
                          stop="\n", max_tokens=128),
    filter_fn = nothing, reversed = true
)
    # Filter rows
    if !isnothing(filter_fn)
        store = filter(filter_fn, store)
    end
    # Lift annotations
    if lift
        lift_prompts = map(annotations) do ann
            lift_instruction * "\n\n" * ann * "\n\n" * "Rewritten:" * "\n\n"
        end
        annotations = lift_lm(lift_prompts)
        annotations = strip.(annotations)
    end
    # Add steps to annotations
    annotations = map(1:length(annotations)) do i
        "Step $(steps[i]): " * annotations[i]
    end
    # Compute similarity to stored original annotations
    embedder = GenGPT3.Embedder()
    embedding = embedder(join(annotations, "\n"))
    sims = GenGPT3.similarity(embedding, store.annotation_embedding)
    top_k = sortperm(sims, rev=true)[1:k]
    top_k = reversed ? reverse(top_k) : top_k
    examples = store.annotated_actions[top_k]
    verbose_examples = store.verbose_actions[top_k]
    kitchen_ids = store.kitchen_id[top_k]
    problem_ids = store.problem_id[top_k]
    return examples, verbose_examples, kitchen_ids, problem_ids
end

"Construct a store of annotated subgoal examples and their text embeddings."
function construct_annotated_subgoal_store(
    paths::Vector{<:AbstractString};
    kitchen_id = -1, problem_id = -1, instance_id = -1,
    include_count = true
)
    # Convert to vectors
    if !(kitchen_id isa Vector)
        kitchen_id = fill(kitchen_id, length(paths))
    end
    if !(problem_id isa Vector)
        problem_id = fill(problem_id, length(paths))
    end
    if !(instance_id isa Vector)
        instance_id = fill(instance_id, length(paths))
    end
    kitchen_ids = Int[]
    problem_ids = Int[]
    instance_ids = Int[]
    n_subgoals = Int[]
    subgoals_strs = String[]
    annotations = String[]
    annotated_subgoals = String[]
    for (k, path) in enumerate(paths)
        # Load annotated subgoals
        subgoals, anns = load_subgoals(path)
        # Iterate over subgoal-annotation pairs
        for t in eachindex(subgoals)
            subgoals_str = join(write_pddl.(subgoals[t]), "\n")
            ann_subgoals_str =
                write_annotated_subgoals(subgoals[t:t], anns[t:t]; include_count)
            push!(kitchen_ids, kitchen_id[k])
            push!(problem_ids, problem_id[k])
            push!(instance_ids, instance_id[k])
            push!(n_subgoals, length(subgoals[t]))
            push!(subgoals_strs, subgoals_str)
            push!(annotations, anns[t])
            push!(annotated_subgoals, ann_subgoals_str)
        end
    end
    # Compute embeddings
    embedder = GenGPT3.Embedder()
    embeddings = embedder(annotations)
    # Construct dataframe store
    store = DataFrame(
        kitchen_id = kitchen_ids,
        problem_id = problem_ids,
        instance_id = instance_ids,
        n_subgoals = n_subgoals,
        subgoals = subgoals_strs,
        annotations = annotations,
        annotated_subgoals = annotated_subgoals,
        embedding = embeddings,
    )
    return store
end

"Read annotated subgoal store from a CSV file."
function read_annotated_subgoal_store(path::AbstractString)
    store = CSV.read(path, DataFrame)
    store.embedding = map(store.embedding) do str
        parse.(Float64, split(chop(str, head=1),','))
    end
    return store
end 

"Select k nearest examples to an annotation from an annotated subgoal store."
function select_subgoal_examples(
    annotation::AbstractString, store::DataFrame, k::Int = 5;
    lift = false, lift_instruction = LIFT_INSTRUCTION,
    lift_lm = GPT3GF(model="text-davinci-003", temperature=0,
                     stop="\n", max_tokens=64),
    filter_fn = nothing, reversed = true, deduplicate = true
)
    # Filter rows
    if !isnothing(filter_fn)
        store = filter(filter_fn, store)
    end
    # Lift annotation
    if lift
        prompt = lift_instruction * "\n\n" * annotation * "\n\n"
        prompt *= "Rewritten:" * "\n\n"
        annotation = lift_lm(prompt)
        annotation = strip(annotation)
    end
    # Compute similarity to stored original annotations
    embedder = GenGPT3.Embedder()
    e = embedder(annotation)
    sims = GenGPT3.similarity(e, store.embedding)
    idxs = sortperm(sims, rev=true)
    top_k = Int[]
    for i in idxs
        if !deduplicate || store.annotations[i] ∉ store.annotations[top_k]
            push!(top_k, i)
        end
        length(top_k) == k && break
    end
    top_k = reversed ? reverse(top_k) : top_k
    annotated_subgoals = store.annotated_subgoals[top_k]
    subgoals = [parse_pddl.(split(sg, "\n")) for sg in store.subgoals[top_k]]
    annotations = store.annotations[top_k]
    return annotated_subgoals, subgoals, annotations
end
