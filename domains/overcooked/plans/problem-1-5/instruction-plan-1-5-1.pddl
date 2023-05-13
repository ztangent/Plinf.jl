(move start-loc chop-loc)
(pick-up board1 chop-loc)
(move chop-loc food-loc)
(put-down board1 food-loc)
(pick-up avocado1 food-loc)
(place-in avocado1 board1 food-loc)
(move food-loc chop-loc)
(pick-up knife1 chop-loc)
(move chop-loc food-loc)
(prepare slice board1 knife1 avocado1 food-loc)
; Pick up the avocado and slice it on the chopping board.
(put-down knife1 food-loc)
(pick-up lettuce1 food-loc)
(place-in lettuce1 board1 food-loc)
(pick-up tomato1 food-loc)
(place-in tomato1 board1 food-loc)
(pick-up cheese1 food-loc)
(place-in cheese1 board1 food-loc)
(pick-up knife1 food-loc)
(prepare chop board1 knife1 lettuce1 food-loc)
(prepare slice board1 knife1 tomato1 food-loc)
(prepare slice board1 knife1 cheese1 food-loc)
; Place lettuce, tomato and cheese on the chopping board, chop the lettuce, then slice the tomato and cheese.
(put-down knife1 food-loc)
(pick-up board1 food-loc)
(move food-loc plate-loc)
(transfer board1 plate1 plate-loc)
; Transfer everything on the chopping board to the plate.
(move plate-loc food-loc)
(put-down board1 food-loc)
(pick-up bacon1 food-loc)
(place-in bacon1 board1 food-loc)
(move food-loc chop-loc)
(pick-up glove1 chop-loc)
(move chop-loc food-loc)
(prepare crumble board1 glove1 bacon1 food-loc)
; Crumble bacon on the chopping board using gloves.
(put-down glove1 food-loc)
(pick-up board1 food-loc)
(move food-loc stove-loc)
(transfer board1 pan1 stove-loc)
(cook grill pan1 stove2 stove-loc)
; Grill the crumbled bacon in a pan on the stove.
(move stove-loc plate-loc)
(put-down board1 plate-loc)
(move plate-loc stove-loc)
(pick-up pan1 stove-loc)
(move stove-loc plate-loc)
(transfer pan1 plate1 plate-loc)
; Transfer the bacon from the pan to the plate.
(move plate-loc food-loc)
(put-down pan1 food-loc)
(pick-up egg1 food-loc)
(move food-loc stove-loc)
(place-in egg1 pot1 stove-loc)
(cook boil pot1 stove1 stove-loc)
; Boil the egg in a pot on the stove.
(pick-up pot1 stove-loc)
(move stove-loc plate-loc)
(transfer pot1 plate1 plate-loc)
; Transfer the egg from the pot to the plate.
(put-down pot1 plate-loc)
(move plate-loc food-loc)
(pick-up salad-dressing1 food-loc)
(move food-loc plate-loc)
(place-in salad-dressing1 plate1 plate-loc)
; Add salad dressing to the plate.
