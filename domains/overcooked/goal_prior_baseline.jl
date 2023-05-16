using Gen, PDDL, Random

if !isdefined(Main, :BASELINE_RECIPE_CACHE)
    const BASELINE_RECIPE_CACHE = Dict{UInt, Vector{Term}}()
end

@gen function cached_recipe_prior(state::State, n_recipes::Int = 200)
    recipes = get!(BASELINE_RECIPE_CACHE, hash(state)) do
        [initial_state_recipe_prior(state) for _ in 1:n_recipes] 
    end
    recipe_id ~ uniform_discrete(1, length(recipes))
    return recipes[recipe_id]
end

@gen function initial_state_recipe_prior(state::State)
    food_types = Symbol[o.name for o in PDDL.get_objects(state, Symbol("ftype"))]
    receptacle_types = Symbol[o.name for o in PDDL.get_objects(state, Symbol("rtype"))]
    prepare_methods = Symbol[o.name for o in PDDL.get_objects(state, Symbol("prepare-method"))]
    combine_methods = Symbol[o.name for o in PDDL.get_objects(state, Symbol("combine-method"))]
    cook_methods = Symbol[o.name for o in PDDL.get_objects(state, Symbol("cook-method"))]
    spec = {*} ~ recipe_prior(food_types, receptacle_types,
                              prepare_methods, combine_methods, cook_methods)
    return spec
end

@gen function recipe_prior(
    food_types::Vector{Symbol},
    receptacle_types::Vector{Symbol},
    prepare_methods::Vector{Symbol},
    combine_methods::Vector{Symbol},
    cook_methods::Vector{Symbol}
)
    # Sample ingredients
    n_ingredients, ingredients =
        {:ingredients} ~ ingredient_prior(food_types)
    # Sample preparation method for each ingredient
    prepare_choices =
        {:prepare} ~ method_prior(n_ingredients, prepare_methods)
    # Sample ingredient clusters for combination steps
    n_combine_clusters, combine_clusters =
        {:combine_clusters} ~ cluster_prior(n_ingredients)
    # Sample combination method for each ingredient cluster
    combine_choices =
        {:combine} ~ method_prior(n_combine_clusters, combine_methods)
    # Sample ingredient clusters for cooking steps
    n_cook_clusters, cook_clusters =
        {:cook_clusters} ~ cluster_prior(n_combine_clusters)
    cook_clusters = map(cook_clusters) do cluster_idxs
        reduce(vcat, combine_clusters[cluster_idxs])
    end
    # Sample cooking method for each ingredient cluster
    cook_choices =
        {:cook} ~ method_prior(n_cook_clusters, cook_methods)
    # Sample type of serving receptacle
    receptacle_id ~ uniform_discrete(1, length(receptacle_types))
    receptacle = receptacle_types[receptacle_id]
    # Construct dish specification from choices
    spec = construct_recipe_spec(ingredients, receptacle, prepare_choices,
                                 combine_clusters, combine_choices,
                                 cook_clusters, cook_choices)
    return spec
end

@gen function ingredient_prior(food_types::Vector{Symbol})
    init_idx ~ uniform_discrete(1, length(food_types))
    included = [({i} ~ bernoulli(i == init_idx ? 1.0 : 0.5))
                for i in eachindex(food_types)]
    ingredients = food_types[included]
    n_ingredients = length(ingredients)
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

function construct_recipe_spec(
    ingredients::Vector{Symbol},
    receptacle::Symbol,
    prepare_choices::Vector,
    combine_clusters::Vector{Vector{Int}},
    combine_choices::Vector,
    cook_clusters::Vector{Vector{Int}},
    cook_choices::Vector
)
    terms = Term[]
    vars = [Var(Symbol(uppercasefirst(string(item)))) for item in ingredients]
    rvar = Var(Symbol(uppercasefirst(string(receptacle))))
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
        cluster = combine_clusters[c]
        n_items = length(cluster)
        if n_items == 1 # Add one combined term
            i = cluster[1]
            term = Compound(Symbol("combined"), Term[Const(method), vars[i]])
            push!(terms, term)
        else # Add combined-with terms for each pair of objects in cluster
            for k in 1:n_items-1
                i, j = cluster[k], cluster[k+1]
                term = Compound(Symbol("combined-with"),
                                Term[Const(method), vars[i], vars[j]])
                push!(terms, term)
            end
        end
    end
    # Construct cooking predicates
    for (c, method) in enumerate(cook_choices)
        method === nothing && continue
        cluster = cook_clusters[c]
        n_items = length(cluster)
        if n_items == 1 # Add one cooked term
            i = cluster[1]
            term = Compound(Symbol("cooked"), Term[Const(method), vars[i]])
            push!(terms, term)
        else # Add cooked-with terms for each pair of objects in cluster
            for k in 1:n_items-1
                i, j = cluster[k], cluster[k+1]
                term = Compound(Symbol("cooked-with"),
                                Term[Const(method), vars[i], vars[j]])
                push!(terms, term)
            end
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
