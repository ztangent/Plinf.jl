(move start-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
(move mix-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
; Place flour and egg in the mixing bowl.
(move mix-loc food-loc)
(pick-up chocolate1 food-loc)
(move food-loc mix-loc)
(place-in chocolate1 mixing-bowl1 mix-loc)
; Add chocolate to the mixing bowl.
(combine mix mixing-bowl1 mixer1 mix-loc)
; Mix everything in the mixing bowl.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc oven-loc)
(transfer mixing-bowl1 tray1 oven-loc)
(cook bake tray1 oven1 oven-loc)
; Transfer the mixture in the mixing bowl to the tray, and bake it in the oven.
(move oven-loc plate-loc)
(put-down mixing-bowl1 plate-loc)
(move plate-loc oven-loc)
(pick-up tray1 oven-loc)
(move oven-loc plate-loc)
(transfer tray1 plate1 plate-loc)
; Transfer the baked food in the tray to the plate.
