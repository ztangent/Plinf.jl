(move start-loc food-loc)
(pick-up tomato1 food-loc)
(move food-loc chop-loc)
(place-in tomato1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 tomato1 chop-loc)
; They place tomato on the chopping board, find a knife, then slice the tomato.
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They put down the knife and transfer the tomato to the plate.
