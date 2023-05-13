(move start-loc food-loc)
(pick-up tuna1 food-loc)
(move food-loc chop-loc)
(place-in tuna1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 tuna1 chop-loc)
; They slice the tuna on the chopping board. This involves picking up the tuna, placing it on the board, picking up the knife, and slicing the tuna.
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; They place the sliced tuna on the plate. This involves first putting down the knife, then picking up the board, moving the board to the plate, and transferring the tuna from the board to the plate. 
(move plate-loc food-loc)
(put-down board1 food-loc)
(pick-up rice1 food-loc)
(move food-loc stove-loc)
(place-in rice1 pot1 stove-loc)
; They place the rice in a pot on the stove. This involves first putting down the chopping borad, then picking up the rice, moving the rice to the stove, and placing the rice in the pot.
(cook boil pot1 stove2 stove-loc)
; They boil the pot on the stove. This involves no additional actions.
(pick-up pot1 stove-loc)
(move stove-loc plate-loc)
(transfer pot1 plate1 plate-loc)
; They transfer the cooked rice to the plate of sliced tuna. This involves picking up the pot, moving the pot to the plate, and transferring the rice from the pot to the plate.
