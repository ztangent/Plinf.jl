(move start-loc food-loc)
(pick-up bread1 food-loc)
; They pick up the bread. This involves moving to the bread and then picking it up.
(move food-loc plate-loc)
(place-in bread1 plate1 plate-loc)
; They place the bread on the plate. This involves moving to the plate and then placing the bread on it.
(move plate-loc food-loc)
(pick-up ham1 food-loc)
; They pick up ham. This involves moving to the ham and then picking it up.
(move food-loc chop-loc)
(place-in ham1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 ham1 chop-loc)
; They slice the ham on the chopping board. This involves placing the ham on the chopping board, picking up the knife, and slicing the ham.
(put-down knife1 chop-loc)
(move chop-loc food-loc)
(pick-up cheese1 food-loc)
; They pick up cheese. This involves putting down the knife first, moving to the cheese, and then picking it up.
(move food-loc chop-loc)
(place-in cheese1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 cheese1 chop-loc)
; They slice the cheese on the chopping board. This involves placing the cheese on the chopping board, picking up the knife, and slicing the cheese.
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer the sliced ham and cheese to the plate. This involves putting down the knife first, picking up the chopping board, moving to the plate, and then transferring the ham and cheese to the plate.
(move plate-loc chop-loc)
(put-down board1 chop-loc)
(move chop-loc food-loc)
(pick-up mayo1 food-loc)
(move food-loc plate-loc)
(place-in mayo1 plate1 plate-loc)
; They add mayonnaise to the plate with the bread and sliced ham and cheese. This involves putting down the board first, picking up the mayonnaise, moving to the plate, and then placing the mayonnaise in the plate.
