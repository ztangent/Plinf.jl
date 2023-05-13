(move start-loc food-loc)
(pick-up bread1 food-loc)
; They pick up the bread.
(move food-loc plate-loc)
(place-in bread1 plate1 plate-loc)
; They place the bread on the plate.
(move plate-loc food-loc)
(pick-up ham1 food-loc)
; They pick up ham.
(move food-loc chop-loc)
(place-in ham1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 ham1 chop-loc)
; They slice the ham on the chopping board.
(put-down knife1 chop-loc)
(move chop-loc food-loc)
(pick-up cheese1 food-loc)
; They pick up cheese.
(move food-loc chop-loc)
(place-in cheese1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 cheese1 chop-loc)
; They slice the cheese on the chopping board.
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer the sliced ham and cheese to the plate.
(move plate-loc chop-loc)
(put-down board1 chop-loc)
(move chop-loc food-loc)
(pick-up mayo1 food-loc)
(move food-loc plate-loc)
(place-in mayo1 plate1 plate-loc)
; They add mayonnaise to the plate with the bread and sliced ham and cheese.
