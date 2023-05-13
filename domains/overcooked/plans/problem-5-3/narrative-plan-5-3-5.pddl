(move start-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
(move mix-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
; They add flour and egg in the mixing bowl.
(move mix-loc food-loc)
(pick-up chocolate1 food-loc)
(move food-loc mix-loc)
(place-in chocolate1 mixing-bowl1 mix-loc)
(combine mix mixing-bowl1 mixer1 mix-loc)
; They place chocolate in the mixing bowl, then mix the contents with a mixer.
(move mix-loc food-loc)
(pick-up strawberry1 food-loc)
(move food-loc mix-loc)
(place-in strawberry1 mixing-bowl1 mix-loc)
; They add strawberry to the mixing bowl.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc fryer-loc)
(transfer mixing-bowl1 basket1 fryer-loc)
; They transfer everything in the mixing bowl to the frying basket.
(cook deep-fry basket1 fryer1 fryer-loc)
; They deep fry the basket in the fryer.
(move fryer-loc food-loc)
(put-down mixing-bowl1 food-loc)
(move food-loc fryer-loc)
(pick-up basket1 fryer-loc)
(move fryer-loc plate-loc)
(transfer basket1 plate1 plate-loc)
; They transfer the fried food to a plate.
