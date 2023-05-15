; They add an egg to the mixing bowl.
; Number of subgoals: 1
(in-receptacle egg1 mixing-bowl1)
; They add flour to the mixing bowl.
; Number of subgoals: 1
(in-receptacle flour1 mixing-bowl1)
; They mix the flour and egg using a mixer.
; Number of subgoals: 2
(combined mix egg1)
(combined mix flour1)
; They transfer the mixture to a tray.
; Number of subgoals: 1
(forall (?f - food) (imply (combined mix ?f) (in-receptacle ?f tray1)))
; They put down the mixing bowl.
; Number of subgoals: 1
(not (holding mixing-bowl1))
; They place an apple on the chopping board.
; Number of subgoals: 1
(in-receptacle apple1 board1)
; They slice the apple.
; Number of subgoals: 1
(prepared slice apple1)
; They take the apple from the chopping board.
; Number of subgoals: 1
(holding apple1)
; They place the apple in the tray.
; Number of subgoals: 1
(in-receptacle apple1 tray1)
; They bake the tray in the oven.
; Number of subgoals: 1
(forall (?f - food) (imply (in-receptacle ?f tray1) (cooked bake ?f)))
; After baking, they transfer the baked food to the plate.
; Number of subgoals: 1
(forall (?f - food) (imply (cooked bake ?f) (in-receptacle ?f plate1)))
