(move start-loc food-loc)
(pick-up bread1 food-loc)
; They pick up bread.
(move food-loc plate-loc)
(place-in bread1 plate1 plate-loc)
; They put the bread on a plate.
(move plate-loc food-loc)
(pick-up tuna1 food-loc)
(move food-loc mix-loc)
(place-in tuna1 mixing-bowl1 mix-loc)
; They pick up the tuna and place it in a mixing bowl.
(move mix-loc food-loc)
(pick-up mayo1 food-loc)
(move food-loc mix-loc)
(place-in mayo1 mixing-bowl1 mix-loc)
; They pick up the mayonnaise and place it in the mixing bowl.
(combine mix mixing-bowl1 mixer1 mix-loc)
; They mix the tuna and mayonnaise in the mixing bowl.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc plate-loc)
(transfer mixing-bowl1 plate1 plate-loc)
(put-down mixing-bowl1 plate-loc)
; They add the mixed tuna and mayonnaise to the plate with bread.
(move plate-loc food-loc)
(pick-up cheese1 food-loc)
(move food-loc chop-loc)
(place-in cheese1 board1 chop-loc)
; They pick up cheese and place it on the chopping board.
(move chop-loc food-loc)
(pick-up tomato1 food-loc)
(move food-loc chop-loc)
(place-in tomato1 board1 chop-loc)
; They pick up tomato and place it on the chopping board.
(move chop-loc food-loc)
(pick-up lettuce1 food-loc)
(move food-loc chop-loc)
(place-in lettuce1 board1 chop-loc)
; They pick up lettuce and place it on the chopping board.
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 tomato1 chop-loc)
; They slice the tomato on the chopping board.
(prepare slice board1 knife1 cheese1 chop-loc)
; They slice the cheese on the chopping board.
(prepare slice board1 knife1 lettuce1 chop-loc)
; They slice the lettuce on the chopping board.
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer the sliced cheese, tomato, and lettuce to the plate with bread, tuna, and mayonnaise.

