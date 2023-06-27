(move start-loc chop-loc)
(pick-up board1 chop-loc)
(move chop-loc food-loc)
(put-down board1 food-loc)
(pick-up tomato1 food-loc)
(place-in tomato1 board1 food-loc)
(pick-up lettuce1 food-loc)
(place-in lettuce1 board1 food-loc)
; Move the chopping board to where the food is located, then place tomato and lettuce in the chopping board.
(move food-loc chop-loc)
(pick-up knife1 chop-loc)
(move chop-loc food-loc)
(prepare slice board1 knife1 tomato1 food-loc)
(prepare slice board1 knife1 lettuce1 food-loc)
; Find the knife and slice the tomato and lettuce.
(put-down knife1 food-loc)
(pick-up cucumber1 food-loc)
(place-in cucumber1 board1 food-loc)
(pick-up knife1 food-loc)
(prepare slice board1 knife1 cucumber1 food-loc)
; Place the cucumber in the chopping board, then slice it.
(put-down knife1 food-loc)
(pick-up board1 food-loc)
(move food-loc plate-loc)
(transfer board1 plate1 plate-loc)
; Put down the knife, and transfer everything on the chopping board to a plate.
(move plate-loc food-loc)
(put-down board1 food-loc)
(pick-up salad-dressing1 food-loc)
(move food-loc plate-loc)
(place-in salad-dressing1 plate1 plate-loc)
; Put down the chopping board, pick up the salad dressing and add it to the plate.
(move plate-loc food-loc)
(pick-up onion1 food-loc)
(place-in onion1 board1 food-loc)
(pick-up knife1 food-loc)
(prepare slice board1 knife1 onion1 food-loc)
; Place onion on the chopping board and slice it.
(put-down knife1 food-loc)
(pick-up board1 food-loc)
(move food-loc plate-loc)
(transfer board1 plate1 plate-loc)
; Transfer the sliced onion to the plate.