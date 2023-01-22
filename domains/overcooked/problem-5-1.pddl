; Patisserie
(define (problem overcooked-problem-5-1)
    (:domain overcooked)
    ;Add glass
    (:objects
        chocolate strawberry orange peach grape apple - ftype ; Food types
        chopping-board mixing-bowl plate glass - rtype ; Receptacle types
        knife - ttype ; Tool types
        mixer - atype ; Appliance types
        mix - combine-method ; Combine methods
        slice - prepare-method ; Preparation methods
        chocolate1 strawberry1 orange1 peach1 grape1 apple1 - food ; Food objects
        board1 mixing-bowl1 plate1 glass1 - receptacle ; Receptacle objects
        knife1 - tool ; Tool types
        mixer1 - appliance ; Appliance objects
        start-loc food-loc mix-loc chop-loc plate-loc glass-loc - location ; Locations
    )
    (:init
        ; Type declarations
        (food-type chocolate chocolate1)
        (food-type strawberry strawberry1)
        (food-type peach peach1)
        (food-type orange orange1)
        (food-type grape grape1)
        (food-type apple apple1)
        (tool-type knife knife1)
        (receptacle-type mixing-bowl mixing-bowl1)
        (receptacle-type plate plate1)
        (receptacle-type chopping-board board1)
        (receptacle-type glass glass1)
        (appliance-type mixer mixer1)
        ; Method declarations
        (has-combine-method mix mixing-bowl mixer)
        (has-prepare-method slice chopping-board knife)
        ; Initial agent state
        (handempty)
        (agent-at-loc start-loc)
        ; Initial food locations
        (object-at-loc chocolate1 food-loc)
        (object-at-loc strawberry1 food-loc)
        (object-at-loc peach1 food-loc)
        (object-at-loc orange1 food-loc)
        (object-at-loc grape1 food-loc)
        (object-at-loc apple1 food-loc)
        ; Receptacle, tool, and appliance locations
        (object-at-loc board1 chop-loc)
        (object-at-loc knife1 chop-loc)
        (object-at-loc mixer1 mix-loc)
        (object-at-loc mixing-bowl1 mix-loc)
        (object-at-loc plate1 plate-loc)
        (object-at-loc glass1 glass-loc)
        ; Whether receptacles are located on appliances
        (in-appliance mixing-bowl1 mixer1)
        (occupied mixer1)
    )
    (:goal   
        (exists (?chocolate - food ?strawberry - food ?plate - receptacle)
                (and (food-type chocolate ?chocolate)
                     (food-type strawberry ?strawberry)
                     (receptacle-type plate ?plate)
                     (combined-with mix ?chocolate ?strawberry)
                     (in-receptacle ?chocolate ?plate)
                     (in-receptacle ?strawberry ?plate)))
    )
)
