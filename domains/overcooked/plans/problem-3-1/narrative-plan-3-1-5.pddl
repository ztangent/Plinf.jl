(move start-loc food-loc)
(pick-up ham1 food-loc)
(move food-loc chop-loc)
(place-in ham1 board1 chop-loc)
; They place ham on the chopping board.
(move chop-loc food-loc)
(pick-up cheese1 food-loc)
(move food-loc chop-loc)
(place-in cheese1 board1 chop-loc)
; They place cheese on the chopping board
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 ham1 chop-loc)
(prepare slice board1 knife1 cheese1 chop-loc)
; They slice the ham and cheese.
(put-down knife1 chop-loc)
(move chop-loc food-loc)
(pick-up bread1 food-loc)
(move food-loc stove-loc)
(place-in bread1 pan1 stove-loc)
; They place bread in the pan on the stove.
(move stove-loc chop-loc)
(pick-up board1 chop-loc)
(move chop-loc stove-loc)
(transfer board1 pan1 stove-loc)
; They transfer the ham and cheese from the chopping board to the pan.
(cook grill pan1 stove1 stove-loc)
; They grill the pan on the stove.
(move stove-loc chop-loc)
(put-down board1 chop-loc)
(move chop-loc stove-loc)
(pick-up pan1 stove-loc)
(move stove-loc plate-loc)
(transfer pan1 plate1 plate-loc)
; Thy transfer the food from the pan to the plate.
