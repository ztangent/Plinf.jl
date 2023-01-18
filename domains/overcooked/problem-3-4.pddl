; Delicatessen
(define (problem overcooked-problem-3-4)
    (:domain overcooked)
    (:objects
        bread cheese tuna onion potato lettuce tomato mayonnaise - ftype ; Food types
        chopping-board basket grill-pan plate mixing-bowl - rtype ; Receptacle types
        knife  - ttype ; Tool types
        stove deep-fryer mixer - atype ; Appliance types
        slice chop mince - prepare-method ; Preparation methods
        mix - combine-method ; Combine methods
        grill deep-fry - cook-method ; Cooking methods
        bread1 cheese1 tuna1 beef1 chicken1 onion1 potato1 lettuce1 tomato1 pineapple1 mayo1 - food ; Food objects
        board1 pan1 plate1 mixing-bowl1 basket1 - receptacle ; Receptacle objects
        knife1 - tool ; Tool objects
        stove1 mixer1 fryer1 - appliance ; Appliance objects
        start-loc food-loc chop-loc stove-loc fryer-loc plate-loc mix-loc - location ; Locations
    )
    (:init
        ; Type declarations
        (food-type bread bread1)
        (food-type tuna tuna1)
        (food-type cheese cheese1)
        (food-type onion onion1)
        (food-type potato potato1)
        (food-type lettuce lettuce1)
        (food-type tomato tomato1)
        (food-type mayonnaise mayo1)
        (receptacle-type chopping-board board1)
        (receptacle-type plate plate1)
        (receptacle-type mixing-bowl mixing-bowl1)
        (receptacle-type grill-pan pan1)
        (receptacle-type basket basket1)
        (tool-type knife knife1)
        (appliance-type stove stove1)
        (appliance-type mixer mixer1)
        (appliance-type deep-fryer fryer1)
        ; Method declarations
        (has-prepare-method slice chopping-board knife)
        (has-prepare-method mince chopping-board knife)
        (has-prepare-method chop chopping-board knife)
        (has-cook-method grill grill-pan stove)
        (has-cook-method deep-fry basket deep-fryer)
        (has-combine-method mix mixing-bowl mixer)
        ; Initial agent state
        (handempty)
        (agent-at-loc start-loc)
        ; Initial food locations
        (object-at-loc bread1 food-loc)
        (object-at-loc tuna1 food-loc)
        (object-at-loc cheese1 food-loc)
        (object-at-loc beef1 food-loc)
        (object-at-loc onion1 food-loc)
        (object-at-loc potato1 food-loc)
        (object-at-loc chicken1 food-loc)
        (object-at-loc lettuce1 food-loc)
        (object-at-loc tomato1 food-loc)
        (object-at-loc pineapple1 food-loc)
        (object-at-loc mayo1 food-loc)
        ; Receptacle, tool, and appliance locations
        (object-at-loc board1 chop-loc)
        (object-at-loc knife1 chop-loc)
        (object-at-loc pan1 stove-loc)
        (object-at-loc stove1 stove-loc)
        (object-at-loc plate1 plate-loc)
        (object-at-loc mixer1 mix-loc)
        (object-at-loc mixing-bowl1 mix-loc)
        (object-at-loc basket1 fryer-loc)
        ; Whether receptacles are located on appliances
        (in-appliance pan1 stove1)
        (occupied stove1)
        (in-appliance mixing-bowl1 mixer1)
        (occupied mixer1)
        (in-appliance basket1 fryer1 )
        (occupied fryer1)
    )

    ; Goal 1: Tuna sandwich
(:goal
        (exists (?bread - food ?tuna - food ?cheese - food ?lettuce - food ?tomato - food ?mayonnaise - food ?plate - receptacle ?mixing-bowl - receptacle)
            (and (food-type tuna ?tuna)
                 (food-type bread ?bread)
                 (food-type cheese ?cheese)
                 (food-type lettuce ?lettuce)
                 (food-type tomato ?tomato)
                 (food-type mayonnaise ?mayonnaise)
                 (receptacle-type plate ?plate)
                 (combined-with mix ?tuna ?mayonnaise)
                 (prepared slice ?cheese)
                 (prepared slice ?tomato)
                 (prepared slice ?lettuce)
                 (in-receptacle ?bread ?plate)
                 (in-receptacle ?tuna ?plate)
                 (in-receptacle ?lettuce ?plate)
                 (in-receptacle ?tomato ?plate)
                 (in-receptacle ?mayonnaise ?plate)
                 (in-receptacle ?cheese ?plate)))
)

)
