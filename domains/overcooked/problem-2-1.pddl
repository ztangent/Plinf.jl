; Sushi bar
(define (problem overcooked-problem-2-1)
    (:domain overcooked)
    (:objects
        tuna salmon - ftype ; Food types
        chopping-board plate grill-pan - rtype ; Receptacle types
        sashimi-knife - ttype ; Tool types
        stove - atype ; Appliance types 
        slice - prepare-method ; Preparation methods
        grill - cook-method ; Cook methods
        tuna1 salmon1 - food ; Food objects
        board1 plate1 pan1 - receptacle ; Receptacle objects
        s-knife1 - tool ; Tool objects
        stove1 - appliance ; Appliance objects
        start-loc stove-loc food-loc chop-loc plate-loc - location ; Locations
    )
    (:init
        ; Type declarations
        (food-type tuna tuna1)
        (food-type salmon salmon1)
        (receptacle-type chopping-board board1)
        (receptacle-type plate plate1)
        (receptacle-type grill-pan pan1)
        (tool-type sashimi-knife s-knife1)
        (appliance-type stove stove1)
        ; Method declarations
        (has-prepare-method slice chopping-board sashimi-knife)
        (has-cook-method grill grill-pan stove)
        ; Initial agent state
        (handempty)
        (agent-at-loc start-loc)
        ; Initial food locations
        (object-at-loc tuna1 food-loc)
        (object-at-loc salmon1 food-loc)
        ; Receptacle, tool, and appliance locations
        (object-at-loc board1 chop-loc)
        (object-at-loc s-knife1 chop-loc)
        (object-at-loc plate1 plate-loc)
        (object-at-loc pan1 stove-loc)
        (object-at-loc stove1 stove-loc)
        ; Whether receptacles are located on appliances
        (in-appliance pan1 stove1)
        (occupied stove1)
    )
    ; Goal 1: Tuna Sashimi
    (:goal 
        (exists (?tuna - food ?plate - receptacle)
                (and (food-type tuna ?tuna)
                     (receptacle-type plate ?plate)
                     (prepared slice ?tuna)
                     (in-receptacle ?tuna ?plate)))
    )

)

