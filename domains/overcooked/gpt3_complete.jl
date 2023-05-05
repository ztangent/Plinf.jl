
using HTTP, JSON3
using GenGPT3

"Call the OpenAI JSON API for GPT-3 and return the results."
function gpt3_complete(
    prompt, n_completions::Int=1;
    endpoint::String = "https://api.openai.com/v1/completions",
    api_key::String = get(ENV, "OPENAI_API_KEY", ""),
    model::String = "text-davinci-002",
    temperature::Real = 1.0,
    max_tokens::Int = 2048,
    logprobs::Union{Nothing,Int} = 0,
    echo::Bool = false,
    stop::Union{String, Nothing} = nothing,
    persistent::Bool = true,
    verbose::Bool = false,
    logit_bias = nothing,
    options... # Other options
)
    headers = ["Content-Type" => "application/json",
               "Authorization" => "Bearer $api_key"]
    data = Dict("prompt" => prompt,
                "n" => n_completions,
                "model" => model,
                "temperature" => temperature,
                "max_tokens" => max_tokens,
                "logprobs" => logprobs,
                "echo" => echo,
                "stop" => stop, options...)
    # Prevent <|endoftext|> from being generated when using custom stop tokens
    if !isnothing(stop)
        logit_bias = isnothing(logit_bias) ? Dict{Int,Float64}() : logit_bias 
        logit_bias[50256] = -100.0
    end
    if !isnothing(logit_bias)
        data["logit_bias"] = logit_bias
    end            
    data = JSON3.write(data)
    if persistent 
        response = nothing
        delay = 1.0
        while isnothing(response)
            try
                if verbose
                    println("Posting HTTP request...")
                end
                response = HTTP.post(endpoint, headers, data)
            catch e
                if verbose
                    println("Error with API request, " * 
                            "waiting $delay seconds to retry...")
                end
                sleep(delay)
                delay = min(delay * 2.0, 64.0) # Increase delay each time
            end
        end
    else
        response = HTTP.post(endpoint, headers, data)
    end
    return JSON3.read(response.body)
end

"Make multiple requests to the OpenAI API to reach completion quota."
function gpt3_batch_complete(
    prompt::String, n_completions::Int=1, batch_size::Int=10;
    verbose::Bool=false, options...
)
    n_remaining = n_completions
    completions = JSON3.Object[]
    while n_remaining > 0
        n_request = min(n_remaining, batch_size)
        if verbose
            println("Requesting $n_request completions ($n_remaining remaining)...")
        end
        response = gpt3_complete(prompt, n_request; verbose=verbose, options...)
        append!(completions, response.choices)
        n_remaining -= n_request
    end
    return completions
end

"Make batched requests to the OpenAI API to reach prompt quota."
function gpt3_multi_prompt_api_call(
    prompts::AbstractVector{<:Union{AbstractString, AbstractVector{Int}}};
    batch_size::Int=min(length(prompts), 16),
    verbose::Bool=false,
    options...
)
    n_remaining = length(prompts)
    choices = JSON3.Object[]
    for batch in Iterators.partition(prompts, batch_size)
        n_request = length(batch)
        n_remaining -= n_request
        if verbose
            println("Making $n_request requests ($n_remaining remaining)...")
        end
        response = gpt3_complete(batch; verbose=verbose, options...)
        n_received = length(choices)
        resize!(choices, n_received + n_request)
        for choice in response.choices
            idx = n_received + choice.index + 1
            choices[idx] = choice
        end
    end
    return choices
end

"Find the index of a completion's last token, including the stop sequence."
function find_stop_index(completion, n_stop_tokens::Int=1)
    if completion.finish_reason == "length"
        return length(completion.logprobs.tokens)
    elseif completion.finish_reason == "stop"
        text_offsets = completion.logprobs.text_offset  
        last_offset = text_offsets[end]
        first_stop_idx = findfirst(==(last_offset), text_offsets)
        last_stop_idx = first_stop_idx + n_stop_tokens - 1
        return last_stop_idx
    end
end

"Extract total log probability of a completion."
function extract_logprobs(completion, n_stop_tokens::Int=1)
    stop_idx = find_stop_index(completion, n_stop_tokens)
    logprobs = completion.logprobs.token_logprobs[1:stop_idx]
    if isempty(logprobs) 
        return 0.0
    elseif logprobs[1] !== nothing
        return sum(logprobs)
    else
        return sum(logprobs[2:end])
    end
end

"Extract tokens and logprobs in a completion until a stop condition."
function extract_tokens_until_stop(completion, stop_condition)
    n_total = length(completion.logprobs.tokens)
    i = 1
    while i < n_total
        tokens = view(completion.logprobs.tokens, 1:i)
        stop_condition(tokens) && break
        i += 1
    end
    tokens = completion.logprobs.tokens[1:i]
    logprobs = completion.logprobs.token_logprobs[1:i]
    return tokens, logprobs
end

"Return the log probabilities of list of completions after a specified prompt."
function gpt3_eval_completion_logprobs(
    prompt::String, completions;
    verbose=false, options... # Other options
)
    # Construct texts to evaluate
    strs = [prompt * s for s in completions]
    # Send to OpenAI API for evaluation
    choices = gpt3_multi_prompt_api_call(strs; 
        logprobs=0, max_tokens=0, echo=true,
        verbose=verbose, options...
    )
    n_prompt_tokens = length(GenGPT3.tokenize(prompt))
    # Extract logprobs
    logprobs = map(choices) do choice
        return sum(choice.logprobs.token_logprobs[n_prompt_tokens+1:end])
    end
    return logprobs
end

"Return the (relative) log probabilities of next tokens after a prompt."
function gpt3_eval_next_token_logprobs(
    prompt::String, next_tokens::AbstractVector{<:AbstractString};
    verbose=false, options... # Other options
)
    # Get token IDs for next tokens
    next_tokens = map(next_tokens) do str
        str_tokens = GenGPT3.tokenize(str)
        if length(str_tokens) != 1
            error("\"$str\" is not a single token.")
        end
        return str_tokens[1]
    end
    token_ids = GenGPT3.encode(next_tokens)
    next_tokens = GenGPT3.detokenize.([[t] for t in next_tokens])
    # Create logit bias dictionary from tokens
    logit_bias = Dict(string(id) => 100.0 for id in token_ids)
    # Send to OpenAI API for evaluation
    resp = gpt3_complete(prompt; logprobs=5, max_tokens=1, echo=false,
                         logit_bias=logit_bias, verbose=verbose, options...)
    # Extract logprobs
    top_logprobs = resp.choices[1].logprobs.top_logprobs[1]
    sum_probs = sum(exp.(values(top_logprobs)))
    n_missing = length(GenGPT3.GPT_VOCAB_LIST) - length(top_logprobs)
    log_mean_missing_prob = log(max(0, (1.0 - sum_probs) / n_missing))
    logprobs = map(next_tokens) do token
        return get(top_logprobs, token, log_mean_missing_prob)
    end
    return logprobs
end
