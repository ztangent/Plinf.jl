; They mix the flour and egg in the mixing bowl to become a dough.
; Number of subgoals: 2
(combined mix flour1)
(combined mix egg1)
; They slice the tomato on the chopping board.
; Number of subgoals: 1
(prepared slice tomato1)
; They chop the beef on the chopping board.
; Number of subgoals: 1
(prepared chop beef1)
; They put down the knife.
; Number of subgoals: 1
(not (holding knife1))
; They pick up the mixing bowl.
; Number of subgoals: 1
(holding mixing-bowl1)
; They transfer the egg-and-flour dough to the tray.
; Number of subgoals: 2
(in-receptacle egg1 tray1)
(in-receptacle flour1 tray1)
; They go back to the chopping board.
; Number of subgoals: 1
(agent-at-loc chop-loc)
; They chop chicken on the chopping board.
; Number of subgoals: 1
(prepared chop chicken1)
; They slice sausage on the chopping board.
; Number of subgoals: 1
(prepared slice sausage1)
; They transfer everything on the chopping board to the tray.
; Number of subgoals: 1
(forall (?f - food) (imply (is-prepared ?f) (in-receptacle ?f tray1)))
; They add cheese to the tray.
; Number of subgoals: 1
(in-receptacle cheese1 tray1)
; They bake everything on the tray in the oven.
; Number of subgoals: 1
(forall (?f - food) (imply (in-receptacle ?f tray1) (cooked bake ?f)))
; They transfer the baked food in the tray to the plate.
; Number of subgoals: 1
(forall (?f - food) (imply (cooked bake ?f) (in-receptacle ?f plate1)))
