(move start-loc chop-loc)
(pick-up board1 chop-loc)
(move chop-loc food-loc)
(put-down board1 food-loc)
; They move the chopping board to where the food is located.
(pick-up tomato1 food-loc)
(place-in tomato1 board1 food-loc)
; They place tomato in the chopping board.
(pick-up lettuce1 food-loc)
(place-in lettuce1 board1 food-loc)
; They place lettuce in the chopping board.
(move food-loc chop-loc)
(pick-up knife1 chop-loc)
(move chop-loc food-loc)
; They find the knife.
(prepare slice board1 knife1 tomato1 food-loc)
; They slice the tomato.
(prepare slice board1 knife1 lettuce1 food-loc)
; They slice the lettuce.
(put-down knife1 food-loc)
(pick-up cucumber1 food-loc)
(place-in cucumber1 board1 food-loc)
; They place cucumber in the chopping board.
(pick-up knife1 food-loc)
(prepare slice board1 knife1 cucumber1 food-loc)
; They slice the cucumber.
(put-down knife1 food-loc)
; They put down the knife.
(pick-up board1 food-loc)
(move food-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer everything on the chopping board to a plate.
(move plate-loc food-loc)
(put-down board1 food-loc)
; They put down the chopping board.
(pick-up salad-dressing1 food-loc)
; They pick up the salad dressing.
(move food-loc plate-loc)
(place-in salad-dressing1 plate1 plate-loc)
; They add salad dressing to the plate.
(move plate-loc food-loc)
(pick-up onion1 food-loc)
(place-in onion1 board1 food-loc)
; They place onion in the chopping board.
(pick-up knife1 food-loc)
(prepare slice board1 knife1 onion1 food-loc)
; They slice the onion.
(put-down knife1 food-loc)
(pick-up board1 food-loc)
(move food-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer the sliced onion to the plate.
