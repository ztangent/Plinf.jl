(move start-loc food-loc)
(pick-up lettuce1 food-loc)
(move food-loc chop-loc)
(place-in lettuce1 board1 chop-loc)
; They pick up the lettuce and place it on the chopping board.
(move chop-loc food-loc)
(pick-up cheese1 food-loc)
(move food-loc chop-loc)
(place-in cheese1 board1 chop-loc)
; They pick up the cheese and place it on the chopping board.
(move chop-loc food-loc)
(pick-up tomato1 food-loc)
(move food-loc chop-loc)
(place-in tomato1 board1 chop-loc)
; They pick up the tomato and place it on the chopping board.
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
; They place the sliced cheese, tomato and lettuce in a plate.
(move plate-loc food-loc)
(put-down board1 food-loc)
(pick-up chicken1 food-loc)
; They pick up the chicken.
(move food-loc stove-loc)
(place-in chicken1 pan1 stove-loc)
(cook grill pan1 stove1 stove-loc)
; They grill the chicken in a pan on the stove.
(pick-up pan1 stove-loc)
(move stove-loc plate-loc)
(transfer pan1 plate1 plate-loc)
; They transfer the grilled chicken from the pan to the plate.
(move plate-loc food-loc)
(put-down pan1 food-loc)
(pick-up bread1 food-loc)
; They pick up the bread.
(move food-loc plate-loc)
(place-in bread1 plate1 plate-loc)
; They place the bread in the plate with the grilled chicken, sliced cheese, tomato, and lettuce.
