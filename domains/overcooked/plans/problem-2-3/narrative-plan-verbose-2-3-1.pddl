(move start-loc food-loc)
(pick-up rice1 food-loc)
(move food-loc stove-loc)
(place-in rice1 pot1 stove-loc)
; They place the rice in a pot on the stove. This involves picking up the rice, moving to the stove, and placing the rice in the pot.
(cook boil pot1 stove1 stove-loc)
; They boil the pot on the stove. This involves no additional actions.
(pick-up pot1 stove-loc)
(move stove-loc plate-loc)
(transfer pot1 plate1 plate-loc)
; After the rice is cooked, they transfer the rice to the plate. This involves picking up the pot, moving to the plate, and transferring the rice to the plate.
(move plate-loc food-loc)
(put-down pot1 food-loc)
(pick-up salmon1 food-loc)
(move food-loc chop-loc)
(place-in salmon1 board1 chop-loc)
(pick-up s-knife1 chop-loc)
(prepare slice board1 s-knife1 salmon1 chop-loc)
; They slice the salmon on the chopping board. This involves first putting down the pot, then picking up the salmon, placing the salmon on the chopping board, picking up the knife, and slicing the salmon
(put-down s-knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
(put-down board1 plate-loc)
; They transfer the sliced salmon to the plate of rice. This involves first putting down the knife, then picking up the chopping board, moving to the plate, transferring the salmon to the plate, then putting down the chopping board.
(move plate-loc food-loc)
(pick-up nori1 food-loc)
; They pick up the nori. This involves moving to the nori, and picking it up.
(move food-loc plate-loc)
(place-in nori1 plate1 plate-loc)
; They assemble the nori with the rice and salmon in the plate. This involves moving to the plate, and placing the nori in the plate.
