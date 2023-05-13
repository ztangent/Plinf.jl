(move start-loc food-loc)
(pick-up tuna1 food-loc)
; They pick up the tuna.
(move food-loc chop-loc)
(place-in tuna1 board1 chop-loc)
(pick-up s-knife1 chop-loc)
(prepare slice board1 s-knife1 tuna1 chop-loc)
; They slice the tuna on the chopping board.
(put-down s-knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer the sliced tuna to the plate.
(move plate-loc food-loc)
(put-down board1 food-loc)
(pick-up rice1 food-loc)
; They pick up the rice.
(move food-loc stove-loc)
(place-in rice1 pot1 stove-loc)
; They put the rice in a pot of water.
(cook boil pot1 stove1 stove-loc)
; They boil the pot on the stove.
(pick-up pot1 stove-loc)
(move stove-loc plate-loc)
(transfer pot1 plate1 plate-loc)
; When the rice is cooked, they transfer the rice from the pot to the plate of sliced tuna.
(move plate-loc food-loc)
(put-down pot1 food-loc)
(pick-up nori1 food-loc)
; They pick up the nori.
(move food-loc plate-loc)
(place-in nori1 plate1 plate-loc)
; They assemble the nori with the rice and tuna in the plate.
