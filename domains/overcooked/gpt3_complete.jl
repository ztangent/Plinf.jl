
using HTTP, JSON3

"Call the OpenAI JSON API for GPT-3 and return the results."
function gpt3_complete(
    prompt::String, n_completions::Int=1;
    endpoint::String = "https://api.openai.com/v1/completions",
    api_key::String = get(ENV, "OPENAI_API_KEY", ""),
    model::String = "text-davinci-003",
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
    return isempty(logprobs) ? 0.0 : sum(logprobs)
end