(move start-loc food-loc)
(pick-up orange1 food-loc)
(move food-loc chop-loc)
(place-in orange1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 orange1 chop-loc)
; They slice orange on the chopping board.
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer the sliced orange to the plate.
