(move start-loc food-loc)
(pick-up cucumber1 food-loc)
(move food-loc chop-loc)
(place-in cucumber1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 cucumber1 chop-loc)
; They pick up cucumber and slice it on the chopping board.
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer the sliced cucumber to the plate.
(move plate-loc food-loc)
(put-down board1 food-loc)
(pick-up lettuce1 food-loc)
(move food-loc plate-loc)
(place-in lettuce1 plate1 plate-loc)
; They add lettuce to the plate.
