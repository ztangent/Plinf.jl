(move start-loc food-loc)
(pick-up lettuce1 food-loc)
(move food-loc chop-loc)
(place-in lettuce1 board1 chop-loc)
; They place the lettuce in the chopping board. This involves picking up the lettuce, moving to the chopping board, and placing the lettuce on the chopping board.
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 lettuce1 chop-loc)
(put-down knife1 chop-loc)
; They slice the lettuce with a knife. This involves picking up the knife, slicing the lettuce, and putting down the knife.
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer the lettuce from the chopping board to the plate. This involves picking up the chopping board, moving to the plate, and transferring the lettuce from the chopping board to the plate.
