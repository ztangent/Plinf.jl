(move start-loc food-loc)
(pick-up tuna1 food-loc)
(move food-loc chop-loc)
(place-in tuna1 board1 chop-loc)
(pick-up s-knife1 chop-loc)
(prepare slice board1 s-knife1 tuna1 chop-loc)
; They slice the tuna on a chopping board. This involves picking up the tuna, placing it on the chopiing board, picking up the knife, and slicing the tuna.
(put-down s-knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They place the sliced tuna on a plate. This involves first putting down the knife, then picking up the chopping board, moving to the plate, and transferring the tuna from the chopping board to the plate.
