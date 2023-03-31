; Pizzeria
(define (problem overcooked-problem-4-1)
    (:domain overcooked)
    (:objects
        pizza-base tomato cheese sausage basil olive - food ; Food types
        slice - prepare-method ; Preparation methods
        bake - cook-method ; Cooking methods
    )
    (:init
        ; Method declarations
        (has-prepare-method slice chopping-board knife)
        (has-cook-method bake tray oven)
        (has-combine-method mix mixing-bowl mixer)
    )
    (:goal
        (exists (?egg - food ?flour - food ?tomato - food ?cheese - food ?basil - food ?plate - receptacle)
            (and (food-type egg ?egg)
                 (food-type flour ?flour)
                 (food-type tomato ?tomato)
                 (food-type cheese ?cheese)
                 (food-type basil ?basil)
                 (receptacle-type plate ?plate)
                 (prepared slice ?tomato)
                 (combined-with mix ?egg ?flour)
                 (cooked-with bake ?egg ?flour)
                 (cooked-with bake ?tomato ?flour)
                 (cooked-with bake ?tomato ?cheese)
                 (cooked-with bake ?cheese ?basil)
                 (in-receptacle ?tomato ?plate)
                 (in-receptacle ?cheese ?plate)
                 (in-receptacle ?basil ?plate)
                 (in-receptacle ?egg ?plate)
                 (in-receptacle ?flour ?plate)))
    )
)
