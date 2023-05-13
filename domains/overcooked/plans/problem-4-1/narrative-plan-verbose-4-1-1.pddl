(move start-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
; They take the flour and put it in a mixing bowl. This involves picking up the flour, moving to the mixing bowl, and placing the flour in the mixing bowl.
(move mix-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
; They take the egg and put it in a mixing bowl. This involves picking up the egg, moving to the mixing bowl, and placing the egg in the mixing bowl.
(combine mix mixing-bowl1 mixer1 mix-loc)
; They mix the egg and flour into a dough in a mixing bowl. This involves no additional actions.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc tray-loc)
(transfer mixing-bowl1 tray1 tray-loc)
(put-down mixing-bowl1 tray-loc)
; They transfer the egg-and-flour dough to the tray. This involves picking up the mixing bowl, moving to the tray, transferring the dough to the tray, and putting down the mixing bowl.
(move tray-loc food-loc)
(pick-up tomato1 food-loc)
; They pick up the tomato. This involves moving to the tomato and picking it up.
(move food-loc chop-loc)
(place-in tomato1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 tomato1 chop-loc)
; They slice the tomato in the chopping board. This involves placing the tomato on the chopping board, picking up the knife, and slicing the tomato.
(put-down knife1 chop-loc)
(take-out tomato1 board1 chop-loc)
(move chop-loc tray-loc)
(place-in tomato1 tray1 tray-loc)
; They place the sliced tomato on the tray with the dough. This involves first putting down the knife, then taking out the sliced tomato from the chopping board, moving to the tray, and placing the tomato on the tray.
(pick-up tray1 tray-loc)
(move tray-loc food-loc)
(put-down tray1 food-loc)
(pick-up cheese1 food-loc)
; They get the cheese. This involves moving to the cheese and picking it up.
(place-in cheese1 tray1 food-loc)
; They add the cheese to the tray. This involves no additional actions.
(pick-up basil1 food-loc)
; They get the basil. This involves moving to the basil and picking it up.
(place-in basil1 tray1 food-loc)
; They add the basil to the tray. This involves no additional actions.
(pick-up tray1 food-loc)
(move food-loc oven-loc)
(put-down tray1 oven-loc)
(cook bake tray1 oven1 oven-loc)
; They bake the tray in the oven. This involves picking up the tray, moving to the oven, putting the tray in the oven, and baking the tray.
(pick-up tray1 oven-loc)
(move oven-loc plate-loc)
(transfer tray1 plate1 plate-loc)
; They transfer everything on the baking tray to the plate. This involves picking up the tray, moving to the plate, and transferring the contents of the tray to the plate.
