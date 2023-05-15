(move start-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
; Place flour in the mixing bowl.
(move mix-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
(combine mix mixing-bowl1 mixer1 mix-loc)
; Add egg to the mixing bowl, then mix the contents.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc tray-loc)
(transfer mixing-bowl1 tray1 tray-loc)
(put-down mixing-bowl1 tray-loc)
; Transfer everything in the mixing bowl to the tray.
(move tray-loc food-loc)
(pick-up cheese1 food-loc)
(move food-loc tray-loc)
(place-in cheese1 tray1 tray-loc)
(pick-up tray1 tray-loc)
(move tray-loc oven-loc)
(put-down tray1 oven-loc)
(cook bake tray1 oven1 oven-loc)
; Add cheese to the tray, place the tray in the oven, then bake it.
(pick-up tray1 oven-loc)
(move oven-loc plate-loc)
(transfer tray1 plate1 plate-loc)
; Transfer the baked contents to the plate.
