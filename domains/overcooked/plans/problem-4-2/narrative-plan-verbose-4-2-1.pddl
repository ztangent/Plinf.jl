(move start-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
(move mix-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
(combine mix mixing-bowl1 mixer1 mix-loc)
; They mix the flour and egg in the mixing bowl to become a dough. This involves picking up the flour and placing it in the mixing bowl, picking up the egg and placing it in the mixing bowl, and then using the mixer to combine the contents of the mixing bowl.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc tray-loc)
(transfer mixing-bowl1 tray1 tray-loc)
(put-down mixing-bowl1 tray-loc)
; They transfer the egg-and-flour dough to the tray. This involves picking up the mixing bowl, moving it to the tray, transferring the contents of the mixing bowl to the tray, and putting down the mixing bowl.
(move tray-loc food-loc)
(pick-up cheese1 food-loc)
; They pick up the cheese. This involves moving to cheese then picking it up.
(move food-loc tray-loc)
(place-in cheese1 tray1 tray-loc)
; They add the cheese to the tray. This involves moving to the tray then placing the cheese on the tray.
(move tray-loc food-loc)
(pick-up sausage1 food-loc)
(move food-loc chop-loc)
(place-in sausage1 board1 chop-loc)
(move chop-loc food-loc)
(pick-up tomato1 food-loc)
(move food-loc chop-loc)
(place-in tomato1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 tomato1 chop-loc)
; They slice tomato on the chopping board. This involves first picking up the tomato and placing it on the chopping board if it is not already there, then slicing the tomato with a knife.
(prepare slice board1 knife1 sausage1 chop-loc)
(put-down knife1 chop-loc)
; They slice the sausage on the chopping board. This involves first picking up the sausage and placing it on the chopping board if it is not already there, then slicing the sausage with a knife.
(pick-up board1 chop-loc)
(move chop-loc tray-loc)
(transfer board1 tray1 tray-loc)
(put-down board1 tray-loc)
; They transfer the sliced tomato and sausage from the chopping board to the tray. This involves picking up the chopping board, moving it to the tray, transferring the contents of the chopping board to the tray, and putting down the chopping board.
(pick-up tray1 tray-loc)
(move tray-loc oven-loc)
(put-down tray1 oven-loc)
(cook bake tray1 oven1 oven-loc)
; They bake everything on the tray in an oven. This involves picking up the tray, moving it to the oven, putting it in the oven, and then baking the contents of the tray.
(pick-up tray1 oven-loc)
(move oven-loc plate-loc)
(transfer tray1 plate1 plate-loc)
; They transfer the baked contents of the tray to a plate. This involves picking up the tray, moving it to the plate, and transferring the contents of the tray to the plate.
