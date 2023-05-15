(move start-loc food-loc)
(pick-up chocolate1 food-loc)
(move food-loc mix-loc)
(place-in chocolate1 mixing-bowl1 mix-loc)
; Add chocolate to the mixing bowl.
(move mix-loc food-loc)
(pick-up strawberry1 food-loc)
(move food-loc mix-loc)
(place-in strawberry1 mixing-bowl1 mix-loc)
; Add strawberry to the mixing bowl.
(combine mix mixing-bowl1 mixer1 mix-loc)
; Mix the strawberry and chocolate together.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc plate-loc)
(transfer mixing-bowl1 plate1 plate-loc)
; Transfer the contents of the mixing bowl to the plate.
