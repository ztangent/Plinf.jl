(move start-loc food-loc)
(pick-up lettuce1 food-loc)
(move food-loc chop-loc)
(place-in lettuce1 board1 chop-loc)
(move chop-loc food-loc)
(pick-up cheese1 food-loc)
(move food-loc chop-loc)
(place-in cheese1 board1 chop-loc)
(move chop-loc food-loc)
(pick-up tomato1 food-loc)
(move food-loc chop-loc)
(place-in tomato1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 tomato1 chop-loc)
(prepare slice board1 knife1 cheese1 chop-loc)
(prepare slice board1 knife1 lettuce1 chop-loc)
; Pick up the cheese, tomato, and lettuce, then slice them on a chopping board.
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; Place the cheese, tomato and lettuce in a plate.
(move plate-loc food-loc)
(put-down board1 food-loc)
(pick-up chicken1 food-loc)
(move food-loc stove-loc)
(place-in chicken1 pan1 stove-loc)
(cook grill pan1 stove1 stove-loc)
; Get some chicken, then grill it in a pan on the stove.
(pick-up pan1 stove-loc)
(move stove-loc plate-loc)
(transfer pan1 plate1 plate-loc)
; Transfer the grilled chicken from the pan to the plate.
(move plate-loc food-loc)
(put-down pan1 food-loc)
(pick-up bread1 food-loc)
(move food-loc plate-loc)
(place-in bread1 plate1 plate-loc)
; Place bread in the plate with the grilled chicken, sliced cheese, tomato, and lettuce.
