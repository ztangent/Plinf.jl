(move start-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
(move mix-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
; Place flour and egg in the mixing bowl.
(combine mix mixing-bowl1 mixer1 mix-loc)
; Mix the contents of the bowl using the mixer.
(move mix-loc food-loc)
(pick-up tomato1 food-loc)
(move food-loc chop-loc)
(place-in tomato1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 tomato1 chop-loc)
; Pick up tomato and slice it on the chopping board.
(put-down knife1 chop-loc)
(move chop-loc mix-loc)
(pick-up mixing-bowl1 mix-loc)
(move mix-loc tray-loc)
(transfer mixing-bowl1 tray1 tray-loc)
; Transfer the dough from the mixing bowl to the tray.
(put-down mixing-bowl1 tray-loc)
(move tray-loc chop-loc)
(take-out tomato1 board1 chop-loc)
(move chop-loc tray-loc)
(place-in tomato1 tray1 tray-loc)
; Place the sliced tomato in the tray.
(pick-up tray1 tray-loc)
(move tray-loc food-loc)
(put-down tray1 food-loc)
; Move the tray to where the rest of the ingredients are.
(pick-up cheese1 food-loc)
(place-in cheese1 tray1 food-loc)
(pick-up sausage1 food-loc)
(place-in sausage1 tray1 food-loc)
; Place cheese and sausage in the tray.
(pick-up tray1 food-loc)
(move food-loc oven-loc)
(put-down tray1 oven-loc)
(cook bake tray1 oven1 oven-loc)
; Place the tray in the oven and bake it.
(pick-up tray1 oven-loc)
(move oven-loc plate-loc)
(transfer tray1 plate1 plate-loc)
; After baking, transfer everything on the tray to the plate.
