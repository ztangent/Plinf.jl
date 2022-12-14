; Delicatessen
(define (problem overcooked-problem-3-2)
    (:domain overcooked)
    (:objects
        ham bacon bread cheese onion lettuce tomato mayonnaise - ftype ; Food types
        chopping-board grill-pan basket plate - rtype ; Receptacle types
        knife - ttype ; Tool types
        stove deep-fryer - atype ; Appliance types
        slice chop mince - prepare-method ; Preparation methods
        grill deep-fry - cook-method ; Cooking methods
        ham1 bread1 cheese1 onion1 bacon1 lettuce1 tomato1 mayo1 - food ; Food objects
        board1 basket1 pan1 plate1 - receptacle ; Receptacle objects
        knife1 - tool ; Tool objects
        stove1 fryer1 - appliance ; Appliance objects
        start-loc food-loc chop-loc fryer-loc stove-loc plate-loc - location ; Locations
    )
    (:init
        ; Type declarations
        (food-type ham ham1)
        (food-type cheese cheese1)
        (food-type onion onion1)
        (food-type bacon bacon1)
        (food-type lettuce lettuce1)
        (food-type tomato tomato1)
        (food-type bread bread1)
        (food-type mayonnaise mayo1)
        (receptacle-type chopping-board board1)
        (receptacle-type plate plate1)
        (receptacle-type grill-pan pan1)
        (receptacle-type basket basket1)
        (tool-type knife knife1)
        (appliance-type stove stove1)
        (appliance-type deep-fryer fryer1)
        ; Method declarations
        (has-prepare-method slice chopping-board knife)
        (has-prepare-method mince chopping-board knife)
        (has-prepare-method chop chopping-board knife)
        (has-cook-method grill grill-pan stove)
        (has-cook-method deep-fry basket deep-fryer)
        ; Initial agent state
        (handempty)
        (agent-at-loc start-loc)
        ; Initial food locations
        (object-at-loc bread1 food-loc)
        (object-at-loc ham1 food-loc)
        (object-at-loc cheese1 food-loc)
        (object-at-loc onion1 food-loc)
        (object-at-loc bacon1 food-loc)
        (object-at-loc lettuce1 food-loc)
        (object-at-loc tomato1 food-loc)
        (object-at-loc mayo1 food-loc)
        ; Receptacle, tool, and appliance locations
        (object-at-loc board1 chop-loc)
        (object-at-loc knife1 chop-loc)
        (object-at-loc pan1 stove-loc)
        (object-at-loc stove1 stove-loc)
        (object-at-loc plate1 plate-loc)
        (object-at-loc fryer1 fryer-loc)
        ; Whether receptacles are located on appliances
        (in-appliance pan1 stove1)
        (in-appliance basket1 fryer1)
        (occupied stove1)
    )
    (:goal
        (exists (?ham - food ?bread - food ?cheese - food ?plate - receptacle)
                (and (food-type bread ?bread)
                     (food-type ham ?ham)
                     (food-type cheese ?cheese)
                     (receptacle-type plate ?plate)
                     (prepared slice ?ham)
                     (prepared slice ?cheese)
                     (in-receptacle ?ham ?plate)
                     (in-receptacle ?bread ?plate)
                     (in-receptacle ?cheese ?plate)))
    )
)
