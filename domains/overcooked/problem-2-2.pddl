; Sushi bar
(define (problem overcooked-problem-2-2)
    (:domain overcooked)
    ;add bowl
    (:objects
        tuna salmon rice - ftype ; Food types
        chopping-board pot plate grill-pan bowl - rtype ; Receptacle types
        knife - ttype ; Tool types
        stove - atype ; Appliance types
        slice - prepare-method ; Preparation methods
        grill boil - cook-method ; Cooking methods
        tuna1 salmon1 rice1 - food ; Food objects
        board1 plate1 pan1 bowl1 - receptacle ; Receptacle objects
        knife1 - tool ; Tool objects
        stove1 - appliance ; Appliance objects
        start-loc food-loc chop-loc stove-loc plate-loc bowl-loc - location ; Locations
    )
    (:init
        ; Type declarations
        (food-type tuna tuna1)
        (food-type salmon salmon1)
        (food-type rice rice1)
        (receptacle-type chopping-board board1)
        (receptacle-type grill-pan pan1)
        (receptacle-type plate plate1)
        (receptacle-type bowl bowl1)
        (tool-type knife knife1)
        (appliance-type stove stove1)
        ; Method declarations
        (has-prepare-method slice chopping-board knife)
        (has-cook-method grill grill-pan stove)
        (has-cook-method boil pot stove)
        ; Initial agent state
        (handempty)
        (agent-at-loc start-loc)
        ; Initial food locations
        (object-at-loc tuna1 food-loc)
        (object-at-loc salmon1 food-loc)
        (object-at-loc rice1 food-loc)
        ; Receptacle, tool, and appliance locations
        (object-at-loc board1 chop-loc)
        (object-at-loc knife1 chop-loc)
        (object-at-loc pan1 stove-loc)
        (object-at-loc stove1 stove-loc)
        (object-at-loc plate1 plate-loc)
        (object-at-loc bowl1 bowl-loc)
        ; Whether receptacles are located on appliances
        (in-appliance pan1 stove1)
        (occupied stove1)
    )
    
    ;Goal 1: Tuna + rice sushi
    (:goal
        (exists (?tuna - food ?rice - food ?plate - receptacle)
                (and (food-type tuna ?tuna)
                     (food-type rice ?rice)
                     (receptacle-type plate ?plate)
                     (prepared slice ?tuna)
                     (cooked boil ?rice)
                     (in-receptacle ?rice ?plate)
                     (in-receptacle ?tuna ?plate)))
  
)
