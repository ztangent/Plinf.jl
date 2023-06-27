(move start-loc food-loc)
(pick-up chicken1 food-loc)
(move food-loc chop-loc)
(place-in chicken1 board1 chop-loc)
(move chop-loc food-loc)
(pick-up tomato1 food-loc)
(move food-loc chop-loc)
(place-in tomato1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 chicken1 chop-loc)
(prepare slice board1 knife1 tomato1 chop-loc)
; They pick up chicken and tomato then slice them on the chopping board.
(put-down knife1 chop-loc)
(move chop-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
; They place some flour in the mixing bowl.
(move mix-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
; They add egg to the mixing bowl.
(combine mix mixing-bowl1 mixer1 mix-loc)
; They mix the contents of the bowl.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc tray-loc)
(transfer mixing-bowl1 tray1 tray-loc)
(put-down mixing-bowl1 tray-loc)
; They transfer the dough from the mixing bowl to the tray.
(move tray-loc food-loc)
(pick-up cheese1 food-loc)
(move food-loc tray-loc)
(place-in cheese1 tray1 tray-loc)
; They add cheese to the tray.
(move tray-loc chop-loc)
(pick-up board1 chop-loc)
(move chop-loc tray-loc)
(transfer board1 tray1 tray-loc)
; They transfer the sliced tomato and chicken from the chopping board to the tray.
(put-down board1 tray-loc)
(pick-up tray1 tray-loc)
(move tray-loc oven-loc)
(put-down tray1 oven-loc)
(cook bake tray1 oven1 oven-loc)
; They place the tray in the oven and bake it.
(pick-up tray1 oven-loc)
(move oven-loc plate-loc)
(transfer tray1 plate1 plate-loc)
; Once baked, they transfer the contents of the tray to a plate.