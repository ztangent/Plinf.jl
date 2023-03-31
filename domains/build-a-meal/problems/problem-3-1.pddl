; Delicatessen 
(define (problem overcooked-problem-3-1)
    (:domain overcooked)
    ; Add ham for pineapple
    (:objects
        bread cheese onion lettuce tomato ham - ftype ; Food types
        chopping-board grill-pan plate - rtype ; Receptacle types
        knife - ttype ; Tool types
        stove - atype ; Appliance types
        slice chop mince - prepare-method ; Preparation methods
        grill - cook-method ; Cooking methods
        bread1 cheese1 onion1 lettuce1 tomato1 ham1 - food ; Food objects
        board1 pan1 plate1 - receptacle ; Receptacle objects
        knife1 - tool ; Tool objects
        stove1 - appliance ; Appliance objects
        start-loc food-loc chop-loc stove-loc plate-loc - location ; Locations
    )
    (:init
        ; Type declarations
        (food-type bread bread1)
        (food-type cheese cheese1)
        (food-type onion onion1)
        (food-type lettuce lettuce1)
        (food-type tomato tomato1)
        (food-type ham ham1)
        (receptacle-type chopping-board board1)
        (receptacle-type plate plate1)
        (receptacle-type grill-pan pan1)
        (tool-type knife knife1)
        (appliance-type stove stove1)
        ; Method declarations
        (has-prepare-method slice chopping-board knife)
        (has-prepare-method mince chopping-board knife)
        (has-prepare-method chop chopping-board knife)
        (has-cook-method grill grill-pan stove)
        ; Initial agent state
        (handempty)
        (agent-at-loc start-loc)
        ; Initial food locations
        (object-at-loc bread1 food-loc)
        (object-at-loc cheese1 food-loc)
        (object-at-loc onion1 food-loc)
        (object-at-loc lettuce1 food-loc)
        (object-at-loc tomato1 food-loc)
        (object-at-loc ham1 food-loc)
        ; Receptacle, tool, and appliance locations
        (object-at-loc board1 chop-loc)
        (object-at-loc knife1 chop-loc)
        (object-at-loc pan1 stove-loc)
        (object-at-loc stove1 stove-loc)
        (object-at-loc plate1 plate-loc)
        ; Whether receptacles are located on appliances
        (in-appliance pan1 stove1)
        (occupied stove1)
    )
     (:goal
        (exists (?bread - food ?cheese - food ?plate - receptacle)
                (and (food-type bread ?bread)
                     (food-type cheese ?cheese)
                     (receptacle-type plate ?plate)
                     (prepared slice ?cheese)
                     (cooked-with grill ?bread ?cheese)
                     (in-receptacle ?bread ?plate)
                     (in-receptacle ?cheese ?plate)))
     )


)



