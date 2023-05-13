(move start-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
; They add an egg to the mixing bowl. This involves picking up the egg, moving to the mixing bowl, and placing the egg in the mixing bowl.
(move mix-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
; They add flour to the mixing bowl. This involves picking up the flour, moving to the mixing bowl, and placing the flour in the mixing bowl.
(combine mix mixing-bowl1 mixer1 mix-loc)
; They mix the flour and egg using a mixer. This involves no additional actions.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc oven-loc)
(transfer mixing-bowl1 tray1 oven-loc)
; They transfer the mixture to a tray. This involves picking up the mixing bowl, moving to the oven, and transferring the contents of the mixing bowl to the tray.
(move oven-loc food-loc)
(put-down mixing-bowl1 food-loc)
; They put down the mixing bowl. This involves moving to an appropriate location and putting down the mixing bowl.
(pick-up apple1 food-loc)
(move food-loc board-loc)
(place-in apple1 board1 board-loc)
; They place an apple on the chopping board. This involves picking up the apple, moving to the chopping board, and placing the apple on the chopping board.
(move board-loc chop-loc)
(pick-up knife1 chop-loc)
(move chop-loc board-loc)
(prepare slice board1 knife1 apple1 board-loc)
; They slice the apple. This involves picking up the knife, moving to the chopping board, and slicing the apple.
(put-down knife1 board-loc)
(take-out apple1 board1 board-loc)
; They take the apple from the chopping board. This involves first putting down the knife, then taking out the apple.
(move board-loc oven-loc)
(place-in apple1 tray1 oven-loc)
; They place the apple in the tray. This involves moving to the oven and placing the apple in the tray.
(cook bake tray1 oven1 oven-loc)
; They bake the tray in the oven. This involves no additional actions.
(pick-up tray1 oven-loc)
(move oven-loc plate-loc)
(transfer tray1 plate1 plate-loc)
; After baking, they transfer the baked food to the plate. This involves picking up the tray, moving to the plate, and transferring the contents of the tray to the plate.
