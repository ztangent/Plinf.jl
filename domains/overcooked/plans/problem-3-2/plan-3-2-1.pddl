(move start-loc food-loc)
(pick-up bread1 food-loc)
(move food-loc plate-loc)
(place-in bread1 plate1 plate-loc)
(move plate-loc food-loc)
(pick-up cheese1 food-loc)
(move food-loc chop-loc)
(place-in cheese1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 cheese1 chop-loc)
(put-down knife1 chop-loc)
(move chop-loc food-loc)
(pick-up ham1 food-loc)
(move food-loc chop-loc)
(place-in ham1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 ham1 chop-loc)
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; (in-receptacle ham1 plate1) (in-receptacle cheese1 plate1)
(move plate-loc chop-loc)
(put-down board1 chop-loc)
(move chop-loc food-loc)
(pick-up mayo1 food-loc)
(move food-loc plate-loc)
(place-in mayo1 plate1 plate-loc)
; (in-receptacle bread1 plate1) (in-receptacle mayo1 plate1)