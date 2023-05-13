(move start-loc chop-loc)
(pick-up board1 chop-loc)
(move chop-loc food-loc)
(put-down board1 food-loc)
; They move the chopping board to where the food is located. This involves picking up the chopping board, moving it to the food, and putting it down.
(pick-up cucumber1 food-loc)
(place-in cucumber1 board1 food-loc)
; They place the cucumber on the chopping board. This involves picking up the cucumber and placing it on the chopping board.
(pick-up onion1 food-loc)
(place-in onion1 board1 food-loc)
; They place the onion on the chopping board. This involves picking up the onion and placing it on the chopping board.
(move food-loc chop-loc)
(pick-up knife1 chop-loc)
; They pick up the knife. This involves moving to the knife, then picking it up.
(move chop-loc food-loc)
(prepare chop board1 knife1 onion1 food-loc)
; They chop the onion. This involves moving to the onion, then chopping it.
(prepare chop board1 knife1 cucumber1 food-loc)
; They chop the cucumber. This involves no additional actions.
(put-down knife1 food-loc)
; They put down the knife. This involves no additional actions.
(pick-up tomato1 food-loc)
(place-in tomato1 board1 food-loc)
; They place the tomato on the chopping board. This involves picking up the tomato and placing it on the chopping board.
(pick-up olive1 food-loc)
(place-in olive1 board1 food-loc)
; They place the olive on the chopping board. This involves picking up the olive and placing it on the chopping board.
(pick-up knife1 food-loc)
(prepare chop board1 knife1 tomato1 food-loc)
; They chop the tomato. This involves picking up the knife, then chopping the tomato.
(prepare chop board1 knife1 olive1 food-loc)
(put-down knife1 food-loc)
; They chop the olive. This involves chopping the olive, then putting down the knife.
(move food-loc chop-loc)
(pick-up glove1 chop-loc)
(move chop-loc food-loc)
(put-down glove1 food-loc)
; They find the gloves. This involves moving to the gloves, picking them up, moving to the food, then putting them down.
(pick-up feta-cheese1 food-loc)
(place-in feta-cheese1 board1 food-loc)
; They place the feta cheese on the chopping board. This involves picking up the feta cheese and placing it on the chopping board.
(pick-up glove1 food-loc)
; They put on the gloves. This involves no additional actions.
(prepare crumble board1 glove1 feta-cheese1 food-loc)
; They crumble feta cheese on the chopping board using the gloves. This involves no additional actions.
(put-down glove1 food-loc)
(pick-up board1 food-loc)
(move food-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer everything on the chopping board to the plate. This involves first putting down the gloves, picking up the chopping board, moving to the plate, then transferring everything on the chopping board to the plate.
