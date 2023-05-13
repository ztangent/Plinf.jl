(move start-loc food-loc)
(pick-up cucumber1 food-loc)
(move food-loc chop-loc)
(place-in cucumber1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 cucumber1 chop-loc)
; They place the cucumber in the chopping board and slice it.
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer the cucumber slices to the plate.
(move plate-loc food-loc)
(put-down board1 food-loc)
(pick-up salad-dressing1 food-loc)
(move food-loc plate-loc)
(place-in salad-dressing1 plate1 plate-loc)
; They find salad dressing and add it to the plate.
