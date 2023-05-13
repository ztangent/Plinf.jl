(move start-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
; They place flour in the mixing bowl.
(move mix-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
; They place the egg in the mixing bowl.
(move mix-loc food-loc)
(pick-up chocolate1 food-loc)
(move food-loc mix-loc)
(place-in chocolate1 mixing-bowl1 mix-loc)
; They add chocolate to the mixing bowl.
(combine mix mixing-bowl1 mixer1 mix-loc)
; They mix everything in the mixing bowl.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc fryer-loc)
(transfer mixing-bowl1 basket1 fryer-loc)
; They transfer the chocolate, flour, and egg mixture into a fryer basket.
(cook deep-fry basket1 fryer1 fryer-loc)
; They deep fry everything.
(move fryer-loc mix-loc)
(put-down mixing-bowl1 mix-loc)
(move mix-loc fryer-loc)
(pick-up basket1 fryer-loc)
(move fryer-loc plate-loc)
(transfer basket1 plate1 plate-loc)
; They transfer the deep fried food to a plate.
