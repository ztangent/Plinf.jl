(move start-loc food-loc)
(pick-up feta-cheese1 food-loc)
(move food-loc chop-loc)
(place-in feta-cheese1 board1 chop-loc)
; They bring feta cheese to the chopping board.
(move chop-loc food-loc)
(pick-up olive1 food-loc)
(move food-loc chop-loc)
(place-in olive1 board1 chop-loc)
; They bring olives to the chopping board.
(pick-up knife1 chop-loc)
(prepare chop board1 knife1 olive1 chop-loc)
(put-down knife1 chop-loc)
(pick-up glove1 chop-loc)
(prepare crumble board1 glove1 feta-cheese1 chop-loc)
; They chop the olives then crumble the feta cheese.
(put-down glove1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer the chopped olives and crumbled feta cheese to the plate.
