(move start-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
(move mix-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
(combine mix mixing-bowl1 mixer1 mix-loc)
; They mix egg and flour in the mixing bowl.
(move mix-loc food-loc)
(pick-up grape1 food-loc)
(move food-loc mix-loc)
(place-in grape1 mixing-bowl1 mix-loc)
; They add grapes to the mixing bowl.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc fryer-loc)
(transfer mixing-bowl1 basket1 fryer-loc)
(cook deep-fry basket1 fryer1 fryer-loc)
; They transfer everything from the mixing bowl to the fryer basket, then deep fry them in the fryer.
(move fryer-loc mix-loc)
(put-down mixing-bowl1 mix-loc)
(move mix-loc fryer-loc)
(pick-up basket1 fryer-loc)
(move fryer-loc plate-loc)
(transfer basket1 plate1 plate-loc)
; They transfer the deep-fried food on a plate.