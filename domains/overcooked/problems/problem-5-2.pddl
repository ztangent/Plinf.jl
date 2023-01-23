; Patisserie
(define (problem overcooked-problem-5-2)
    (:domain overcooked)
    (:objects
        egg honey flour chocolate strawberry watermelon grape apple - ftype ; Food types
        mixing-bowl plate tray - rtype ; Receptacle types
        mixer oven - atype ; Appliance types
        mix - combine-method ; Preparation methods
        bake - cook-method ; Cooking methods
        egg1 honey1 flour1 chocolate1 strawberry1 watermelon1 grape1 apple1 - food ; Food objects
        mixing-bowl1 plate1 tray1 - receptacle ; Receptacle objects
        mixer1 oven1 - appliance ; Appliance objects
        start-loc food-loc mix-loc oven-loc plate-loc - location ; Locations
    )
    (:init
        ; Type declarations
        (food-type honey honey1)
        (food-type flour flour1)
        (food-type egg egg1)
        (food-type chocolate chocolate1)
        (food-type strawberry strawberry1)
        (food-type watermelon watermelon1)
        (food-type grape grape1)
        (food-type apple apple1)
        (receptacle-type mixing-bowl mixing-bowl1)
        (receptacle-type plate plate1)
        (receptacle-type tray tray1)
        (appliance-type oven oven1)
        (appliance-type mixer mixer1)
        ; Method declarations
        (has-combine-method mix mixing-bowl mixer)
        (has-cook-method bake tray oven)
        ; Initial agent state
        (handempty)
        (agent-at-loc start-loc)
        ; Initial food locations
        (object-at-loc honey1 food-loc)
        (object-at-loc flour1 food-loc)
        (object-at-loc egg1 food-loc)
        (object-at-loc chocolate1 food-loc)
        (object-at-loc strawberry1 food-loc)
        (object-at-loc watermelon1 food-loc)
        (object-at-loc grape1 food-loc)
        (object-at-loc apple1 food-loc)
        ; Receptacle, tool, and appliance locations
        (object-at-loc mixer1 mix-loc)
        (object-at-loc mixing-bowl1 mix-loc)
        (object-at-loc tray1 oven-loc)
        (object-at-loc oven1 oven-loc)
        (object-at-loc plate1 plate-loc)
        ; Whether receptacles are located on appliances
        (in-appliance mixing-bowl1 mixer1)
        (in-appliance tray1 oven1)
        (occupied mixer1)
        (occupied oven1)
    )
    (:goal
        (exists (?egg - food ?chocolate - food ?flour - food ?plate - receptacle)
                (and (food-type egg ?egg)
                     (food-type flour ?flour)
                     (food-type chocolate ?chocolate)
                     (receptacle-type plate ?plate)
                     (combined-with mix ?egg ?flour)
                     (combined-with mix ?flour ?chocolate)
                     (cooked-with bake ?egg ?flour)
                     (cooked-with bake ?flour ?chocolate)
                     (in-receptacle ?egg ?plate)
                     (in-receptacle ?chocolate ?plate)
                     (in-receptacle ?flour ?plate)))
    )
)
