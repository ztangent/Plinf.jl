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
(move mix-loc chop-loc)
(pick-up board1 chop-loc)
(move chop-loc food-loc)
(put-down board1 food-loc)
(pick-up tomato1 food-loc)
(place-in tomato1 board1 food-loc)
(pick-up beef1 food-loc)
(place-in beef1 board1 food-loc)
(move food-loc chop-loc)
(pick-up knife1 chop-loc)
(move chop-loc food-loc)
(prepare slice board1 knife1 tomato1 food-loc)
; They slice the tomato on the chopping board. This involves first picking up the tomato and placing it on the chopping board if it is not already there, then slicing the tomato with a knife.
(prepare chop board1 knife1 beef1 food-loc)
; They chop the beef on the chopping board. This involves first picking up the beef and placing it on the chopping board if it is not already there, then chopping the beef with a knife.
(put-down knife1 food-loc)
; They put down the knife. This involves no additional actions.
(move food-loc mix-loc)
(pick-up mixing-bowl1 mix-loc)
; They pick up the mixing bowl. This involves moving to the mixing bowl and picking it up.
(move mix-loc tray-loc)
(transfer mixing-bowl1 tray1 tray-loc)
(put-down mixing-bowl1 tray-loc)
; They transfer the egg-and-flour dough to the tray. This involves moving to the tray, transferring the contents of the mixing bowl to the tray, then putting down the mixing bowl.
(move tray-loc food-loc)
; They go back to the chopping board. This involves no additional actions.
(pick-up sausage1 food-loc)
(place-in sausage1 board1 food-loc)
(pick-up chicken1 food-loc)
(place-in chicken1 board1 food-loc)
(pick-up knife1 food-loc)
(prepare chop board1 knife1 chicken1 food-loc)
; They chop chicken on the chopping board. This involves first picking up the chicken and placing it on the chopping board if it is not already there, then chopping the chicken with a knife.
(prepare slice board1 knife1 sausage1 food-loc)
; They slice sausage on the chopping board. This involves first picking up the sausage and placing it on the chopping board if it is not already there, then slicing the sausage with a knife.
(put-down knife1 food-loc)
(pick-up board1 food-loc)
(move food-loc tray-loc)
(transfer board1 tray1 tray-loc)
(put-down board1 tray-loc)
; They transfer everything on the chopping board to the tray. This involves first putting down the knife, then picking up the chopping board, moving to the tray, transferring the contents of the chopping board to the tray, then putting down the chopping board.
(move tray-loc food-loc)
(pick-up cheese1 food-loc)
(move food-loc tray-loc)
(place-in cheese1 tray1 tray-loc)
; They add cheese to the tray. This involves picking up the cheese and placing it on the tray.
(pick-up tray1 tray-loc)
(move tray-loc oven-loc)
(put-down tray1 oven-loc)
(cook bake tray1 oven1 oven-loc)
; They bake everything on the tray in the oven. This involves picking up the tray, placing it in the oven, then baking the tray in the oven.
(pick-up tray1 oven-loc)
(move oven-loc plate-loc)
(transfer tray1 plate1 plate-loc)
; They transfer the baked food in the tray to the plate. This involves picking up the tray, moving to the plate, then transferring the contents of the tray to the plate.
