using PDDL, SymbolicPlanners
using CSV, DataFrames, Dates

include("goal_validation.jl")
include("gpt3_complete.jl")

## Helper functions ##

"Constructs a kitchen description from a PDDL problem."
function construct_kitchen_description(
    domain::Domain, problem::Problem
)
    # Construct initial state
    state = initstate(domain, problem)
    # List food ingredients
    ingredients = sort!(string.(PDDL.get_objects(state, :ftype)))
    ingredients_str = "Ingredients: " * join(ingredients, ", ") 
    # List receptacles
    receptacles = sort!(string.(PDDL.get_objects(state, :rtype)))
    receptacles_str = "Receptacles: " * join(receptacles, ", ")
    # List tools
    tools = sort!(string.(PDDL.get_objects(state, :ttype)))
    tools_str = "Tools: " * join(tools, ", ")
    # List appliances
    # TODO: none when no appliances
    appliances = sort!(string.(PDDL.get_objects(state, :atype)))
    appliances_str = "Appliances: " * join(appliances, ", ")
    # List preparation methods
    query = pddl"(has-prepare-method ?method ?rtype ?ttype)"
    prepare_methods = String[]
    for subst in satisfiers(domain, state, query)
        method = subst[pddl"(?method)"]
        rtype = subst[pddl"(?rtype)"]
        ttype = subst[pddl"(?ttype)"]
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
        method = subst[pddl"(?method)"]
        rtype = subst[pddl"(?rtype)"]
        atype = subst[pddl"(?atype)"]
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
        method = subst[pddl"(?method)"]
        rtype = subst[pddl"(?rtype)"]
        atype = subst[pddl"(?atype)"]
        str = "$method (using $atype with $rtype)"
        push!(cook_methods, str)
    end
    cook_methods = isempty(cook_methods) ?
        "none" :  join(sort!(cook_methods), ", ")
    cook_str = "Cooking Methods: " * cook_methods
    # Concatenate all lines into kitchen description
    kitchen_str = join([ingredients_str, receptacles_str, tools_str, appliances_str, prepare_str, combine_str, cook_str], "\n")
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
    food_type_map = Dict(x.args[2] => x.args[1] for x in food_type_terms)
    ingredient_vars = collect(keys(food_type_map))
    ingredients = sort!(string.(map(x -> x.args[1], food_type_terms)))
    ingredients_str = "Ingredients: " * join(ingredients, ", ", " and ")
    # List preparation steps
    prepare_terms = filter(x -> x.name == Symbol("prepared"), terms)
    prepare_strs = map(prepare_terms) do term
        method = term.args[1]
        food_type = food_type_map[term.args[2]]
        str = "Prepare: $method the $food_type"
        return str
    end
    # List combining steps for individually combined items
    combine_terms = filter(x -> x.name == Symbol("combined"), terms)
    combine_strs = map(combine_terms) do term
        method = term.args[1]
        food_type = food_type_map[term.args[2]]
        str = "Combine: $method the $food_type"
        return str
    end
    # List combining steps for jointly combined items
    combined_with_terms = filter(x -> x.name == Symbol("combined-with"), terms)
    combined_with_methods = unique!([x.args[1] for x in combined_with_terms])
    combined_with_strs = String[]
    for method in combined_with_methods
        edges = filter(x -> x.args[1] == method, combined_with_terms)
        graph = construct_graph(ingredient_vars, edges)
        for component in find_connected_components(graph)
            if length(component) == 1 continue end
            vars = ingredient_vars[component]
            types = sort!([string(food_type_map[v]) for v in vars])
            str = "Combine: $method the " * join(types, ", ", " and ")
            push!(combined_with_strs, str)
        end
    end
    # List cooking steps for individually cooked items
    cook_terms = filter(x -> x.name == Symbol("cooked"), terms)
    cook_strs = map(cook_terms) do term
        method = term.args[1]
        food_type = food_type_map[term.args[2]]
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
        for component in find_connected_components(graph)
            vars = ingredient_vars[component]
            types = sort!([string(food_type_map[v]) for v in vars])
            str = "Cook: $method the " * join(types, ", ", " and ")
            push!(cooked_with_strs, str)
        end
    end
    # List serving receptacle
    receptacle_type_terms = filter(x -> x.name == Symbol("receptacle-type"), terms)
    receptacle = string(receptacle_type_terms[1].args[1])
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
            desc = read(path[1:end-5] * ".txt", String)
            m = match(r"Goal:\n([\n\s\w\-;,\(\).]*)[\w\s]*", desc)
            desc = isnothing(m) ? error("English goal description not found") : m.captures[1]
            return construct_recipe_description(domain, prob, desc)
        end
        str = "KITCHEN: $(uppercase(name))\n\n" * kitchen * "\n\nRECIPES\n\n" * join(recipes, "\n\n")
        prompt *= str * "\n\n"
    end
    return prompt
end

## Test kitchen and recipe construction
domain = load_domain(joinpath(@__DIR__, "domain.pddl"))
problem = load_problem(joinpath(@__DIR__, "problem-4-5.pddl"))

kitchen = construct_kitchen_description(domain, problem)
recipe = construct_recipe_description(domain, problem)

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

