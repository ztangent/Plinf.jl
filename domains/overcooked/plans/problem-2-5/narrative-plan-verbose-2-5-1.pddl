(move start-loc food-loc)
(pick-up rice1 food-loc)
(move food-loc stove-loc)
(place-in rice1 pot1 stove-loc)
; They place the rice in the pot on the stove. This involves picking up the rice, moving to the stove, and placing the rice in the pot.
(cook boil pot1 stove1 stove-loc)
; They boil the pot on the stove. This involves no additional actions.
(pick-up pot1 stove-loc)
(move stove-loc plate-loc)
(transfer pot1 plate1 plate-loc)
(put-down pot1 plate-loc)
; They transfer the boiled rice onto a plate. This involves picking up the pot, moving the stove to the plate, transferring the rice to the plate, and putting down the pot.
(move plate-loc food-loc)
(pick-up crab1 food-loc)
(move food-loc chop-loc)
(place-in crab1 board1 chop-loc)
(pick-up s-knife1 chop-loc)
(prepare slice board1 s-knife1 crab1 chop-loc)
; Then they slice crab on a chopping board. This involves picking up the crab, moving to the chopping board, placing the crab on the board, picking up the knife, and slicing the crab.
(put-down s-knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
(put-down board1 plate-loc)
; They place the sliced crab on the plate with the rice. This involves putting down the held knife, picking up the chopping board, moving to the plate, transferring the crab to the plate, and putting down the chopping board.
(pick-up plate1 plate-loc)
(move plate-loc food-loc)
(put-down plate1 food-loc)
(pick-up cucumber1 food-loc)
(place-in cucumber1 plate1 food-loc)
; They place the cucumber in the plate of sliced crab. This involves picking up the plate first, moving to the cucumber, putting down the plate, then placing the cucumber in the plate.
(pick-up avocado1 food-loc)
(place-in avocado1 plate1 food-loc)
; They place the avocado in the plate of sliced crab. This involves picking up the avocado and placing the avocado in the plate.
(pick-up nori1 food-loc)
(place-in nori1 plate1 food-loc)
; They place the nori in the plate of sliced crab. This involves picking up the nori and placing the nori in the plate.
