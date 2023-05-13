(move start-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
(move mix-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
(combine mix mixing-bowl1 mixer1 mix-loc)
; They mix the flour and egg in the mixing bowl to become a dough.
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
; They slice the tomato on the chopping board.
(prepare chop board1 knife1 beef1 food-loc)
; They chop the beef on the chopping board.
(put-down knife1 food-loc)
; They put down the knife.
(move food-loc mix-loc)
(pick-up mixing-bowl1 mix-loc)
; They pick up the mixing bowl.
(move mix-loc tray-loc)
(transfer mixing-bowl1 tray1 tray-loc)
(put-down mixing-bowl1 tray-loc)
; They transfer the egg-and-flour dough to the tray.
(move tray-loc food-loc)
; They go back to the chopping board.
(pick-up sausage1 food-loc)
(place-in sausage1 board1 food-loc)
(pick-up chicken1 food-loc)
(place-in chicken1 board1 food-loc)
(pick-up knife1 food-loc)
(prepare chop board1 knife1 chicken1 food-loc)
; They chop chicken on the chopping board.
(prepare slice board1 knife1 sausage1 food-loc)
; They slice sausage on the chopping board.
(put-down knife1 food-loc)
(pick-up board1 food-loc)
(move food-loc tray-loc)
(transfer board1 tray1 tray-loc)
(put-down board1 tray-loc)
; They transfer everything on the chopping board to the tray.
(move tray-loc food-loc)
(pick-up cheese1 food-loc)
(move food-loc tray-loc)
(place-in cheese1 tray1 tray-loc)
; They add cheese to the tray.
(pick-up tray1 tray-loc)
(move tray-loc oven-loc)
(put-down tray1 oven-loc)
(cook bake tray1 oven1 oven-loc)
; They bake everything on the tray in the oven.
(pick-up tray1 oven-loc)
(move oven-loc plate-loc)
(transfer tray1 plate1 plate-loc)
; They transfer the baked food in the tray to the plate.
