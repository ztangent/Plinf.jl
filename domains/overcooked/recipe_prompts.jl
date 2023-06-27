using PDDL
using Random

RECIPE_TEMPLATE = """
Description: [DESCRIPTION]
Ingredients: [INGREDIENT]+
[(Prepare|Combine|Cook): [METHOD] the [INGREDIENT]+]+
Serve: (in|on) a [RECEPTACLE]"""

RECIPE_PRIOR_INSTRUCTION =
    "Below is a list of recipes that can be made using only the " *
    "ingredients, receptacles, tools, appliances, and methods in this kitchen. " *
    "If ingredients in a recipe are not modified by any method, then they can be " * 
    "assumed to remain in store-bought form.\n\n"

INFERENCE_KITCHEN_HEADER = 
    "Someone is in a kitchen, and is about to make a dish. The following is a description of the kitchen."
INFERENCE_NARRATIVE_HEADER =
    "You now observe them taking the following actions:"
INFERENCE_MCQ_QUESTION_TEXT =
    "Which of these recipes are they likely trying to make?"

INFERENCE_FREEFORM_QUESTION_TEXT =
    "Given the above, what recipe could they be making? " *
    "Please express your answer in the following format, using only the " *
    "ingredients, receptacles, tools, appliances, and methods in this kitchen:" *
    "\n\n" * RECIPE_TEMPLATE * "\n\n" *
    "Note that each preparation, combination, or cooking step should mention " *
    "*only* the ingredients that are used in the recipe, as stated in the " *
    "ingredients list. In addition, the recipe should only be served in one of " *
    "the receptacles listed in the kitchen."

function construct_recipe_prior_prompt(
    domain::Domain, problem, recipes=String[], kitchen_name="";
    instruction=RECIPE_PRIOR_INSTRUCTION
)
    kitchen_desc = construct_kitchen_description(domain, problem)
    prompt = "KITCHEN: $(uppercase(kitchen_name))" * "\n\n" * kitchen_desc
    prompt *= "\n\n" * instruction * "RECIPES\n\n" * join(recipes, "\n\n")
    return prompt
end
   
function construct_multishot_recipe_prior_prompt(
    domain::Domain, train_problems, train_recipes, train_names,
    test_problem, test_recipes, test_name;
    kwargs...
)
    prompt = ""
    for (i, name) in enumerate(train_names)
        prompt *= construct_recipe_prior_prompt(
            domain, train_problems[i], train_recipes[i], name;
            kwargs...
        ) * "\n\n"
    end
    prompt *= construct_recipe_prior_prompt(
        domain, test_problem, test_recipes, test_name;
        kwargs...
    )
    return prompt
end

function construct_recipe_inference_prompt_mcq(
    domain::Domain, problem,
    narrative, narrative_step::Int,
    recipes::Vector{String},
    kitchen_name="";
    kitchen_header=INFERENCE_KITCHEN_HEADER,
    narrative_header=INFERENCE_NARRATIVE_HEADER,
    question_text=INFERENCE_MCQ_QUESTION_TEXT,
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

function construct_multishot_recipe_inference_prompt_mcq(
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
    test_prompt = construct_recipe_inference_prompt_mcq(
        domain, test_problem, test_narrative,
        test_step, test_recipes, test_name; kwargs...
    )
    prompt *= test_prompt
    return prompt
end

function construct_recipe_inference_prompt_freeform(
    domain::Domain, problem,
    narrative, narrative_step::Int,
    kitchen_name="";
    kitchen_header=INFERENCE_KITCHEN_HEADER,
    narrative_header=INFERENCE_NARRATIVE_HEADER,
    question_text=INFERENCE_FREEFORM_QUESTION_TEXT,
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
    return prompt
end

function construct_multishot_recipe_inference_prompt_freeform(
    domain::Domain,
    train_problems, train_narratives, train_recipes, train_names,
    test_problem, test_narrative, test_step::Int, test_name;
    train_step_mode=:fixed, train_step_frac=0.75, kwargs...
)
    prompt = ""
    # Compute test step fraction
    test_step_frac = test_step / length(test_narrative)
    # Iterate over training set
    for (i, name) in enumerate(train_names)
        problem = train_problems[i]
        narrative = train_narratives[i]
        recipe = train_recipes[i]
        if train_step_mode == :match
            train_step = round(Int, test_step_frac * length(narrative))
        elseif train_step_mode == :last
            train_step = length(narrative)
        else
            train_step = round(Int, length(narrative) * train_step_frac)
        end
        train_prompt = construct_recipe_inference_prompt_freeform(
            domain, problem, narrative, train_step, name;
            kwargs...
        )
        train_prompt *= "BEGIN ANSWER\n" * recipe * "\nEND ANSWER"
        prompt *= train_prompt * "\n\n" * "===" * "\n\n"
    end
    # Append prompt for test problem
    test_prompt = construct_recipe_inference_prompt_freeform(
        domain, test_problem, test_narrative,
        test_step, test_name; kwargs...
    )
    prompt *= test_prompt * "BEGIN ANSWER\n"
    return prompt
end
