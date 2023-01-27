(move start-loc food-loc)
(put-down board1 food-loc)
(pick-up rice1 food-loc)
(move food-loc stove-loc)
(place-in rice1 pot1 stove-loc)
(cook boil pot1 stove1 stove-loc)
; They place the rice in a pot of water on the stove to boil.
(pick-up pot1 stove-loc)
(move stove-loc plate-loc)
(transfer pot1 plate1 plate-loc)
; They when the rice is cooked, they transfer the rice to the plate.
(move plate-loc food-loc)
(put-down pot1 food-loc)
(pick-up salmon1 food-loc)
(move food-loc chop-loc)
(place-in salmon1 board1 chop-loc)
(pick-up s-knife1 chop-loc)
(prepare slice board1 s-knife1 salmon1 chop-loc)
; They slice the salmon on the chopping board.
(put-down s-knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer the sliced salmon to the plate of rice.
(pick-up nori1 food-loc)
(move food-loc plate-loc)
(place-in nori1 plate1 plate-loc)
; They pick up nori and place it in the plate of rice and salmon.
