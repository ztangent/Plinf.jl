(move start-loc food-loc)
(pick-up rice1 food-loc)
(move food-loc stove-loc)
(place-in rice1 pot1 stove-loc)
(cook boil pot1 stove2 stove-loc)
; Place rice in a pot, then boil the pot on the stove.
(pick-up pot1 stove-loc)
(move stove-loc plate-loc)
(transfer pot1 plate1 plate-loc)
; Transfer the rice from the pot to a plate.
(put-down pot1 plate-loc)
(move plate-loc food-loc)
(pick-up tuna1 food-loc)
(move food-loc chop-loc)
(place-in tuna1 board1 chop-loc)
; Place tuna on a chopping board.
(move chop-loc food-loc)
(pick-up salmon1 food-loc)
(move food-loc chop-loc)
(place-in salmon1 board1 chop-loc)
; Place salmon on a chopping board.
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 salmon1 chop-loc)
(prepare slice board1 knife1 tuna1 chop-loc)
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; Slice the tuna and salmon, then transfer them to the plate.
