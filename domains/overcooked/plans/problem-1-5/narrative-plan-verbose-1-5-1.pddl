(move start-loc chop-loc)
(pick-up board1 chop-loc)
(move chop-loc food-loc)
(put-down board1 food-loc)
(pick-up avocado1 food-loc)
; They pick up the avocado. This involves moving to the avocado, then picking it up.
(place-in avocado1 board1 food-loc)
(move food-loc chop-loc)
(pick-up knife1 chop-loc)
(move chop-loc food-loc)
(prepare slice board1 knife1 avocado1 food-loc)
; They slice the avocado on the chopping board. This involves placing the avocado on the chopping board, picking up a knife, then slicing the avocado.
(put-down knife1 food-loc)
(pick-up lettuce1 food-loc)
(place-in lettuce1 board1 food-loc)
; They place the lettuce on the chopping board. This involves putting down the knife first, then picking up the lettuce and placing it on the chopping board.
(pick-up tomato1 food-loc)
(place-in tomato1 board1 food-loc)
; They place the tomato on the chopping board. This involves picking up the tomato and placing it on the chopping board.
(pick-up cheese1 food-loc)
(place-in cheese1 board1 food-loc)
; They place the cheese on the chopping board. This involves picking up the cheese and placing it on the chopping board.
(pick-up knife1 food-loc)
(prepare chop board1 knife1 lettuce1 food-loc)
; They chop the lettuce on the chopping board. This involves picking up the knife first, then chopping the lettuce.
(prepare slice board1 knife1 tomato1 food-loc)
; They slice the tomato on the chopping board. This involves no additional actions.
(prepare slice board1 knife1 cheese1 food-loc)
; They slice the cheese on the chopping board. This involves no additional actions.
(put-down knife1 food-loc)
(pick-up board1 food-loc)
(move food-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer everything on the chopping board to the plate. This involves putting down the knife first, then picking up the chopping board and transferring everything on it to the plate.
(move plate-loc food-loc)
(put-down board1 food-loc)
(pick-up bacon1 food-loc)
(place-in bacon1 board1 food-loc)
; They place bacon on the chopping board. This involves first putting down the chopping board, then picking up the bacon and placing it on the chopping board.
(move food-loc chop-loc)
(pick-up glove1 chop-loc)
; They put on gloves. This involves moving to the gloves, then picking them up.
(move chop-loc food-loc)
(prepare crumble board1 glove1 bacon1 food-loc)
; They crumble bacon onto the chopping board. This involves moving to the chopping board, then crumbling the bacon onto it.
(put-down glove1 food-loc)
(pick-up board1 food-loc)
(move food-loc stove-loc)
(transfer board1 pan1 stove-loc)
; They transfer the crumbled bacon from the chopping board to the pan. This involves taking off the gloves, picking up the chopping board, then transferring the bacon to the pan.
(cook grill pan1 stove2 stove-loc)
; They grill the pan on the stove. This involves no additional actions.
(move stove-loc plate-loc)
(put-down board1 plate-loc)
(move plate-loc stove-loc)
(pick-up pan1 stove-loc)
(move stove-loc plate-loc)
(transfer pan1 plate1 plate-loc)
; They transfer the bacon from the pan to the plate. This involves putting down the chopping board first, then picking up the pan and transferring the from the pan to the plate.
(move plate-loc food-loc)
(put-down pan1 food-loc)
(pick-up egg1 food-loc)
; They pick up an egg. This involves moving to the egg, putting down the pan, then picking up the egg.
(move food-loc stove-loc)
(place-in egg1 pot1 stove-loc)
; They place the egg in a pot on the stove. This involves moving to the stove, then placing the egg in the pot.
(cook boil pot1 stove1 stove-loc)
; They boil the pot on the stove. This involves no additional actions.
(pick-up pot1 stove-loc)
(move stove-loc plate-loc)
(transfer pot1 plate1 plate-loc)
; They transfer the egg from the pot to the plate. This involves picking up the pot, then transferring the egg from the pot to the plate.
(put-down pot1 plate-loc)
(move plate-loc food-loc)
(pick-up salad-dressing1 food-loc)
(move food-loc plate-loc)
(place-in salad-dressing1 plate1 plate-loc)
; They add salad dressing to the plate of food. This involves putting down the pot, then picking up the salad dressing and adding it to the plate.
