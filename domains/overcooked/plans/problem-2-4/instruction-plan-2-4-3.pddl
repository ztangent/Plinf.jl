(move start-loc food-loc)
(pick-up salmon1 food-loc)
(move food-loc chop-loc)
(place-in salmon1 board1 chop-loc)
; Bring salmon to chopping board.
(move chop-loc food-loc)
(pick-up cucumber1 food-loc)
(move food-loc chop-loc)
(place-in cucumber1 board1 chop-loc)
; Bring cucumber to the chopping board.
(pick-up s-knife1 chop-loc)
(prepare slice board1 s-knife1 salmon1 chop-loc)
(prepare slice board1 s-knife1 cucumber1 chop-loc)
; Slice the salmon and cucumber.
(put-down s-knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; Transfer the contents of the chopping board to the plate.
(move plate-loc food-loc)
(put-down board1 food-loc)
(pick-up rice1 food-loc)
(move food-loc stove-loc)
(place-in rice1 pot1 stove-loc)
(cook boil pot1 stove1 stove-loc)
; Place rice in the pot and cook it on the stove.
(pick-up pot1 stove-loc)
(move stove-loc plate-loc)
(transfer pot1 plate1 plate-loc)
; Transfer the cooked rice from the pot to the plate.
(move plate-loc food-loc)
(put-down pot1 food-loc)
(pick-up nori1 food-loc)
(move food-loc plate-loc)
(place-in nori1 plate1 plate-loc)
; Assemble the nori with the rice and salmon and cucumber on the plate.
