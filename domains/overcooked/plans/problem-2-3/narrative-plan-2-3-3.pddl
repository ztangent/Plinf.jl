(move start-loc food-loc)
(pick-up rice1 food-loc)
(move food-loc stove-loc)
(place-in rice1 pot1 stove-loc)
(cook boil pot1 stove1 stove-loc)
; They boil some rice in a pot on the stove.
(pick-up pot1 stove-loc)
(move stove-loc plate-loc)
(transfer pot1 plate1 plate-loc)
; Once the rice is done, they transfer it to the plate.
(put-down pot1 plate-loc)
(move plate-loc food-loc)
(pick-up tuna1 food-loc)
(move food-loc chop-loc)
(place-in tuna1 board1 chop-loc)
; They place tuna in the chopping board.
(move chop-loc food-loc)
(pick-up salmon1 food-loc)
(move food-loc chop-loc)
(place-in salmon1 board1 chop-loc)
; They place salmon in the chopping board.
(pick-up s-knife1 chop-loc)
(prepare slice board1 s-knife1 salmon1 chop-loc)
(prepare slice board1 s-knife1 tuna1 chop-loc)
; They slice the salmon and tuna.
(put-down s-knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer the sliced salmon and tuna to the plate.
(put-down board1 plate-loc)
(move plate-loc food-loc)
(pick-up nori1 food-loc)
(move food-loc plate-loc)
(place-in nori1 plate1 plate-loc)
; They find nori and assemble it with the other ingredients on the plate.