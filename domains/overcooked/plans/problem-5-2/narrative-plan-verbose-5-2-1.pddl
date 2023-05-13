(move start-loc food-loc)
(pick-up flour1 food-loc)
(move food-loc mix-loc)
(place-in flour1 mixing-bowl1 mix-loc)
; They place flour in the mixing bowl. This involves picking up the flour, moving to the mixing bowl, and placing the flour in the mixing bowl.
(move mix-loc food-loc)
(pick-up egg1 food-loc)
(move food-loc mix-loc)
(place-in egg1 mixing-bowl1 mix-loc)
; They place egg in the mixing bowl. This involves picking up the egg, moving to the mixing bowl, and placing the egg in the mixing bowl.
(move mix-loc food-loc)
(pick-up chocolate1 food-loc)
(move food-loc mix-loc)
(place-in chocolate1 mixing-bowl1 mix-loc)
; They add chocolate to the mixing bowl. This involves picking up the chocolate, moving to the mixing bowl, and placing the chocolate in the mixing bowl.
(combine mix mixing-bowl1 mixer1 mix-loc)
; They mix everything in the mixing bowl. This involves no additional actions.
(pick-up mixing-bowl1 mix-loc)
(move mix-loc oven-loc)
(transfer mixing-bowl1 tray1 oven-loc)
; They transfer the mixture in the mixing bowl to the tray. This involves picking up the mixing bowl, moving to the oven, and transferring the contents of the mixing bowl to the tray.
(cook bake tray1 oven1 oven-loc)
; They bake the tray in the oven. This involves no additional actions.
(move oven-loc plate-loc)
(put-down mixing-bowl1 plate-loc)
(move plate-loc oven-loc)
(pick-up tray1 oven-loc)
(move oven-loc plate-loc)
(transfer tray1 plate1 plate-loc)
; They transfer the baked food in the tray to the plate. This invloves first putting down the mixing bowl somewhere convenient, then picking up the tray, moving to the plate, and transferring the contents of the tray to the plate.
