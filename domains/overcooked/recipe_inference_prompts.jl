using Random

INFERENCE_KITCHEN_HEADER = 
    "Someone is in a kitchen, and is about to make a dish. The following is a description of the kitchen."
INFERENCE_NARRATIVE_HEADER =
    "You now observe them taking the following actions:"
INFERENCE_QUESTION_TEXT =
    "Which of these recipes are they likely trying to make?"

function construct_recipe_inference_prompt(
    domain::Domain, problem,
    narrative, narrative_step::Int,
    recipes::Vector{String},
    kitchen_name="";
    kitchen_header=INFERENCE_KITCHEN_HEADER,
    narrative_header=INFERENCE_NARRATIVE_HEADER,
    question_text=INFERENCE_QUESTION_TEXT,
)
    kitchen_desc = construct_kitchen_description(domain, problem)
    prompt = kitchen_header * "\n\n" * "KITCHEN: $(uppercase(kitchen_name))"
    prompt *= "\n\n" * kitchen_desc
    narrative = narrative[1:narrative_step]
    if !isempty(narrative)
        prompt *= "\n\n" * narrative_header * "\n"
        for (i, line) in enumerate(narrative)
            prompt *= "\n$(i). $(line)"
        end
    end
    prompt *= "\n\n" * question_text * "\n\n"
    for (i, recipe) in enumerate(recipes)
        option_char = Char(64 + i)
        prompt *= "-- Recipe $(option_char) --\n$(recipe)\n\n"
    end
    prompt *= "Answer: Recipe"
    return prompt
end

function construct_multishot_recipe_inference_prompt(
    domain::Domain,
    train_problems, train_narratives, train_recipes,
    train_correct_ids, train_names,
    test_problem, test_narrative, test_step::Int,
    test_recipes, test_name;
    train_step_mode=:fixed, train_step_frac=0.75, kwargs...
)
    prompt = ""
    # Create new RNG with fixed seed based on kitchen
    rng = MersenneTwister(hash(test_name))
    # Compute test step fraction
    test_step_frac = test_step / length(test_narrative)
    # Iterate over training set
    for (i, name) in enumerate(train_names)
        problem = train_problems[i]
        narrative = train_narratives[i]
        recipes = train_recipes[i]
        perm_ids = randperm(rng, length(recipes))
        recipes = recipes[perm_ids]
        correct_id = findfirst(==(train_correct_ids[i]), perm_ids)
        if train_step_mode == :match
            train_step = round(Int, test_step_frac * length(narrative))
        elseif train_step_mode == :last
            train_step = length(narrative)
        else
            train_step = round(Int, length(narrative) * train_step_frac)
        end
        train_prompt = construct_recipe_inference_prompt(
            domain, problem, narrative, train_step, recipes, name;
            kwargs...
        )
        option_char = Char(64 + correct_id)
        prompt *= train_prompt * " " * option_char * "\n\n" * "===" * "\n\n"
    end
    # Append prompt for test problem
    test_prompt = construct_recipe_inference_prompt(
        domain, test_problem, test_narrative,
        test_step, test_recipes, test_name; kwargs...
    )
    prompt *= test_prompt
    return prompt
end
