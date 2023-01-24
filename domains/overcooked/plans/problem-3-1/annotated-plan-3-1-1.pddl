(move start-loc food-loc)
(pick-up bread1 food-loc)
(move food-loc stove-loc)
(place-in bread1 pan1 stove-loc)
; First, they place the bread on a pan on the stove.
(pick-up cheese1 food-loc)
(move food-loc chop-loc)
(place-in cheese1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 cheese1 chop-loc)
; (prepared slice cheese1)
; Then, they pick up the cheese and slice it on the chopping board.
(put-down knife1 chop-loc)
(take-out cheese1 board1 chop-loc)
(move chop-loc stove-loc)
(place-in cheese1 pan1 stove-loc)
(cook grill pan1 stove1 stove-loc)
; (cooked-with grill bread1 cheese1)
; Then, they grill the bread and cheese on the stove.
(pick-up pan1 stove-loc)
(move stove-loc plate-loc)
(transfer pan1 plate1 plate-loc)
; (in-receptacle bread1 plate1) (in-receptacle cheese1 plate1)
; Then, they transfer the grilled bread and cheese to the plate.
