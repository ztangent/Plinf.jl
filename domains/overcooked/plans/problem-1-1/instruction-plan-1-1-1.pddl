(move start-loc food-loc)
(pick-up lettuce1 food-loc)
(move food-loc chop-loc)
(place-in lettuce1 board1 chop-loc)
; Place the lettuce on the chopping board.
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 lettuce1 chop-loc)
(put-down knife1 chop-loc)
; Slice the lettuce.
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; Transfer the lettuce to the plate.
