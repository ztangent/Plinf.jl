(move start-loc food-loc)
(pick-up tomato1 food-loc)
(move food-loc chop-loc)
(place-in tomato1 board1 chop-loc)
; They place the tomato on the chopping board. This involves picking up the tomato, moving to the chopping board, and placing the tomato on the chopping board.
(move chop-loc food-loc)
(pick-up lettuce1 food-loc)
(move food-loc chop-loc)
(place-in lettuce1 board1 chop-loc)
; They place the lettuce on the chopping board. This involves picking up the lettuce, moving to the chopping board, and placing the lettuce on the chopping board.
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 lettuce1 chop-loc)
; They slice the lettuce. This involves picking up the knife, then using the knife to slice the lettuce.
(prepare slice board1 knife1 tomato1 chop-loc)
; They slice the tomato. This involves no additional actions.
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer the sliced lettuce and tomato from the chopping board to the plate. This involves first putting down the knife, then picking up the chopping board, moving to the plate, then transferring the contents of the chopping board to the plate.
