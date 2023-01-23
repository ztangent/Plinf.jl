; Sushi bar
(define (problem overcooked-problem-2-5)
    (:domain overcooked)
    (:objects
        tuna salmon avocado soybean crab rice nori cucumber - ftype ; Food types
        chopping-board pot plate grill-pan - rtype ; Receptacle types
        knife sashimi-knife - ttype ; Tool types
        stove - atype ; Appliance types
        slice - prepare-method ; Preparation methods
        boil grill - cook-method ; Cooking methods
        tuna1 salmon1 soybean1 avocado1 crab1 rice1 nori1 cucumber1 - food ; Food objects
        board1 pot1 plate1 pan1 - receptacle ; Receptacle objects
        knife1 s-knife1 - tool ; Tool objects
        stove1 stove2 - appliance ; Appliance objects
        start-loc food-loc chop-loc stove-loc plate-loc - location ; Locations
    )
    (:init
        ; Type declarations
        (food-type crab crab1)
        (food-type rice rice1)
        (food-type nori nori1)
        (food-type cucumber cucumber1)
        (food-type avocado avocado1)
        (food-type tuna tuna1)
        (food-type salmon salmon1)
        (food-type soybean soybean1)
        (receptacle-type chopping-board board1)
        (receptacle-type pot pot1)
        (receptacle-type grill-pan pan1)
        (receptacle-type plate plate1)
        (tool-type knife knife1)
        (tool-type sashimi-knife s-knife1)
        (appliance-type stove stove1)
        (appliance-type stove stove2)
        ; Method declarations
        (has-prepare-method slice chopping-board sashimi-knife)
        (has-prepare-method slice chopping-board knife)
        (has-cook-method boil pot stove)
        (has-cook-method grill grill-pan stove)
        ; Initial agent state
        (handempty)
        (agent-at-loc start-loc)
        ; Initial food locations
        (object-at-loc crab1 food-loc)
        (object-at-loc rice1 food-loc)
        (object-at-loc nori1 food-loc)
        (object-at-loc cucumber1 food-loc)
        (object-at-loc tuna1 food-loc)
        (object-at-loc salmon1 food-loc)
        (object-at-loc avocado1 food-loc)
        (object-at-loc soybean1 food-loc)
        ; Receptacle, tool, and appliance locations
        (object-at-loc board1 chop-loc)
        (object-at-loc knife1 chop-loc)
        (object-at-loc s-knife1 chop-loc)
        (object-at-loc pot1 stove-loc)
        (object-at-loc pan1 stove-loc)
        (object-at-loc stove1 stove-loc)
        (object-at-loc stove2 stove-loc)
        (object-at-loc plate1 plate-loc)
        ; Whether receptacles are located on appliances
        (in-appliance pot1 stove1)
        (in-appliance pan1 stove2)
        (occupied stove1)
        (occupied stove2)
    )
    (:goal
        (exists (?avocado - food  ?nori - food ?rice - food ?crab - food ?cucumber - food ?plate - receptacle)
                (and (food-type nori ?nori)
                     (food-type rice ?rice)
                     (food-type crab ?crab)
                     (food-type cucumber ?cucumber)
                     (food-type avocado ?avocado)
                     (receptacle-type plate ?plate)
                     (prepared slice ?crab)
                     (cooked boil ?rice)
                     (in-receptacle ?nori ?plate)
                     (in-receptacle ?rice ?plate)
                     (in-receptacle ?cucumber ?plate)
                     (in-receptacle ?avocado ?plate)
                     (in-receptacle ?crab ?plate)))
    )
)
