(move start-loc food-loc)
(pick-up tomato1 food-loc)
(move food-loc chop-loc)
(place-in tomato1 board1 chop-loc)
(move chop-loc food-loc)
(pick-up lettuce1 food-loc)
(move food-loc chop-loc)
(place-in lettuce1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 lettuce1 chop-loc)
(prepare slice board1 knife1 tomato1 chop-loc)
; (prepared slice lettuce1) (prepared slice tomato1)
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; (in-receptacle lettuce1 plate1) (in-receptacle tomato1 plate1)
