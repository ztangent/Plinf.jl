(move start-loc food-loc)
(pick-up strawberry1 food-loc)
; They pick up strawberries. This involves moving to the strawberries and picking them up.
(move food-loc mix-loc)
(place-in strawberry1 mixing-bowl1 mix-loc)
; They add the strawberries to the bowl. This involves moving to the mixing bowl and placing the strawberries in it.
(move mix-loc food-loc)
(pick-up chocolate1 food-loc)
(move food-loc mix-loc)
(place-in chocolate1 mixing-bowl1 mix-loc)
; They add chocolate to the bowl. This involves picking up the chocolate and placing it in the mixing bowl.
(combine mix mixing-bowl1 mixer1 mix-loc)
; They mix the chocolate with the strawberries. This involves using the mixer to mix the contents of the mixing bowl.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc plate-loc)
(transfer mixing-bowl1 plate1 plate-loc)
; They transfer the mixed strawberries and chocolate to a plate. This involves picking up the mixing bowl and transferring the contents of the mixing bowl to the plate.
