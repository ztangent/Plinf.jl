(move start-loc food-loc)
(pick-up tuna1 food-loc)
; They pick up the tuna. This involves moving to the tuna and picking it up.
(move food-loc chop-loc)
(place-in tuna1 board1 chop-loc)
(pick-up s-knife1 chop-loc)
(prepare slice board1 s-knife1 tuna1 chop-loc)
; They slice the tuna on the chopping board. This involves placing the tuna on the board, picking up the knife, and slicing the tuna.
(put-down s-knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They transfer the sliced tuna to the plate. This involves putting down the knife first, picking up the board, moving to the plate, and transferring the tuna.
(move plate-loc food-loc)
(put-down board1 food-loc)
(pick-up rice1 food-loc)
; They pick up the rice. This involves putting down the board first, then picking up the rice.
(move food-loc stove-loc)
(place-in rice1 pot1 stove-loc)
; They put the rice in a pot of water. This involves moving to the stove and placing the rice in the pot.
(cook boil pot1 stove1 stove-loc)
; They boil the pot on the stove. This involves no additional actions.
(pick-up pot1 stove-loc)
(move stove-loc plate-loc)
(transfer pot1 plate1 plate-loc)
; When the rice is cooked, they transfer the rice from the pot to the plate of sliced tuna. This involves picking up the pot, moving to the plate, and transferring the rice.
(move plate-loc food-loc)
(put-down pot1 food-loc)
(pick-up nori1 food-loc)
; They pick up the nori. This involves putting down the pot first, then picking up the nori.
(move food-loc plate-loc)
(place-in nori1 plate1 plate-loc)
; They assemble the nori with the rice and tuna in the plate. This involves moving to the plate and placing the nori in the plate.
