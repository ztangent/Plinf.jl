; They place flour in the mixing bowl.
; Number of subgoals: 1
(in-receptacle flour1 mixing-bowl1)
; They place egg in the mixing bowl.
; Number of subgoals: 1
(in-receptacle egg1 mixing-bowl1)
; They add chocolate to the mixing bowl.
; Number of subgoals: 1
(in-receptacle chocolate1 mixing-bowl1)
; They mix everything in the mixing bowl.
; Number of subgoals: 1
(forall (?f - food) (imply (in-receptacle ?f mixing-bowl1) (combined mix ?f)))
; They transfer the mixture in the mixing bowl to the tray.
; Number of subgoals: 1
(forall (?f - food) (imply (combined mix ?f) (in-receptacle ?f tray1)))
; They bake the tray in the oven.
; Number of subgoals: 1
(forall (?f - food) (imply (in-receptacle ?f tray1) (cooked bake ?f)))
; They transfer the baked food in the tray to the plate.
; Number of subgoals: 1
(forall (?f - food) (imply (cooked bake ?f) (in-receptacle ?f plate1)))
