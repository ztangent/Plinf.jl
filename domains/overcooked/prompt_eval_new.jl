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
    description = join([ingredients_str, receptacles_str, tools_str, appliances_str, prepare_str, combine_str, cook_str], "\n")
    return description
end

"Constructs a recipe description from a PDDL problem."
function construct_recipe_description(
    domain::Domain, problem::Problem
)
    # Extract goal from problem
    goal = PDDL.get_goal(problem)
    # Extract recipe terms
    terms = goal.args[2].args
    # List recipe ingredients
    food_type_terms = filter(x -> x.name == Symbol("food-type"), terms)
    food_type_map = Dict(x.args[2] => x.args[1] for x in food_type_terms)
    ingredients = sort!(string.(map(x -> x.args[1], food_type_terms)))
    ingredients_str = "Ingredients: " * join(ingredients, ", ")
   
    # List preparation steps
    prepare_terms = filter(x -> x.name == Symbol("prepared"), terms)
    prepare_strs = map(prepare_terms) do term
        method = term.args[1]
        food_type = food_type_map[term.args[2]]
        str = "Prepare: $method the $food_type"
        return str
    end
    prepare_str = join(prepare_strs, "\n")

    #List combination steps
    #combine_terms = filter(x -> x.name == Symbol("combine-wtih"), terms)
    #combine  = sort!(string.(map(x -> x.args[1], combine_terms)))
    #combine_str = "Combine: " * join(combine, " the ", ingredients)
   
    # List cooking steps for individually cooked items
    cook_terms = filter(x -> x.name == Symbol("cooked"), terms)
    cook_strs = map(cook_terms) do term
        method = term.args[1]
        food_type = food_type_map[term.args[2]]
        str = "Cook: $method the $food_type"
        return str
    end
    cook_str = join(cook_strs, "\n")

    # List cooking steps for jointly cooked items
    #Depth First Search
    #pull first element 
    # Mark as visited
    # Recursively visit each unvisited element attached to the first
    cook_with_terms = filter(x -> x.name == Symbol("cooked-with"), terms)
    cook_with_strs = map(cook_with_terms) do term
        method = term.args[1]
        food_type = food_type_map[term.args[2]]
        str = "Cook: $method the"

                food_type = food_type_map[term.args[2]]     
        return root

    end
    cook_with_str = join(cook_with_strs, "\n")

    

    return cook_with_str
end

# Load domain and problem 1-1
domain = load_domain(joinpath(@__DIR__, "domain.pddl"))
problem = load_problem(joinpath(@__DIR__, "problem-4-5.pddl"))

s = construct_kitchen_description(domain, problem)
recipe = construct_recipe_description(domain, problem)

# Construct a matrix graph 
graph = [0 1 1;
         1 0 0;
         1 0 0]
graph[1, 2]


findall(x -> x > 0, graph[1, :])

Vertices:
1. cabbage
2. carrot
3. onion
4. potato


ingredients = ["cabbage", "carrot", "onion", "potato"]
idx = findfirst(==("carrot"), ingredients)

# Load domain and problem
domain = load_domain(joinpath(@__DIR__, "domain.pddl"))
problem = load_problem(joinpath(@__DIR__, "problem-4-3.pddl"))
# Extract goal from problem
goal = PDDL.get_goal(problem)
 # Extract recipe terms
terms = goal.args[2].args
print(terms)
# Extract the edges from the recipe terms by using Regex to search for "cooked-with phrase"
edges = filter(x -> x.name == Symbol("cooked-with"), terms)
display(edges)
# List food ingredients
ingredients = filter(x -> x.name == Symbol("food-type"), terms)
ingredients = sort!(map(x -> string(x.args[2]), ingredients))
display(ingredients)
#Pull ingredients from the edges
n = length(ingredients)
graph = falses(n, n)
for e in edges
    ingredient_1 = e.args[2]
    ingredient_2 = e.args[3]
    idx_1 = findfirst(==(string(ingredient_1)), ingredients)
    idx_2 = findfirst(==(string(ingredient_2)), ingredients)
    graph[idx_1, idx_2] = true
    graph[idx_2, idx_1] = true
end


visited = falses(length(ingredients))
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


display(all_components)

display(component)

current_node = pop!(nodes_to_visit)
end




