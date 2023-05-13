(move start-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
(move mix-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
(combine mix mixing-bowl1 mixer1 mix-loc)
; They mix the flour and egg in the mixing bowl to become a dough. This involves picking up the flour and placing it in the mixing bowl, picking up the egg and placing it in the mixing bowl, and then using the mixer to combine the contents of the mixing bowl.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc tray-loc)
(transfer mixing-bowl1 tray1 tray-loc)
(put-down mixing-bowl1 tray-loc)
; They transfer the egg-and-flour dough to the tray. This involves picking up the mixing bowl, moving to the tray, transferring the contents of the mixing bowl to the tray, and putting down the mixing bowl.
(move tray-loc chop-loc)
(pick-up board1 chop-loc)
; They pick up the chopping board. This involves moving to the chopping board and picking it up.
(move chop-loc food-loc)
(put-down board1 food-loc)
; They place the chopping board next to the food. This involves moving to the food and putting down the chopping board.
(pick-up mushroom1 food-loc)
(place-in mushroom1 board1 food-loc)
; They place mushroom on the chopping board. This involves picking up the mushroom and placing it on the chopping board.
(pick-up onion1 food-loc)
(place-in onion1 board1 food-loc)
; They add onion to the chopping board. This involves picking up the onion and placing it on the chopping board.
(pick-up olive1 food-loc)
(place-in olive1 board1 food-loc)
; They add olive to the chopping board. This involves picking up the olive and placing it on the chopping board.
(move food-loc chop-loc)
(pick-up knife1 chop-loc)
(move chop-loc food-loc)
(prepare slice board1 knife1 onion1 food-loc)
; They slice the onion on the chopping board. This involves picking up the knife and slicing the onion.
(prepare slice board1 knife1 olive1 food-loc)
; They slice the olive on the chopping board. This involves no additional actions.
(prepare slice board1 knife1 mushroom1 food-loc)
; They slice the mushroom on the chopping board. This involves no additional actions.
(put-down knife1 food-loc)
(pick-up tomato1 food-loc)
(place-in tomato1 board1 food-loc)
; They place tomato on the chopping board. This involves first putting down the knife, then picking up the tomato and placing it on the chopping board.
(pick-up knife1 food-loc)
(prepare slice board1 knife1 tomato1 food-loc)
; They slice the tomato. This involves picking up the knife and slicing the tomato.
(put-down knife1 food-loc)
(pick-up board1 food-loc)
(move food-loc tray-loc)
(transfer board1 tray1 tray-loc)
(put-down board1 tray-loc)
; They transfer everything on the chopping board into the tray. This involves first putting down the knife, then picking up the chopping board, moving to the tray, transferring the contents of the chopping board to the tray, and putting down the chopping board.
(move tray-loc food-loc)
(pick-up cheese1 food-loc)
(move food-loc tray-loc)
(place-in cheese1 tray1 tray-loc)
; They add cheese to the tray. This involves picking up the cheese and placing it in the tray.
(pick-up tray1 tray-loc)
(move tray-loc oven-loc)
(put-down tray1 oven-loc)
(cook bake tray1 oven1 oven-loc)
; They bake the tray in the oven. This involves picking up the tray, moving to the oven, placing the tray in the oven, and baking the tray in the oven.
(pick-up tray1 oven-loc)
(move oven-loc plate-loc)
(transfer tray1 plate1 plate-loc)
; They transfer the baked food in the tray to the plate. This involves picking up the tray, moving to the plate, and transferring the contents of the tray to the plate.
