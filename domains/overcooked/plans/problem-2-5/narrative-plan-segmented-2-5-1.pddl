(move start-loc food-loc)
(pick-up rice1 food-loc)
(move food-loc stove-loc)
(place-in rice1 pot1 stove-loc)
; They place the rice in the pot on the stove.
(cook boil pot1 stove1 stove-loc)
; They boil the pot on the stove.
(pick-up pot1 stove-loc)
(move stove-loc plate-loc)
(transfer pot1 plate1 plate-loc)
(put-down pot1 plate-loc)
; They transfer the boiled rice onto a plate.
(move plate-loc food-loc)
(pick-up crab1 food-loc)
(move food-loc chop-loc)
(place-in crab1 board1 chop-loc)
(pick-up s-knife1 chop-loc)
(prepare slice board1 s-knife1 crab1 chop-loc)
; Then they slice crab on a chopping board.
(put-down s-knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
(put-down board1 plate-loc)
; They place the sliced crab on the plate with the rice.
(pick-up plate1 plate-loc)
(move plate-loc food-loc)
(put-down plate1 food-loc)
(pick-up cucumber1 food-loc)
(place-in cucumber1 plate1 food-loc)
; They add cucumber to the plate of sliced crab.
(pick-up avocado1 food-loc)
(place-in avocado1 plate1 food-loc)
; They add avocado to the plate of sliced crab.
(pick-up nori1 food-loc)
(place-in nori1 plate1 food-loc)
; They add nori to the plate of sliced crab.
