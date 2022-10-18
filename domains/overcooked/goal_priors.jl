using Gen, PDDL

@gen function dish_prior(
    food_types::Vector{Symbol},
    receptacle_types::Vector{Symbol},
    prepare_methods::Vector{Symbol},
    combine_methods::Vector{Symbol},
    cook_methods::Vector{Symbol}
)
    # Sample ingredients
    n_ingredients, ingredients =
        {:ingredients} ~ ingredient_prior(food_types)
    # Sample ingredient cluster assignments
    n_clusters, clusters =
        {:clusters} ~ cluster_prior(n_ingredients)
    # Sample preparation method for each ingredient
    prepare_choices =
        {:prepare} ~ method_prior(n_ingredients, prepare_methods)
    # Sample combination method for each ingredient cluster
    combine_choices =
        {:combine} ~ method_prior(n_clusters, combine_methods)
    # Sample cooking method for each ingredient cluster
    cook_choices =
        {:cook} ~ method_prior(n_clusters, cook_methods)
    # Sample type of serving receptacle
    receptacle_id ~ uniform_discrete(1, length(receptacle_types))
    receptacle = receptacle_types[receptacle_id]
    # Construct dish specification from choices
    # return ingredients, clusters, receptacle,
    #        prepare_choices, combine_choices, cook_choices
    spec = construct_dish_spec(ingredients, clusters, receptacle,
                               prepare_choices, combine_choices, cook_choices)
    return spec
end

@gen function ingredient_prior(food_types::Vector{Symbol})
    n_food_types = length(food_types)
    n_ingredients = ({:n} ~ geometric(0.5)) + 1
    ingredients = Vector{Symbol}(undef, n_ingredients)
    for i in 1:n_ingredients
        food_id = {i} ~ uniform_discrete(1, n_food_types)
        ingredients[i] = food_types[food_id]
    end
    return n_ingredients, ingredients
end

# CRP style clustering prior
@gen function cluster_prior(n_items::Int)
    n_clusters = 0
    clusters = Vector{Int}[]
    for k in 1:n_items
        probs = Float64[length(c)/k for c in clusters]
        push!(probs, 1/k)
        cluster_id = {k} ~ categorical(probs)
        if cluster_id > n_clusters
            n_clusters += 1
            push!(clusters, Int[])
        end
        push!(clusters[cluster_id], k)
    end
    return n_clusters, clusters
end

@gen function method_prior(n_items::Int, methods::Vector{Symbol})
    choices = Vector{Union{Symbol,Nothing}}(undef, n_items)
    for i in 1:n_items
        method_id = {i} ~ uniform_discrete(0, length(methods))
        choices[i] = method_id == 0 ? nothing : methods[method_id]
    end
    return choices
end

function construct_dish_spec(
    ingredients::Vector{Symbol},
    clusters::Vector{Vector{Int}},
    receptacle::Symbol,
    prepare_choices::Vector,
    combine_choices::Vector,
    cook_choices::Vector
)
    terms = Term[]
    vars = [Var(Symbol("F$i")) for i in 1:length(ingredients)]
    rvar = Var(:R)
    # Construct food type declarations
    for (i, food_type) in enumerate(ingredients)
        term = Compound(Symbol("food-type"), Term[Const(food_type), vars[i]])
        push!(terms, term)
    end
    # Construct receptacle type declaration
    term = Compound(Symbol("receptacle-type"), Term[Const(receptacle), rvar])
    push!(terms, term)
    # Construct preparation predicates
    for (i, method) in enumerate(prepare_choices)
        method === nothing && continue
        term = Compound(Symbol("prepared"), Term[Const(method), vars[i]])
        push!(terms, term)
    end
    # Construct combination predicates
    for (c, method) in enumerate(combine_choices)
        method === nothing && continue
        cluster = clusters[c]
        for i in cluster
            term = Compound(Symbol("combined"), Term[Const(method), vars[i]])
            push!(terms, term)
        end
        n_items = length(cluster)
        n_items == 1 && continue
        for k in 1:length(cluster)
            i, j = cluster[k], cluster[k == n_items ? 1 : k+1]
            term = Compound(Symbol("combined-with"),
                            Term[Const(method), vars[i], vars[j]])
            push!(terms, term)
        end
    end
    # Construct cooking predicates
    for (c, method) in enumerate(cook_choices)
        method === nothing && continue
        cluster = clusters[c]
        for i in cluster
            term = Compound(Symbol("cooked"), Term[Const(method), vars[i]])
            push!(terms, term)
        end
        n_items = length(cluster)
        n_items == 1 && continue
        for k in 1:length(cluster)
            i, j = cluster[k], cluster[k == n_items ? 1 : k+1]
            term = Compound(Symbol("cooked-with"),
                            Term[Const(method), vars[i], vars[j]])
            push!(terms, term)
        end
    end
    # Construct receptacle predicates
    for v in vars
        term = Compound(Symbol("in-receptacle"), Term[v, rvar])
        push!(terms, term)
    end
    # Construct type conditions
    typeconds = Term[Compound(:food, Term[v]) for v in vars]
    push!(typeconds, Compound(:receptacle, Term[rvar]))
    # Wrap in existential quantifier
    spec = Compound(:exists, Term[Compound(:and, typeconds),
                                  Compound(:and, terms)])
    return spec
end
