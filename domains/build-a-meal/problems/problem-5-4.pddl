; Fruits and desserts
(define (problem overcooked-problem-5-4)
    (:domain overcooked)
    (:objects
        honey chocolate strawberry watermelon grape apple ice milk - ftype ; Food types
        blender-jug chopping-board mixing-bowl glass - rtype ; Receptacle types
        blender mixer - atype ; Appliance types
        knife - ttype ; Tool types
        mix blend  - combine-method ; Combine methods
        slice - prepare-method ; Preparation methods
        honey1 chocolate1 strawberry1 watermelon1 grape1 apple1 ice1 milk1 - food ; Food objects
        blender-jug1 board1 mixing-bowl1 glass1 - receptacle ; Receptacle objects
        blender1 mixer1 - appliance ; Appliance objects
        knife1 - tool ; Tool objects
        start-loc food-loc mix-loc chop-loc glass-loc blend-loc - location ; Locations
    )
    (:init
        ; Type declarations
        (food-type honey honey1)
        (food-type chocolate chocolate1)
        (food-type strawberry strawberry1)
        (food-type watermelon watermelon1)
        (food-type grape grape1)
        (food-type apple apple1)
        (food-type ice ice1)
        (food-type milk milk1)
        (tool-type knife knife1)
        (receptacle-type mixing-bowl mixing-bowl1)
        (receptacle-type chopping-board board1)
        (receptacle-type glass glass1)
        (receptacle-type blender-jug blender-jug1)
        (appliance-type mixer mixer1)
        (appliance-type blender blender1)
        ; Method declarations
        (has-combine-method mix mixing-bowl mixer)
        (has-prepare-method slice chopping-board knife)
        (has-combine-method blend blender-jug blender)
        ; Initial agent state
        (handempty)
        (agent-at-loc start-loc)
        ; Initial food locations
        (object-at-loc honey1 food-loc)
        (object-at-loc chocolate1 food-loc)
        (object-at-loc strawberry1 food-loc)
        (object-at-loc watermelon1 food-loc)
        (object-at-loc grape1 food-loc)
        (object-at-loc apple1 food-loc)
        (object-at-loc ice1 food-loc)
        (object-at-loc milk1 food-loc)
        ; Receptacle, tool, and appliance locations
        (object-at-loc board1 chop-loc)
        (object-at-loc knife1 chop-loc)
        (object-at-loc mixer1 mix-loc)
        (object-at-loc mixing-bowl1 mix-loc)
        (object-at-loc glass1 glass-loc)
        (object-at-loc blender1 blend-loc)
        (object-at-loc blender-jug1 blend-loc)
        ; Whether receptacles are located on appliances
        (in-appliance mixing-bowl1 mixer1)
        (in-appliance blender-jug1 blender1)
        (occupied mixer1)
        (occupied blender1)
    )
    (:goal
        (exists (?ice - food ?chocolate - food ?milk - food ?glass - receptacle)
                (and (food-type ice ?ice)
                     (food-type milk ?milk)
                     (food-type chocolate ?chocolate)
                     (receptacle-type glass ?glass)
                     (combined-with blend ?ice ?milk)
                     (combined-with blend ?milk ?chocolate)
                     (in-receptacle ?ice ?glass)
                     (in-receptacle ?chocolate ?glass)
                     (in-receptacle ?milk ?glass)))
    )
)