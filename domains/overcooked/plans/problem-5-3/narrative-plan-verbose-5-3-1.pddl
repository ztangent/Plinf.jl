(move start-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
; They place flour in the mixing bowl. This involves picking up the flour, moving to the mixing bowl, and placing the flour in the mixing bowl.
(move mix-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
; They place the egg in the mixing bowl. This involves picking up the egg, moving to the mixing bowl, and placing the egg in the mixing bowl.
(move mix-loc food-loc)
(pick-up chocolate1 food-loc)
(move food-loc mix-loc)
(place-in chocolate1 mixing-bowl1 mix-loc)
; They add chocolate to the mixing bowl. This involves picking up the chocolate, moving to the mixing bowl, and placing the chocolate in the mixing bowl.
(combine mix mixing-bowl1 mixer1 mix-loc)
; They mix everything in the mixing bowl. This involves no additional actions.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc fryer-loc)
(transfer mixing-bowl1 basket1 fryer-loc)
; They transfer the chocolate, flour, and egg mixture into a fryer basket. This involves picking up the mixing bowl, moving to the fryer, and transferring the contents of the mixing bowl to the fryer basket.
(cook deep-fry basket1 fryer1 fryer-loc)
; They deep fry everything. This involves no additional actions.
(move fryer-loc mix-loc)
(put-down mixing-bowl1 mix-loc)
(move mix-loc fryer-loc)
(pick-up basket1 fryer-loc)
(move fryer-loc plate-loc)
(transfer basket1 plate1 plate-loc)
; They transfer the deep fried food to a plate. This involves first putting down the mixing bowl somewhere convenient, then picking up the fryer basket, moving to the plate, and transferring the contents of the fryer basket to the plate.
