(move start-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
(move mix-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
(combine mix mixing-bowl1 mixer1 mix-loc)
; (combined-with mix egg1 flour1)
(move mix-loc food-loc)
(pick-up tomato1 food-loc)
(move food-loc chop-loc)
(place-in tomato1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 tomato1 chop-loc)
; (prepared slice tomato1)
(put-down knife1 chop-loc)
(take-out tomato1 board1 chop-loc)
(move chop-loc mix-loc)
(place-in tomato1 mixing-bowl1 mix-loc)
(pick-up mixing-bowl1 mix-loc)
(move mix-loc tray-loc)
(transfer mixing-bowl1 tray1 tray-loc)
(put-down mixing-bowl1 tray-loc)
(pick-up tray1 tray-loc)
(move tray-loc food-loc)
(put-down tray1 food-loc)
(pick-up cheese1 food-loc)
(place-in cheese1 tray1 food-loc)
(pick-up sausage1 food-loc)
(place-in sausage1 tray1 food-loc)
(pick-up olive1 food-loc)
(place-in olive1 tray1 food-loc)
(pick-up tray1 food-loc)
(move food-loc oven-loc)
(put-down tray1 oven-loc)
(cook bake tray1 oven1 oven-loc)
; (cooked-with bake egg1 flour1) (cooked-with bake flour1 tomato1) (cooked-with bake tomato1 cheese1) (cooked-with bake cheese1 sausage1) (cooked-with bake sausage1 olive1)
(pick-up tray1 oven-loc)
(move oven-loc plate-loc)
(transfer tray1 plate1 plate-loc)
; (in-receptacle tomato1 plate1) (in-receptacle cheese1 plate1) (in-receptacle sausage1 plate1) (in-receptacle olive1 plate1) (in-receptacle egg1 plate1) (in-receptacle flour1 plate1)
