(move start-loc food-loc)
(pick-up tuna1 food-loc)
(move food-loc chop-loc)
(place-in tuna1 board1 chop-loc)
(pick-up s-knife1 chop-loc)
(prepare slice board1 s-knife1 tuna1 chop-loc)
; They slice the tuna on a chopping board.
(put-down s-knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They place the sliced tuna on a plate.
