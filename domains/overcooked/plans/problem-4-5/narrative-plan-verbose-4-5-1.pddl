(move start-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
(move mix-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
(combine mix mixing-bowl1 mixer1 mix-loc)
; They mix the flour and egg in the mixing bowl. This involves first picking up egg and placing it in the mixing bowl, then picking up flour and placing it in the mixing bowl, then combining the contents of the mixing bowl with the mixer.
(move mix-loc food-loc)
(pick-up ham1 food-loc)
(move food-loc chop-loc)
(place-in ham1 board1 chop-loc)
; The find the ham and place it on the chopping board. This involves picking up the ham, moving to the chopping board, and placing the ham on the chopping board.
(move chop-loc food-loc)
(pick-up tomato1 food-loc)
(move food-loc chop-loc)
(place-in tomato1 board1 chop-loc)
; They find the tomato and place it on the chopping board. This involves picking up the tomato, moving to the chopping board, and placing the tomato on the chopping board.
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 tomato1 chop-loc)
; They slice the tomato on the chopping board. This involves picking up the knife, then slicing the tomato on the chopping board.
(prepare slice board1 knife1 ham1 chop-loc)
(put-down knife1 chop-loc)
; They slice the ham on the chopping board. This involves slicing the ham on the chopping board, then putting down the knife.
(move chop-loc food-loc)
(pick-up cheese1 food-loc)
; They pick up the cheese. This involves moving to the cheese and picking it up.
(move food-loc chop-loc)
(place-in cheese1 board1 chop-loc)
; They place the cheese on the chopping board. This involves moving to the chopping board and placing the cheese on the chopping board.
(move chop-loc mix-loc)
(pick-up mixing-bowl1 mix-loc)
; They go to the mixing bowl and pick it up. This involves moving to the mixing bowl and picking it up.
(move mix-loc tray-loc)
(transfer mixing-bowl1 tray1 tray-loc)
(put-down mixing-bowl1 tray-loc)
; They transfer the egg and flour mixture to the tray. This involves moving to the tray, transferring the contents of the mixing bowl to the tray, then putting down the mixing bowl.
(move tray-loc chop-loc)
(pick-up board1 chop-loc)
(move chop-loc tray-loc)
(transfer board1 tray1 tray-loc)
; They transfer everything from the chopping board onto the tray. This involves picking up the chopping board, moving to the tray, then transferring the contents of the chopping board to the tray.
(move tray-loc food-loc)
(put-down board1 food-loc)
; They put down the chopping board. This involves no additional actions.
(pick-up pineapple1 food-loc)
(place-in pineapple1 board1 food-loc)
; They place the pineapple on the chopping board. This involves first picking up the pineapple, then placing it on the chopping board.
(move food-loc chop-loc)
(pick-up knife1 chop-loc)
(move chop-loc food-loc)
(prepare chop board1 knife1 pineapple1 food-loc)
(put-down knife1 food-loc)
; They chop the pineapple on the chopping board. This involves picking up the knife, chopping the pineapple, then putting down the knife.
(take-out pineapple1 board1 food-loc)
(move food-loc tray-loc)
(place-in pineapple1 tray1 tray-loc)
; They place the chopped pineapple into the tray. This involves taking out the pineapple from the chopping board, moving to the tray, then placing the pineapple in the tray.
(pick-up tray1 tray-loc)
(move tray-loc oven-loc)
(put-down tray1 oven-loc)
(cook bake tray1 oven1 oven-loc)
; They bake the tray in the oven. This involves picking up the tray, moving to the oven, placing the tray in the oven, then baking the tray.
(pick-up tray1 oven-loc)
(move oven-loc plate-loc)
(transfer tray1 plate1 plate-loc)
; They transfer the baked food in the tray to the plate. This involves picking up the tray, moving to the plate, then transferring the contents of the tray to the plate.
