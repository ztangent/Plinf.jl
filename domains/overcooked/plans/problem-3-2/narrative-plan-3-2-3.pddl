(move start-loc food-loc)
(pick-up ham1 food-loc)
(move food-loc chop-loc)
(place-in ham1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 ham1 chop-loc)
; They pick up ham, then slice it on the chopping board.
(put-down knife1 chop-loc)
(move chop-loc food-loc)
(pick-up bread1 food-loc)
(move food-loc plate-loc)
(place-in bread1 plate1 plate-loc)
; They find bread and place it on a plate.
(move plate-loc chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer the ham to the plate.
(put-down board1 plate-loc)
(move plate-loc food-loc)
(pick-up mayo1 food-loc)
(move food-loc plate-loc)
(place-in mayo1 plate1 plate-loc)
; They find mayonnaise and add it to the plate.
