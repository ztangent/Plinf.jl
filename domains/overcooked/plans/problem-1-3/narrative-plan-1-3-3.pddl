(move start-loc food-loc)
(pick-up feta-cheese1 food-loc)
(move food-loc chop-loc)
(place-in feta-cheese1 board1 chop-loc)
(move chop-loc food-loc)
(pick-up cucumber1 food-loc)
(move food-loc chop-loc)
(place-in cucumber1 board1 chop-loc)
; They place feta cheese and cucumber on the chopping board.
(move chop-loc food-loc)
(pick-up onion1 food-loc)
(move food-loc chop-loc)
(place-in onion1 board1 chop-loc)
; They place onion on the chopping board.
(pick-up knife1 chop-loc)
(prepare chop board1 knife1 onion1 chop-loc)
(prepare slice board1 knife1 cucumber1 chop-loc)
; They chop the onion and slice the cucumber
(put-down knife1 chop-loc)
(pick-up glove1 chop-loc)
(prepare crumble board1 glove1 feta-cheese1 chop-loc)
; They crumble the feta cheese using gloves.
(put-down glove1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer the ingredients on the chopping board to the plate.
