(move start-loc food-loc)
(pick-up tuna1 food-loc)
(move food-loc chop-loc)
(place-in tuna1 board1 chop-loc)
(pick-up s-knife1 chop-loc)
(prepare slice board1 s-knife1 tuna1 chop-loc)
; Pick up tuna and slice it on the chopping board.
(put-down s-knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; Transfer the sliced tuna to the plate.
(move plate-loc food-loc)
(put-down board1 food-loc)
(pick-up rice1 food-loc)
(move food-loc stove-loc)
(place-in rice1 pot1 stove-loc)
(cook boil pot1 stove1 stove-loc)
; Pick up the rice and put it in a pot of water on the stove to boil.
(pick-up pot1 stove-loc)
(move stove-loc plate-loc)
(transfer pot1 plate1 plate-loc)
; Transfer the cooked rice from the pot to the plate of sliced tuna.
(move plate-loc food-loc)
(put-down pot1 food-loc)
(pick-up nori1 food-loc)
(move food-loc plate-loc)
(place-in nori1 plate1 plate-loc)
; Pick up the nori and assemble it with the rice and tuna in the plate.
