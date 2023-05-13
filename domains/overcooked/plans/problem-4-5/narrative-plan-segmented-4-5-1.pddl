(move start-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
(move mix-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
(combine mix mixing-bowl1 mixer1 mix-loc)
; They mix the flour and egg in the mixing bowl.
(move mix-loc food-loc)
(pick-up ham1 food-loc)
(move food-loc chop-loc)
(place-in ham1 board1 chop-loc)
; The find the ham and place it on the chopping board.
(move chop-loc food-loc)
(pick-up tomato1 food-loc)
(move food-loc chop-loc)
(place-in tomato1 board1 chop-loc)
; They find the tomato and place it on the chopping board.
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 tomato1 chop-loc)
; They slice the tomato on the chopping board.
(prepare slice board1 knife1 ham1 chop-loc)
(put-down knife1 chop-loc)
; They slice the ham on the chopping board.
(move chop-loc food-loc)
(pick-up cheese1 food-loc)
; They pick up the cheese.
(move food-loc chop-loc)
(place-in cheese1 board1 chop-loc)
; They place the cheese on the chopping board.
(move chop-loc mix-loc)
(pick-up mixing-bowl1 mix-loc)
; They go to the mixing bowl and pick it up.
(move mix-loc tray-loc)
(transfer mixing-bowl1 tray1 tray-loc)
(put-down mixing-bowl1 tray-loc)
; They transfer the egg and flour mixture to the tray.
(move tray-loc chop-loc)
(pick-up board1 chop-loc)
(move chop-loc tray-loc)
(transfer board1 tray1 tray-loc)
; They transfer everything from the chopping board onto the tray.
(move tray-loc food-loc)
(put-down board1 food-loc)
; They put down the chopping board.
(pick-up pineapple1 food-loc)
(place-in pineapple1 board1 food-loc)
; They place the pineapple on the chopping board.
(move food-loc chop-loc)
(pick-up knife1 chop-loc)
(move chop-loc food-loc)
(prepare chop board1 knife1 pineapple1 food-loc)
(put-down knife1 food-loc)
; They chop the pineapple on the chopping board.
(take-out pineapple1 board1 food-loc)
(move food-loc tray-loc)
(place-in pineapple1 tray1 tray-loc)
; They place the chopped pineapple into the tray.
(pick-up tray1 tray-loc)
(move tray-loc oven-loc)
(put-down tray1 oven-loc)
(cook bake tray1 oven1 oven-loc)
; They bake the tray in the oven.
(pick-up tray1 oven-loc)
(move oven-loc plate-loc)
(transfer tray1 plate1 plate-loc)
; They transfer the baked food in the tray to the plate.
