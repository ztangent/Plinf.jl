
using HTTP, JSON3

function gpt3_complete(
    prompt::String, n_completions::Int=1;
    endpoint::String = "https://api.openai.com/v1/completions",
    api_key::String = get(ENV, "OPENAI_API_KEY", ""),
    model::String = "text-davinci-002",
    temperature::Real = 0.7,
    max_tokens::Int = 2560,
    logprobs::Union{Nothing,Int} = nothing,
    echo::Bool = false,
    stop::Union{String, Vector{<:String}} = "<|endoftext|>",
    verbose::Bool = false,
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
    data = JSON3.write(data)
    if verbose
        println("Posting HTTP request...")
    end
    response = HTTP.post(endpoint, headers, data,
                         readtimeout=30, connect_timeout = 30)
    return JSON3.read(response.body)
end
