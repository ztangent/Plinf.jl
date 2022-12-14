; Patisserie
(define (problem overcooked-problem-5-5)
    (:domain overcooked)
    ;add plate
    (:objects
        egg honey flour chocolate strawberry watermelon grape apple peach orange ice milk - ftype ; Food types
        blender-jug basket mixing-bowl chopping-board plate tray glass - rtype ; Receptacle types
        oven deep-fryer mixer blender - atype ; Appliance types
        knife - ttype ; Tool types
        slice - prepare-method ; Preparation methods
        blend mix - combine-method ; Combine methods
        bake deep-fry - cook-method ; Cooking methods
        egg1 honey1 flour1 chocolate1 strawberry1 watermelon1 grape1 apple1 peach1 orange1 ice1 milk1 - food ; Food objects
        blender-jug1 glass1 basket1 mixing-bowl1 board1 plate1 tray1 - receptacle ; Receptacle objects
        blender1 oven1 fryer1 mixer1 - appliance ; Appliance objects
        knife1 - tool ; Tool objects
        start-loc food-loc blend-loc oven-loc fryer-loc glass-loc mix-loc board-loc plate-loc chop-loc - location ; Locations
    )
    (:init
        ; Type declarations
        (food-type honey honey1)
        (food-type flour flour1)
        (food-type ice ice1)
        (food-type egg egg1)
        (food-type chocolate chocolate1)
        (food-type strawberry strawberry1)
        (food-type watermelon watermelon1)
        (food-type orange orange1)
        (food-type peach peach1)
        (food-type grape grape1)
        (food-type apple apple1)
        (food-type milk milk1)
        (tool-type knife knife1)
        (receptacle-type blender-jug blender-jug1)
        (receptacle-type glass glass1)
        (receptacle-type basket basket1)
        (receptacle-type mixing-bowl mixing-bowl1)
        (receptacle-type chopping-board board1)
        (receptacle-type plate plate1)
        (receptacle-type tray tray1)
        (appliance-type oven oven1)
        (appliance-type deep-fryer fryer1)
        (appliance-type blender blender1)
        (appliance-type mixer mixer1)
        ; Method declarations
        (has-prepare-method slice chopping-board knife)
        (has-combine-method mix mixing-bowl mixer)
        (has-combine-method blend blender-jug blender)
        (has-cook-method deep-fry basket deep-fryer)
        (has-cook-method bake tray oven)
        ; Initial agent state
        (handempty)
        (agent-at-loc start-loc)
        ; Initial food locations
        (object-at-loc ice1 food-loc)
        (object-at-loc milk1 food-loc)
        (object-at-loc honey1 food-loc)
        (object-at-loc flour1 food-loc)
        (object-at-loc egg1 food-loc)
        (object-at-loc chocolate1 food-loc)
        (object-at-loc strawberry1 food-loc)
        (object-at-loc watermelon1 food-loc)
        (object-at-loc grape1 food-loc)
        (object-at-loc apple1 food-loc)
        (object-at-loc peach1 food-loc)
        (object-at-loc orange1 food-loc)
        ; Receptacle, tool, and appliance locations
        (object-at-loc blender1 blend-loc)
        (object-at-loc blender-jug1 blend-loc)
        (object-at-loc basket1 fryer-loc)
        (object-at-loc oven1 oven-loc)
        (object-at-loc glass1 glass-loc)
        (object-at-loc fryer1 fryer-loc)
        (object-at-loc board1 board-loc)
        (object-at-loc plate1 plate-loc)
        (object-at-loc tray1 oven-loc)
        (object-at-loc knife1 chop-loc)
        (object-at-loc mixer1 mix-loc)
        (object-at-loc mixing-bowl1 mix-loc)
        ; Whether receptacles are located on appliances
        (in-appliance blender-jug1 blender1)
        (in-appliance basket1 fryer1)
        (in-appliance mixing-bowl1 mixer1)
        (in-appliance tray1 oven1)
        (occupied mixer1)
        (occupied blender1)
        (occupied fryer1)
        (occupied oven1)
    )
    (:goal
        (exists (?egg - food ?apple - food ?flour - food ?plate - receptacle)
                (and (food-type egg ?egg)
                     (food-type flour ?flour)
                     (food-type apple ?apple)
                     (receptacle-type plate ?plate)
                     (prepared slice ?apple)
                     (combined-with mix ?egg ?flour)
                     (combined-with mix ?flour ?apple)
                     (cooked-with bake ?egg ?flour)
                     (cooked-with bake ?flour ?apple)
                     (in-receptacle ?egg ?plate)
                     (in-receptacle ?flour ?plate)
                     (in-receptacle ?apple ?plate)))
    )
)