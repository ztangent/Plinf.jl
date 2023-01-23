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

"Extract ingredient variables or objects from a recipe formula."
function extract_ingredients(recipe::Term)
    if recipe.name == :exists
        terms = recipe.args[2].args
        food_type_terms = filter(x -> x.name == Symbol("food-type"), terms)
        ingredients = [term.args[2] for term in food_type_terms]
    else
        terms = PDDL.flatten_conjs(recipe)
        in_receptacle_terms = filter(x -> x.name == Symbol("in-receptacle"), terms)
        ingredients = [term.args[1] for term in in_receptacle_terms]
    end
    return ingredients
end

"Extract ingredient clusters that are cooked or combined together."
function extract_ingredient_clusters(
    ingredients::AbstractVector{<:Term},
    terms::AbstractVector{<:Term},
    predicate_name::Symbol
)
    terms = filter(terms) do term
        term.name == predicate_name
    end
    methods = unique!([x.args[1] for x in terms])
    all_cluster_ingredients = Vector{eltype(ingredients)}[]
    all_cluster_terms = Vector{Term}[]
    for method in methods
        edges = filter(x -> x.args[1] == method, terms)
        graph = construct_graph(ingredients, edges)
        for component in find_connected_components(graph)
            if length(component) == 1 continue end
            cluster_ingredients = ingredients[component]
            cluster_terms = filter(edges) do e
                e.args[2] in cluster_ingredients &&
                e.args[3] in cluster_ingredients
            end
            push!(all_cluster_ingredients, cluster_ingredients)
            push!(all_cluster_terms, cluster_terms)
        end
    end
    return all_cluster_ingredients, all_cluster_terms
end

function extract_ingredient_clusters(recipe::Term, predicate_name::Symbol)
    ingredients = extract_ingredients(recipe)
    terms = recipe.name == :exists ?
        recipe.args[2].args : PDDL.flatten_conjs(recipe)
    return extract_ingredient_clusters(ingredients, terms, predicate_name)
end

