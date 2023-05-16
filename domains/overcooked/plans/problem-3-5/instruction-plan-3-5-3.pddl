(move start-loc food-loc)
(pick-up chicken1 food-loc)
(move food-loc fryer-loc)
(place-in chicken1 basket1 fryer-loc)
(cook deep-fry basket1 fryer1 fryer-loc)
; Place chicken in the fryer and deep fry it.
(pick-up basket1 fryer-loc)
(move fryer-loc plate-loc)
(transfer basket1 plate1 plate-loc)
; Place the fried chicken on a plate.
