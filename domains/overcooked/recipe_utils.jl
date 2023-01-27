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

"Extract and Skolemize variables with food or receptacle type declarations."
function extract_and_skolemize_vars(recipe_terms, predicate_name)
    type_terms = filter(x -> x.name == predicate_name, recipe_terms)
    var_map = Dict{Var,Term}()
    var_types = Dict{Var,Term}()
    type_counts = Dict{Symbol,Int}()
    for term in type_terms
        type = term.args[1]
        var = term.args[2]
        count = get(type_counts, type.name, 0) + 1
        obj = Const(Symbol(type, count))
        var_map[var] = obj
        var_types[var] = type
        type_counts[type.name] = count
    end
    return var_map, var_types, type_counts
end

"Normalize recipe by converting ingredient clusters to a canonical form."
function normalize_recipe(recipe::Term)
    # Extract recipe terms from existential condition
    terms = PDDL.flatten_conjs(recipe.args[2])
    # Extract and Skolemize food variables
    f_var_map, f_var_types, f_type_counts =
        extract_and_skolemize_vars(terms, Symbol("food-type"))
    # Extract and Skolemize receptacle variables
    r_var_map, r_var_types, r_type_counts =
        extract_and_skolemize_vars(terms, Symbol("receptacle-type"))
    # Replace all variables with their Skolemized constants
    terms = Term[PDDL.substitute(t, merge(f_var_map, r_var_map)) for t in terms]
    new_terms = copy(terms)
    # Normalize combination clusters
    ingredients = collect(values(f_var_map))
    combine_cluster_vars = Dict{Var,Const}()
    combine_clusters, combine_terms =
        extract_ingredient_clusters(ingredients, terms, Symbol("combined-with"))
    for (i, (c, c_terms)) in enumerate(zip(combine_clusters, combine_terms))
        setdiff!(new_terms, c_terms)
        method = c_terms[1].args[1] # Extract combination method
        for obj in c # Add combined terms for each ingredient
            push!(new_terms, Compound(:combined, Term[method, obj]))
        end
        cluster_var = Var(Symbol("Combine", i))
        for obj in c # Add combined with terms for each ingredient
            push!(new_terms, Compound(Symbol("combined-in-cluster"), 
                                      Term[method, cluster_var, obj]))
        end
        # Add cluster variable
        combine_cluster_vars[cluster_var] = method
    end
    # Normalize cooking clusters
    cook_cluster_vars = Dict{Var,Const}()
    cook_clusters, cook_terms =
        extract_ingredient_clusters(ingredients, terms, Symbol("cooked-with"))
    for (i, (c, c_terms)) in enumerate(zip(cook_clusters, cook_terms))
        setdiff!(new_terms, c_terms)
        method = c_terms[1].args[1] # Extract cooking method
        for obj in c # Add cooked terms for each ingredient
            push!(new_terms, Compound(:cooked, Term[method, obj]))
        end
        cluster_var = Var(Symbol("Cook", i))
        for obj in c # Add combined with terms for each ingredient
            push!(new_terms, Compound(Symbol("cooked-in-cluster"), 
                                      Term[method, cluster_var, obj]))
        end
        # Add cluster variable
        cook_cluster_vars[cluster_var] = method
    end
    cluster_vars = merge(combine_cluster_vars, cook_cluster_vars)
    return unique!(new_terms), cluster_vars
end

"""
    recipe_overlap(recipe1, recipe2)

Returns the intersection-over-union of recipe terms after normalization and
variable alignment, as a measure of the semantic similarity of two recipes.
"""
function recipe_overlap(recipe1::Term, recipe2::Term)
    terms1, vars1 = normalize_recipe(recipe1)
    terms2, vars2 = normalize_recipe(recipe2)
    # Perform DFS over all possible variable alignments to find max IOU
    max_iou = 0.0
    queue = [Dict{Var,Term}()]
    while !isempty(queue)
        alignment = pop!(queue)
        # Compute intersection over union for complete variable alignments
        if length(alignment) == min(length(vars1), length(vars2))
            ts1 = Term[PDDL.substitute(t, alignment) for t in terms1]
            iou = length(intersect(ts1, terms2)) / length(union(ts1, terms2))
            if iou > max_iou
                max_iou = iou
            end
        else # Extend current variable alignment by trying all possibilities
            for v1 in setdiff(keys(vars1), keys(alignment))
                for v2 in setdiff(keys(vars2), values(alignment))
                    vars1[v1] == vars2[v2] || continue # Ensure method match
                    new_alignment = copy(alignment)
                    new_alignment[v1] = v2
                    push!(queue, new_alignment)
                end
            end
        end
    end
    return max_iou
end
