; Delicatessen
(define (problem overcooked-problem-3-3)
    (:domain overcooked)
    (:objects
        hamburger-bun cheese beef chicken onion potato bacon lettuce tomato pineapple - ftype ; Food types
        chopping-board basket grill-pan plate - rtype ; Receptacle types
        knife - ttype ; Tool types
        stove deep-fryer - atype ; Appliance types
        slice chop mince - prepare-method ; Preparation methods
        grill deep-fry - cook-method ; Cooking methods
        hamburger-bun1 cheese1 beef1 chicken1 onion1 potato1 bacon1 lettuce1 tomato1 pineapple1 - food ; Food objects
        board1 basket1 pan1 plate1 - receptacle ; Receptacle objects
        knife1 - tool ; Tool objects
        stove1 fryer1 - appliance ; Appliance objects
        start-loc food-loc chop-loc fryer-loc stove-loc plate-loc - location ; Locations
    )
    (:init
        ; Type declarations
        (food-type hamburger-bun hamburger-bun1)
        (food-type beef beef1)
        (food-type cheese cheese1)
        (food-type onion onion1)
        (food-type potato potato1)
        (food-type chicken chicken1)
        (food-type bacon bacon1)
        (food-type lettuce lettuce1)
        (food-type tomato tomato1)
        (food-type pineapple pineapple1)
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
        (object-at-loc hamburger-bun1 food-loc)
        (object-at-loc cheese1 food-loc)
        (object-at-loc beef1 food-loc)
        (object-at-loc onion1 food-loc)
        (object-at-loc potato1 food-loc)
        (object-at-loc chicken1 food-loc)
        (object-at-loc bacon1 food-loc)
        (object-at-loc lettuce1 food-loc)
        (object-at-loc tomato1 food-loc)
        (object-at-loc pineapple1 food-loc)
        ; Receptacle, tool, and appliance locations
        (object-at-loc board1 chop-loc)
        (object-at-loc knife1 chop-loc)
        (object-at-loc pan1 stove-loc)
        (object-at-loc stove1 stove-loc)
        (object-at-loc plate1 plate-loc)
        (object-at-loc fryer1 fryer-loc)
        (object-at-loc basket1 fryer-loc)
        ; Whether receptacles are located on appliances
        (in-appliance pan1 stove1)
        (in-appliance basket1 fryer1)
        (occupied stove1)
        (occupied fryer1)
    )
    (:goal
        (exists (?hamburger-bun - food ?beef - food ?cheese - food ?potato - food ?plate - receptacle)
                (and (food-type beef ?beef)
                     (food-type hamburger-bun ?hamburger-bun)
                     (food-type cheese ?cheese)
                     (food-type potato ?potato)
                     (receptacle-type plate ?plate)
                     (prepared slice ?cheese)
                     (prepared slice ?potato)
                     (cooked grill ?beef)
                     (cooked deep-fry ?potato)
                     (in-receptacle ?hamburger-bun ?plate)
                     (in-receptacle ?beef ?plate)
                     (in-receptacle ?cheese ?plate)
                     (in-receptacle ?potato ?plate)))
    )
)
