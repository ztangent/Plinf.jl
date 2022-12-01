using PDDL
using CSV, DataFrames, Dates

include("gpt3_complete.jl")
include("goal_validation.jl")

## Recipe parsing and validation ##

"Parse recipe string as a PDDL goal, checking if it is a valid PDDL formula."
function parse_recipe(str::AbstractString)
    lines = split(strip(str), "\n")
    terms = Term[] 

    # Parse English description
    description_str = lines[1]
    m = match(r"Description: (.*)", description_str)
    description = m.captures[1]

    # Parse ingredients
    ingredients_str = lines[2]
    m = match(r"Ingredients: (.*)", ingredients_str)
    ingredients = split(m.captures[1], ", ")
    final_ingredients = split(pop!(ingredients), " and ")
    append!(ingredients, final_ingredients)
    ingredients = map(x -> replace(x, " " => "-"), ingredients)
    food_types = map(x -> Const(Symbol(x)), ingredients)
    food_vars = map(x -> Var(Symbol(uppercasefirst(x))), ingredients)
    # Construct food type declarations
    for (type, var) in zip(food_types, food_vars)
        term = Compound(Symbol("food-type"), Term[type, var])
        push!(terms, term)
    end

    # Parse receptacle
    m = match(r"Serve: (?:in|on|upon) (?:a|an) (.+)", lines[end])
    receptacle = m.captures[1]
    # Construct receptacle type declaration
    r_type = Const(Symbol(receptacle))
    r_var = Var(Symbol(uppercasefirst(receptacle)))
    push!(terms, Compound(Symbol("receptacle-type"), Term[r_type, r_var]))

    # Loop over remaining lines
    for line in lines[3:end-1]
        m = match(r"(\w+): (.*)", line)
        step_type = m.captures[1]
        if step_type == "Prepare"
            term = parse_prepare_step(m.captures[2])
            push!(terms, term)
        elseif step_type == "Combine"
            combine_terms = parse_combine_step(m.captures[2])
            append!(terms, combine_terms)
        elseif step_type == "Cook"
            cook_terms = parse_cook_step(m.captures[2])
            append!(terms, cook_terms)
        else
            error("Unrecognized step type")
        end
    end

    # Add in-receptacle terms
    for var in food_vars
        term = Compound(Symbol("in-receptacle"), Term[var, r_var])
        push!(terms, term)
    end

    # Construct type conditions
    typeconds = Term[Compound(:food, Term[var]) for var in food_vars]
    push!(typeconds, Compound(:receptacle, Term[r_var]))

    # Wrap in existential quantifier
    goal = Compound(:exists, Term[Compound(:and, typeconds),
                                  Compound(:and, terms)])

    return goal, description
end

function parse_prepare_step(str::AbstractString)
    method, ingredient = split(str, " the ")
    method = Const(Symbol(method))
    ingredient = replace(ingredient, " " => "-")
    var = Var(Symbol(uppercasefirst(ingredient)))
    return Compound(:prepared, Term[method, var])
end

function parse_combine_step(str::AbstractString)
    method, ingredients = split(str, " the ")
    # Parse method    
    method = Const(Symbol(method))
    # Parse ingredients
    ingredients = split(ingredients, ", ")
    final_ingredients = split(pop!(ingredients), " and ")
    append!(ingredients, final_ingredients)
    ingredients = map(x -> replace(x, " " => "-"), ingredients)
    food_vars = map(x -> Var(Symbol(uppercasefirst(x))), ingredients)

    # Handle single ingredient case
    if length(food_vars) == 1
        term = Compound(:combined, Term[method, food_vars[1]])
        return Term[term]
    end

    # Handle multi-ingredient case
    terms = Term[]
    for i in 1:(length(food_vars)-1)
        var1, var2 = food_vars[i], food_vars[i+1]
        term = Compound(Symbol("combined-with"), Term[method, var1, var2])
        push!(terms, term)
    end
    return terms
end

function parse_cook_step(str::AbstractString)
    method, ingredients = split(str, " the ")
    # Parse method    
    method = Const(Symbol(method))
    # Parse ingredients
    ingredients = split(ingredients, ", ")
    final_ingredients = split(pop!(ingredients), " and ")
    append!(ingredients, final_ingredients)
    ingredients = map(x -> replace(x, " " => "-"), ingredients)
    food_vars = map(x -> Var(Symbol(uppercasefirst(x))), ingredients)

    # Handle single ingredient case
    if length(food_vars) == 1
        term = Compound(:cooked, Term[method, food_vars[1]])
        return Term[term]
    end

    # Handle multi-ingredient case
    terms = Term[]
    for i in 1:(length(food_vars)-1)
        var1, var2 = food_vars[i], food_vars[i+1]
        term = Compound(Symbol("cooked-with"), Term[method, var1, var2])
        push!(terms, term)
    end
    return terms
end

"Tries to parse a recipe to PDDL, returns nothing upon failure."
function try_parse_recipe(str::AbstractString)
    try
        return parse_recipe(str)
    catch e
        return nothing
    end
end

"Validates a generated recipe string with several checks."
function validate_recipe_string(
    str::AbstractString, domain::Domain, state::State;
    verbose::Bool=false
)
    # Check if recipe parses to PDDL formula
    result = try_parse_recipe(str)
    if isnothing(result)
        reason = "Parse error"
        if verbose println("Validation Failed: $reason") end
        return (false, reason)
    end
    goal, _ = result
    if verbose println("Validation: Goal Parsed") end
    return validate_goal(goal, domain, state, verbose=verbose)
end

## Prompt generation functions ##

"Convert PDDL constant to string, replacing dashes with spaces."
function const_to_str(x::Const)
    return replace(string(x), "-" => " ")
end

"Constructs a kitchen description from a PDDL problem."
function construct_kitchen_description(
    domain::Domain, problem::Problem
)
    # Construct initial state
    state = initstate(domain, problem)
    # List food ingredients
    ingredients = sort!(const_to_str.(PDDL.get_objects(state, :ftype)))
    ingredients_str = "Ingredients: " * join(ingredients, ", ") 
    # List receptacles
    receptacles = sort!(const_to_str.(PDDL.get_objects(state, :rtype)))
    receptacles = isempty(receptacles) ? "none" : join(receptacles, ", ")
    receptacles_str = "Receptacles: " * receptacles
    # List tools
    tools = sort!(const_to_str.(PDDL.get_objects(state, :ttype)))
    tools = isempty(tools) ? "none" : join(tools, ", ")
    tools_str = "Tools: " * tools
    # List appliances
    appliances = sort!(const_to_str.(PDDL.get_objects(state, :atype)))
    appliances = isempty(appliances) ? "none" : join(appliances, ", ")
    appliances_str = "Appliances: " * appliances
    # List preparation methods
    query = pddl"(has-prepare-method ?method ?rtype ?ttype)"
    prepare_methods = String[]
    for subst in satisfiers(domain, state, query)
        method = subst[pddl"(?method)"] |> const_to_str
        rtype = subst[pddl"(?rtype)"] |> const_to_str
        ttype = subst[pddl"(?ttype)"] |> const_to_str
        str = "$method (using $ttype with $rtype)"
        push!(prepare_methods, str)
    end
    prepare_methods = isempty(prepare_methods) ?
        "none" :  join(sort!(prepare_methods), ", ")
    prepare_str = "Preparation Methods: " * prepare_methods
    # List combination methods
    query = pddl"(has-combine-method ?method ?rtype ?atype)"
    combine_methods = String[]
    for subst in satisfiers(domain, state, query)
        method = subst[pddl"(?method)"] |> const_to_str
        rtype = subst[pddl"(?rtype)"] |> const_to_str
        atype = subst[pddl"(?atype)"] |> const_to_str
        str = "$method (using $atype with $rtype)"
        push!(combine_methods, str)
    end
    combine_methods = isempty(combine_methods) ?
        "none" :  join(sort!(combine_methods), ", ")
    combine_str = "Combinination Methods: " * combine_methods
    # List cooking methods
    query = pddl"(has-cook-method ?method ?rtype ?atype)"
    cook_methods = String[]
    for subst in satisfiers(domain, state, query)
        method = subst[pddl"(?method)"] |> const_to_str
        rtype = subst[pddl"(?rtype)"] |> const_to_str
        atype = subst[pddl"(?atype)"] |> const_to_str
        str = "$method (using $atype with $rtype)"
        push!(cook_methods, str)
    end
    cook_methods = isempty(cook_methods) ?
        "none" :  join(sort!(cook_methods), ", ")
    cook_str = "Cooking Methods: " * cook_methods
    # Concatenate all lines into kitchen description
    kitchen_str = join([ingredients_str, receptacles_str, 
                        tools_str, appliances_str,
                        prepare_str, combine_str, cook_str], "\n")
    return kitchen_str
end

"Constructs a recipe description from a PDDL problem."
function construct_recipe_description(
    domain::Domain, problem::Problem, description::AbstractString=""
)   
    # Construct description string
    description = "Description: $description"
    # Extract goal from problem
    goal = PDDL.get_goal(problem)
    # Extract recipe terms
    terms = goal.args[2].args
    # List recipe ingredients
    food_type_terms = filter(x -> x.name == Symbol("food-type"), terms)
    food_var_map = Dict(x.args[2] => const_to_str(x.args[1])
                         for x in food_type_terms)
    ingredient_vars = collect(keys(food_var_map))
    ingredients = sort!(collect(values(food_var_map)))
    ingredients_str = "Ingredients: " * join(ingredients, ", ", " and ")
    # List preparation steps
    prepare_terms = filter(x -> x.name == Symbol("prepared"), terms)
    prepare_strs = map(prepare_terms) do term
        method = term.args[1] |> const_to_str 
        ingredient = food_var_map[term.args[2]]
        str = "Prepare: $method the $ingredient"
        return str
    end
    # List combining steps for individually combined items
    combine_terms = filter(x -> x.name == Symbol("combined"), terms)
    combine_strs = map(combine_terms) do term
        method = term.args[1] |> const_to_str
        ingredient = food_var_map[term.args[2]]
        str = "Combine: $method the $ingredient"
        return str
    end
    # List combining steps for jointly combined items
    combined_with_terms = filter(x -> x.name == Symbol("combined-with"), terms)
    combined_with_methods = unique!([x.args[1] for x in combined_with_terms])
    combined_with_strs = String[]
    for method in combined_with_methods
        edges = filter(x -> x.args[1] == method, combined_with_terms)
        graph = construct_graph(ingredient_vars, edges)
        method = const_to_str(method)
        for component in find_connected_components(graph)
            if length(component) == 1 continue end
            vars = ingredient_vars[component]
            ingredients = sort!([food_var_map[v] for v in vars])
            str = "Combine: $method the " * join(ingredients, ", ", " and ")
            push!(combined_with_strs, str)
        end
    end
    # List cooking steps for individually cooked items
    cook_terms = filter(x -> x.name == Symbol("cooked"), terms)
    cook_strs = map(cook_terms) do term
        method = term.args[1] |> const_to_str
        food_type = food_var_map[term.args[2]]
        str = "Cook: $method the $food_type"
        return str
    end
    # List cooking steps for jointly cooked items
    cooked_with_terms = filter(x -> x.name == Symbol("cooked-with"), terms)
    cooked_with_methods = unique!([x.args[1] for x in cooked_with_terms])
    cooked_with_strs = String[]
    for method in cooked_with_methods
        edges = filter(x -> x.args[1] == method, cooked_with_terms)
        graph = construct_graph(ingredient_vars, edges)
        method = const_to_str(method)
        for component in find_connected_components(graph)
            if length(component) == 1 continue end
            vars = ingredient_vars[component]
            ingredients = sort!([food_var_map[v] for v in vars])
            str = "Cook: $method the " * join(ingredients, ", ", " and ")
            push!(cooked_with_strs, str)
        end
    end
    # List serving receptacle
    receptacle_term = filter(x -> x.name == Symbol("receptacle-type"), terms)[1]
    receptacle = const_to_str(receptacle_term.args[1])
    receptacle_str = "Serve: in a $receptacle"
    # Concatenate all lines into recipe description
    recipe_str = join([[description, ingredients_str];
                        prepare_strs;
                        combine_strs; combined_with_strs;
                        cook_strs; cooked_with_strs;
                        [receptacle_str]], "\n")
    return recipe_str
end

function construct_graph(ingredients, edges)
    n = length(ingredients)
    graph = falses(n, n)
    for e in edges
        ingredient_1 = e.args[2]
        ingredient_2 = e.args[3]
        idx_1 = findfirst(==(ingredient_1), ingredients)
        idx_2 = findfirst(==(ingredient_2), ingredients)
        graph[idx_1, idx_2] = true
        graph[idx_2, idx_1] = true
    end
    return graph
end

function find_connected_components(graph::BitMatrix)
    visited = falses(size(graph)[1])
    all_components = []
    # Loop until every node is visited
    while !all(visited)
        root = findfirst(==(false), visited)
        stack = [root]
        component = Int[]
        while !isempty(stack)
            # Pop first node from the stack
            node = pop!(stack)
            visited[node] = true
            push!(component, node)
            # Iterate through the adjacent nodes
            neighbors = findall(graph[node, :])
            for x in neighbors
                if !visited[x]
                    push!(stack, x)
                end
            end
        end
        sort!(component)
        push!(all_components, component)
    end
    return all_components
end    

function construct_multikitchen_prompt(domain::Domain, problem_sets, kitchen_names)
    prompt = ""
    for (problem_paths, name) in zip(problem_sets, kitchen_names)
        reference_problem = load_problem(problem_paths[end])
        kitchen = construct_kitchen_description(domain, reference_problem)
        recipes = map(problem_paths) do path
            prob = load_problem(path)
            desc_path = path[1:end-5] * ".txt"
            desc = load_english_recipe_description(desc_path)
            return construct_recipe_description(domain, prob, desc)
        end
        str = "KITCHEN: $(uppercase(name))\n\n" * kitchen * "\n\nRECIPES\n\n" * join(recipes, "\n\n")
        prompt *= str * "\n\n"
    end
    return prompt
end

function load_english_recipe_description(path::AbstractString)
    description = read(path, String)
    m = match(r"Goal:\r?\n([\n\s\w\-;,\(\).]*)[\w\s]*", description)
    description = isnothing(m) ? error("English recipe description not found") : m.captures[1]
    return description
end

## Test kitchen and recipe construction
domain = load_domain(joinpath(@__DIR__, "domain.pddl"))
problem = load_problem(joinpath(@__DIR__, "problem-4-5.pddl"))
description = load_english_recipe_description(joinpath(@__DIR__, "problem-4-5.txt"))

kitchen = construct_kitchen_description(domain, problem)
recipe = construct_recipe_description(domain, problem, description)

## Construct multi-kitchen prompt from last two problems of each kitchen

prompt = construct_multikitchen_prompt(
    domain,
    [
        [joinpath(@__DIR__, "problem-1-4.pddl"), joinpath(@__DIR__, "problem-1-5.pddl")],
        [joinpath(@__DIR__, "problem-2-4.pddl"), joinpath(@__DIR__, "problem-2-5.pddl")],
        [joinpath(@__DIR__, "problem-3-4.pddl"), joinpath(@__DIR__, "problem-3-5.pddl")],
        [joinpath(@__DIR__, "problem-4-4.pddl"), joinpath(@__DIR__, "problem-4-5.pddl")],
        [joinpath(@__DIR__, "problem-5-4.pddl"), joinpath(@__DIR__, "problem-5-5.pddl")],
    ],
    ["salad bar", "sushi bar", "delicatassen", "pizzeria", "patisserie"]
)

## Script options ##

# Kitchen names
KITCHEN_NAMES = [
    "salad bar", 
    "sushi bar",
    "delicatassen",
    "pizzeria",
    "patisserie"
]

# Paths to problems used in prompt generation
PROMPT_PROBLEMS = [
    ["problem-1-3.pddl", "problem-1-4.pddl", "problem-1-5.pddl"],
    ["problem-2-3.pddl", "problem-2-4.pddl", "problem-2-5.pddl"],
    ["problem-3-3.pddl", "problem-3-4.pddl", "problem-3-5.pddl"],
    ["problem-4-3.pddl", "problem-4-4.pddl", "problem-4-5.pddl"],
    ["problem-5-3.pddl", "problem-5-4.pddl", "problem-5-5.pddl"],
]
PROMPT_PROBLEMS = [joinpath.(@__DIR__, pset) for pset in PROMPT_PROBLEMS]

# Paths to problems to test goal generation on
TEST_PROBLEMS = [
    ["problem-1-1.pddl", "problem-1-2.pddl", "problem-1-3.pddl", "problem-1-4.pddl", "problem-1-5.pddl"],
    ["problem-2-1.pddl", "problem-2-2.pddl", "problem-2-3.pddl", "problem-2-4.pddl", "problem-2-5.pddl"],
    ["problem-3-1.pddl", "problem-3-2.pddl", "problem-3-3.pddl", "problem-3-4.pddl", "problem-3-5.pddl"],
    ["problem-4-1.pddl", "problem-4-2.pddl", "problem-4-3.pddl", "problem-4-4.pddl", "problem-4-5.pddl"],
    ["problem-5-1.pddl", "problem-5-2.pddl", "problem-5-3.pddl", "problem-5-4.pddl", "problem-5-5.pddl"],
]
TEST_PROBLEMS = [joinpath.(@__DIR__, pset) for pset in TEST_PROBLEMS]

# Number of completions per prompt
N_REPEATS = 10

# Temperature of generated completion
TEMPERATURE = 1.0

# Initialize data frame
df = DataFrame(
    kitchen_id=Int[],
    kitchen_name=String[],
    problem=String[],
    description=String[],
    prompt=String[],
    temperature=Float64[],
    completion=String[],
    pddl_goal=String[],
    eng_goal=String[],
    parse_success=Bool[],
    valid=Bool[],
    reason=String[]
)
df_types = eltype.(eachcol(df))
datetime = Dates.format(Dates.now(), "yyyy-mm-ddTHH-MM-SS")
df_path = joinpath(@__DIR__, "prompt_eval_multi_$(datetime).csv")

# Load domain
domain = load_domain(joinpath(@__DIR__, "domain.pddl"))

# Iterate over kitchen types
for (idx, kitchen_name) in enumerate(KITCHEN_NAMES)
    println("== Kitchen $idx : $kitchen_name ==")

    # Iterate over test problems for each kitchen type
    for problem_path in TEST_PROBLEMS[idx]
        println("-- Problem: $(basename(problem_path)) --")

        # Load problem and construct initial state
        problem = load_problem(problem_path)
        state = initstate(domain, problem)

        # Construct multi-kitchen context from context problems
        train_idxs = filter(!=(idx), 1:length(PROMPT_PROBLEMS))
        train_names = KITCHEN_NAMES[train_idxs]
        train_problems = PROMPT_PROBLEMS[train_idxs]
        context = construct_multikitchen_prompt(domain, train_problems, train_names)

        # Construct kitchen description for test problem
        kitchen_desc = construct_kitchen_description(domain, problem)

        # Construct prompt from context and kitchen description
        prompt = (context * "KITCHEN: $(uppercase(kitchen_name))\n\n" *
                  kitchen_desc * "\n\nRECIPES\n\nDescription:")
        
        println() 
        println("Prompt:\n")
        println(prompt)

        # Send prompt to GPT3 and get response
        println("---")
        println("Requesting $N_REPEATS completions through OpenAI API...")
        response = nothing
        while isnothing(response)
            try
                response = gpt3_complete(prompt, N_REPEATS, stop="Description:",
                                         temperature=TEMPERATURE, verbose=true)
            catch e
                println("Error with API request, waiting 2 seconds to retry...")
                sleep(2.0)
            end
        end
        println("---")

        # Iterate over multiple completions
        for (i, choice) in enumerate(response.choices)
            # Extract completion text
            completion = choice.text 
            completion = strip("Description:" * completion)
            println("-- Completion $i--")
            println(completion)
            # Try to parse to PDDL and English description
            result = try_parse_recipe(completion)
            if isnothing(result)
                pddl_goal, eng_goal = "", ""
                parse_success = false
            else
                pddl_goal, eng_goal = result
                pddl_goal = write_pddl(pddl_goal)
                parse_success = true
            end
            # Check if generated recipe is valid
            println()
            valid, reason =
                validate_recipe_string(completion, domain, state; verbose=true)
            println()
            println("Goal Validity: $valid")
            println("Validation Reason: $reason")
            println()
            row = Dict(
                :kitchen_id => idx,
                :kitchen_name => kitchen_name,            
                :problem => basename(problem_path),
                :description => kitchen_desc,
                :prompt => prompt,
                :completion => completion,
                :pddl_goal => pddl_goal,
                :eng_goal => eng_goal,
                :temperature => TEMPERATURE,
                :parse_success => parse_success,
                :valid => valid,
                :reason => reason
            )
            push!(df, row)
        end
        CSV.write(df_path, df)
        println()
        println("Sleeping for 10s to avoid rate limit...")
        sleep(10.0)

        println()
    end
end
