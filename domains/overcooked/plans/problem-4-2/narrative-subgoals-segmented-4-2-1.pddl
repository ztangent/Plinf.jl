; They mix the flour and egg in the mixing bowl to become a dough.
; Number of subgoals: 2
(combined mix flour1)
(combined mix egg1)
; They transfer the egg-and-flour dough to the tray.
; Number of subgoals: 2
(in-receptacle egg1 tray1)
(in-receptacle flour1 tray1)
; They pick up the cheese.
; Number of subgoals: 1
(holding cheese1)
; They add the cheese to the tray.
; Number of subgoals: 1
(in-receptacle cheese1 tray1)
; They slice tomato on the chopping board.
; Number of subgoals: 1
(prepared slice tomato1)
; They slice the sausage on the chopping board.
; Number of subgoals: 1
(prepared slice sausage1)
; They transfer the sliced tomato and sausage from the chopping board to the tray.
; Number of subgoals: 2
(in-receptacle tomato1 tray1)
(in-receptacle sausage1 tray1)
; They bake everything on the tray in an oven.
; Number of subgoals: 1
(forall (?f - food) (imply (in-receptacle ?f tray1) (cooked bake ?f)))
; They transfer the baked contents of the tray to a plate.
; Number of subgoals: 1
(forall (?f - food) (imply (cooked bake ?f) (in-receptacle ?f plate1)))
