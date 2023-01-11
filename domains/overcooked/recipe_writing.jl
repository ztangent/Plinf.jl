## Code for writing English descriptions given PDDL inputs

using PDDL

"Constructs a kitchen description from a PDDL problem."
function construct_kitchen_description(domain::Domain, state::State)
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
    combine_str = "Combination Methods: " * combine_methods
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
construct_kitchen_description(domain::Domain, problem::Problem) =
    construct_kitchen_description(domain, initstate(domain, problem))

"Constructs a recipe description from a PDDL problem."
function construct_recipe_description(goal::Term, description="")   
    # Construct description string / flavor text
    description = "Description: $description"
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

construct_recipe_description(domain::Domain, problem::Problem, description="") =
    construct_recipe_description(PDDL.get_goal(problem), description)

"Construct adjacency matrix of ingredient graph for a particular relation."
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

"Find connected components in an adjacency matrix."
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

"Convert PDDL constant to string, replacing dashes with spaces."
function const_to_str(x::Const)
    return replace(string(x), "-" => " ")
end

"Loads the English description / summary for a recipe / goal."
function load_english_recipe_description(path::AbstractString)
    description = read(path, String)
    m = match(r"Goal:\r?\n([\n\s\w\-;,\(\).]*)[\w\s]*", description)
    description = isnothing(m) ? error("English recipe description not found") : m.captures[1]
    return description
end

## Test kitchen and recipe construction
# domain = load_domain(joinpath(@__DIR__, "domain.pddl"))
# problem = load_problem(joinpath(@__DIR__, "problem-4-5.pddl"))
# description = load_english_recipe_description(joinpath(@__DIR__, "problem-4-5.txt"))

# kitchen = construct_kitchen_description(domain, problem)
# recipe = construct_recipe_description(domain, problem, description)
