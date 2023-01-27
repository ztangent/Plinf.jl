(move start-loc food-loc)
(pick-up strawberry1 food-loc)
(move food-loc mix-loc)
(place-in strawberry1 mixing-bowl1 mix-loc)
; They pick up strawberries and add to the bowl.
(move mix-loc food-loc)
(pick-up chocolate1 food-loc)
(move food-loc mix-loc)
(place-in chocolate1 mixing-bowl1 mix-loc)
(combine mix mixing-bowl1 mixer1 mix-loc)
; They add chocolate to the bowl and mix with the strawberries.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc plate-loc)
(transfer mixing-bowl1 plate1 plate-loc)
; They transfer the strawberries and chocolate to the plate.
