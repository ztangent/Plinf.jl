(move start-loc chop-loc)
(pick-up board1 chop-loc)
(move chop-loc food-loc)
(put-down board1 food-loc)
; They move the chopping board to where the food is located.
(pick-up cucumber1 food-loc)
(place-in cucumber1 board1 food-loc)
; They place the cucumber on the chopping board.
(pick-up onion1 food-loc)
(place-in onion1 board1 food-loc)
; They place the onion on the chopping board.
(move food-loc chop-loc)
(pick-up knife1 chop-loc)
(move chop-loc food-loc)
(prepare chop board1 knife1 onion1 food-loc)
; They pick up the knife and chop the onion.
(prepare chop board1 knife1 cucumber1 food-loc)
(put-down knife1 food-loc)
; They chop the cucumber then put down the knife.
(pick-up tomato1 food-loc)
(place-in tomato1 board1 food-loc)
(pick-up olive1 food-loc)
(place-in olive1 board1 food-loc)
(pick-up knife1 food-loc)
(prepare chop board1 knife1 tomato1 food-loc)
(prepare chop board1 knife1 olive1 food-loc)
(put-down knife1 food-loc)
; They place the tomato and olive on the chopping board, then chop them.
(move food-loc chop-loc)
(pick-up glove1 chop-loc)
(move chop-loc food-loc)
(put-down glove1 food-loc)
(pick-up feta-cheese1 food-loc)
(place-in feta-cheese1 board1 food-loc)
(pick-up glove1 food-loc)
(prepare crumble board1 glove1 feta-cheese1 food-loc)
; They find and put on gloves, then crumble feta cheese on the chopping board.
(put-down glove1 food-loc)
(pick-up board1 food-loc)
(move food-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer everything on the chopping board to the plate.
