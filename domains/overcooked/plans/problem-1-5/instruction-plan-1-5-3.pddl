(move start-loc chop-loc)
(pick-up board1 chop-loc)
(move chop-loc food-loc)
(put-down board1 food-loc)
; Bring the chopping board to where the food is located.
(pick-up lettuce1 food-loc)
(place-in lettuce1 board1 food-loc)
(pick-up tomato1 food-loc)
(place-in tomato1 board1 food-loc)
; Place lettuce and tomato on the chopping board.
(move food-loc chop-loc)
(pick-up knife1 chop-loc)
(move chop-loc food-loc)
; Find a knife.
(prepare slice board1 knife1 tomato1 food-loc)
(prepare slice board1 knife1 lettuce1 food-loc)
; Slice the tomato and lettuce.
(put-down knife1 food-loc)
(pick-up cucumber1 food-loc)
(place-in cucumber1 board1 food-loc)
(pick-up onion1 food-loc)
(place-in onion1 board1 food-loc)
; Place cucumber and onion on the chopping board.
(pick-up knife1 food-loc)
(prepare slice board1 knife1 onion1 food-loc)
(prepare slice board1 knife1 cucumber1 food-loc)
; Slice the onion and cucumber.
(put-down knife1 food-loc)
(pick-up board1 food-loc)
(move food-loc plate-loc)
(transfer board1 plate1 plate-loc)
; Transfer the food on the chopping board to the plate.
(put-down board1 plate-loc)
(move plate-loc food-loc)
(pick-up salad-dressing1 food-loc)
(move food-loc plate-loc)
(place-in salad-dressing1 plate1 plate-loc)
; Pick up salad dressing and add some to the plate.
