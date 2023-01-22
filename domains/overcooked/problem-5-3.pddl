; Patisserie
(define (problem overcooked-problem-5-3)
    (:domain overcooked)
    (:objects
        egg honey sugar flour chocolate strawberry apple - ftype ; Food types
        mixing-bowl plate chopping-board basket - rtype ; Receptacle types
        mixer deep-fryer - atype ; Appliance types
        mix - combine-method ; Combination methods
        slice - prepare-method; Preparation methods
        deep-fry - cook-method ; Cooking methods
        knife - ttype ; Tool types
        egg1 honey1 sugar1 flour1 chocolate1 strawberry1 apple1 - food ; Food objects
        mixing-bowl1 plate1 basket1 board1 - receptacle ; Receptacle objects
        mixer1 fryer1 - appliance ; Appliance objects
        knife1 - tool ; Tool objects 
        start-loc food-loc chop-loc mix-loc fryer-loc plate-loc - location ; Locations
    )
    (:init
        ; Type declarations
        (food-type honey honey1)
        (food-type flour flour1)
        (food-type egg egg1)
        (food-type chocolate chocolate1)
        (food-type strawberry strawberry1)
        (food-type apple apple1)
        (food-type sugar sugar1)
        (receptacle-type mixing-bowl mixing-bowl1)
        (receptacle-type plate plate1)
        (receptacle-type basket basket1)
        (receptacle-type chopping-board board1)
        (tool-type knife knife1)
        (appliance-type deep-fryer fryer1)
        (appliance-type mixer mixer1)
        ; Method declarations
        (has-combine-method mix mixing-bowl mixer)
        (has-cook-method deep-fry basket deep-fryer)
        (has-prepare-method slice chopping-board knife)
        ; Initial agent state
        (handempty)
        (agent-at-loc start-loc)
        ; Initial food locations
        (object-at-loc honey1 food-loc)
        (object-at-loc flour1 food-loc)
        (object-at-loc egg1 food-loc)
        (object-at-loc chocolate1 food-loc)
        (object-at-loc strawberry1 food-loc)
        (object-at-loc apple1 food-loc)
        (object-at-loc sugar1 food-loc)
        ; Receptacle, tool, and appliance locations
        (object-at-loc knife1 chop-loc)
        (object-at-loc board1 chop-loc)
        (object-at-loc mixer1 mix-loc)
        (object-at-loc mixing-bowl1 mix-loc)
        (object-at-loc basket1 fryer-loc)
        (object-at-loc plate1 plate-loc)
        (object-at-loc fryer1 fryer-loc)
        ; Whether receptacles are located on appliances
        (in-appliance mixing-bowl1 mixer1)
        (in-appliance basket1 fryer1)
        (occupied mixer1)
        (occupied fryer1)
    )
    (:goal
            (exists (?egg - food ?chocolate - food ?flour - food ?plate - receptacle)
                    (and (food-type egg ?egg)
                         (food-type flour ?flour)
                         (food-type chocolate ?chocolate)
                         (receptacle-type plate ?plate)
                         (combined-with mix ?egg ?flour)
                         (combined-with mix ?flour ?chocolate)
                         (cooked-with deep-fry ?egg ?flour)
                         (cooked-with deep-fry ?flour ?chocolate)
                         (in-receptacle ?egg ?plate)
                         (in-receptacle ?chocolate ?plate)
                         (in-receptacle ?flour ?plate)))
    )
)
