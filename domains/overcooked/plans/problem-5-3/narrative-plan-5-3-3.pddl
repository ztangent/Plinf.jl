(move start-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
(move mix-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
(combine mix mixing-bowl1 mixer1 mix-loc)
; They combine egg and flour into a dough in the mixing bowl.
(move mix-loc food-loc)
(pick-up strawberry1 food-loc)
(move food-loc mix-loc)
(place-in strawberry1 mixing-bowl1 mix-loc)
; They pick up strawberry and add it to the mixing bowl.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc fryer-loc)
(transfer mixing-bowl1 basket1 fryer-loc)
; They transfer the contents of the mixing bowl to the frying basket.
(move fryer-loc food-loc)
(put-down mixing-bowl1 food-loc)
(move food-loc fryer-loc)
(cook deep-fry basket1 fryer1 fryer-loc)
; They put away the mixing bowl, then deep fry the contents of the basket.
(pick-up basket1 fryer-loc)
(move fryer-loc plate-loc)
(transfer basket1 plate1 plate-loc)
; They transfer the contents of the frying basket to a plate.
