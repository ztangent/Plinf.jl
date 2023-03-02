## Code for parsing English recipe descriptions to PDDL

using PDDL

"Tries to parse a recipe to PDDL, returns nothing upon failure."
function try_parse_recipe(str::AbstractString)
    try
        term, description = parse_recipe(str)
        term = parse_pddl(write_pddl(term)) # Reparse to check for errors
        return term, description
    catch e
        return nothing
    end
end

"Parse recipe string as a PDDL goal, checking if it is a valid PDDL formula."
function parse_recipe(str::AbstractString)
    lines = filter(!=(""), split(strip(str), "\n"))
    terms = Term[] 

    # Parse English description
    description_str = lines[1]
    m = match(r"Description: ?(.*)", description_str)
    if isnothing(m)
        description = "missing"
        pushfirst!(lines, "Description: ")
    else
        description = m.captures[1]
    end

    # Parse ingredients
    ingredients_str = lines[2]
    m = match(r"Ingredients: ?(.*)", ingredients_str)
    ingredients = split_ingredient_list(m.captures[1])
    ingredients = map(x -> replace(x, " " => "-"), strip.(ingredients))
    food_types = map(x -> Const(Symbol(x)), ingredients)
    food_vars = map(x -> Var(Symbol(uppercasefirst(x))), ingredients)
    # Construct food type declarations
    for (type, var) in zip(food_types, food_vars)
        term = Compound(Symbol("food-type"), Term[type, var])
        push!(terms, term)
    end

    # Parse receptacle
    m = match(r"Serve: ?(?:in|on|upon) (?:a|an) ([\w\- ]+)", lines[end])
    receptacle = m.captures[1]
    receptacle = replace(strip(receptacle), " " => "-")
    # Construct receptacle type declaration
    r_type = Const(Symbol(receptacle))
    r_var = Var(Symbol(uppercasefirst(receptacle)))
    push!(terms, Compound(Symbol("receptacle-type"), Term[r_type, r_var]))

    # Loop over remaining lines
    for line in lines[3:end-1]
        m = match(r"(\w+): ?(.*)", line)
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

function split_ingredient_list(str::AbstractString)
    ingredients = split(str, ", ")
    final_ingredients_str = pop!(ingredients)
    n_chars = length(final_ingredients_str)
    if n_chars > 4 && final_ingredients_str[1:4] == "and " # Handle Oxford comma
        final_ingredients = [final_ingredients_str[5:end]]
    else
        final_ingredients = split(final_ingredients_str, " and ")
    end
    append!(ingredients, final_ingredients)
    return ingredients
end

function parse_prepare_step(str::AbstractString)
    method, ingredients = split(str, " the ")
    # Parse method    
    method = Const(Symbol(replace(method, " " => "-")))
    # Parse ingredients
    ingredients = split_ingredient_list(ingredients)
    ingredients = map(x -> replace(x, " " => "-"), strip.(ingredients))
    @assert length(ingredients) == 1
    ingredient = ingredients[1]
    var = Var(Symbol(uppercasefirst(ingredient)))
    return Compound(:prepared, Term[method, var])
end

function parse_combine_step(str::AbstractString)
    method, ingredients = split(str, " the ")
    # Parse method    
    method = Const(Symbol(replace(method, " " => "-")))
    # Parse ingredients
    ingredients = split_ingredient_list(ingredients)
    ingredients = map(x -> replace(x, " " => "-"), strip.(ingredients))
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
    method = Const(Symbol(replace(method, " " => "-")))
    # Parse ingredients
    ingredients = split_ingredient_list(ingredients)
    ingredients = map(x -> replace(x, " " => "-"), strip.(ingredients))
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
