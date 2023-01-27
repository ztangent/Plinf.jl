(move start-loc food-loc)
(pick-up lettuce1 food-loc)
(move food-loc chop-loc)
(place-in lettuce1 board1 chop-loc)
; First, they place the lettuce in the chopping board.
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 lettuce1 chop-loc)
(put-down knife1 chop-loc)
; Next, they slice the lettuce with a knife.
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They then transfer the lettuce from the chopping board to the plate.