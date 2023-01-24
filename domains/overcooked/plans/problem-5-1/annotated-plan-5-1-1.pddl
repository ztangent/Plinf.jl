(move start-loc food-loc)
(pick-up strawberry1 food-loc)
(move food-loc mix-loc)
(place-in strawberry1 mixing-bowl1 mix-loc)
; First, they pick up strawberries and add to the bowl.
(move mix-loc food-loc)
(pick-up chocolate1 food-loc)
(move food-loc mix-loc)
(place-in chocolate1 mixing-bowl1 mix-loc)
(combine mix mixing-bowl1 mixer1 mix-loc)
; (combined-with mix chocolate1 strawberry1)
; Then, they add chocolate to the bowl and mix with the strawberries.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc plate-loc)
(transfer mixing-bowl1 plate1 plate-loc)
; (in-receptacle chocolate1 plate1) (in-receptacle strawberry1 plate1)
; Then, they transfer the strawberries and chocolate to the plate.
