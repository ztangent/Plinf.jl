(move start-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
(move mix-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
(combine mix mixing-bowl1 mixer1 mix-loc)
; They mix the flour and egg in the mixing bowl.
(move mix-loc chop-loc)
(pick-up board1 chop-loc)
(move chop-loc food-loc)
(put-down board1 food-loc)
(pick-up onion1 food-loc)
(place-in onion1 board1 food-loc)
(pick-up mushroom1 food-loc)
(place-in mushroom1 board1 food-loc)
(pick-up olive1 food-loc)
(place-in olive1 board1 food-loc)
(pick-up tomato1 food-loc)
(place-in tomato1 board1 food-loc)
(move food-loc chop-loc)
(pick-up knife1 chop-loc)
(move chop-loc food-loc)
(prepare slice board1 knife1 onion1 food-loc)
(prepare slice board1 knife1 olive1 food-loc)
(prepare slice board1 knife1 mushroom1 food-loc)
(prepare slice board1 knife1 tomato1 food-loc)
; They slice the onion, olive, mushroom and tomato.
(put-down knife1 food-loc)
(pick-up board1 food-loc)
(move food-loc tray-loc)
(transfer board1 tray1 tray-loc)
(put-down board1 tray-loc)
(move tray-loc mix-loc)
(pick-up mixing-bowl1 mix-loc)
(move mix-loc tray-loc)
(transfer mixing-bowl1 tray1 tray-loc)
(put-down mixing-bowl1 tray-loc)
; They transfer the egg and flour mixture to the tray, and the sliced onion, olive, mushroom and tomato as well.
(pick-up tray1 tray-loc)
(move tray-loc food-loc)
(put-down tray1 food-loc)
(pick-up cheese1 food-loc)
(place-in cheese1 tray1 food-loc)
; They add cheese to the tray.
(pick-up tray1 food-loc)
(move food-loc oven-loc)
(put-down tray1 oven-loc)
(cook bake tray1 oven1 oven-loc)
; They bake the tray in the oven.
(pick-up tray1 oven-loc)
(move oven-loc plate-loc)
(transfer tray1 plate1 plate-loc)
; They transfer the baked food in the tray to the plate.
