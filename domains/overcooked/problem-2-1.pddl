; Sushi bar
(define (problem overcooked-problem-2-1)
    (:domain overcooked)
    (:objects
        tuna salmon crab - ftype ; Food types
        chopping-board plate - rtype ; Receptacle types
        sashimi-knife - ttype ; Tool types
        slice - prepare-method ; Preparation methods
        tuna1 salmon1 crab1 - food ; Food objects
        board1 plate1 - receptacle ; Receptacle objects
        s-knife1 - tool ; Tool objects
        start-loc food-loc chop-loc plate-loc - location ; Locations
    )
    (:init
        ; Type declarations
        (food-type tuna tuna1)
        (food-type salmon salmon1)
        (food-type crab crab1)
        (receptacle-type chopping-board board1)
        (receptacle-type plate plate1)
        (tool-type sashimi-knife s-knife1)
        ; Method declarations
        (has-prepare-method slice chopping-board sashimi-knife)
        ; Initial agent state
        (handempty)
        (agent-at-loc start-loc)
        ; Initial food locations
        (object-at-loc tuna1 food-loc)
        (object-at-loc salmon1 food-loc)
        (object-at-loc crab1 food-loc)

        ; Receptacle, tool, and appliance locations
        (object-at-loc board1 chop-loc)
        (object-at-loc s-knife1 chop-loc)
        (object-at-loc plate1 plate-loc)
        ; Whether receptacles are located on appliances
    )
    (:goal
        (exists (?salmon - food ?tuna - food ?plate - receptacle)
                (and (food-type tuna ?tuna)
                     (receptacle-type plate ?plate)
                     (prepared slice ?tuna)
                     (in-receptacle ?tuna ?plate)))
    )
)
