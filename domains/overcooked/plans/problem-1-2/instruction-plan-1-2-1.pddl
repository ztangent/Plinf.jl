(move start-loc food-loc)
(pick-up tomato1 food-loc)
(move food-loc chop-loc)
(place-in tomato1 board1 chop-loc)
(move chop-loc food-loc)
(pick-up lettuce1 food-loc)
(move food-loc chop-loc)
(place-in lettuce1 board1 chop-loc)
; Place the tomato and lettuce on the chopping board.
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 lettuce1 chop-loc)
(prepare slice board1 knife1 tomato1 chop-loc)
; Slice the lettuce and tomato.
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; Transfer the sliced lettuce and tomato from the chopping board to the plate.
