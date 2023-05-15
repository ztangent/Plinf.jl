; They take the flour and put it in a mixing bowl.
; Number of subgoals: 1
(in-receptacle flour1 mixing-bowl1)
; They take the egg and put it in a mixing bowl.
; Number of subgoals: 1
(in-receptacle egg1 mixing-bowl1)
; They mix the egg and flour into a dough in a mixing bowl.
; Number of subgoals: 2
(combined mix flour1)
(combined mix egg1)
; They transfer the egg-and-flour dough to the tray.
; Number of subgoals: 2
(in-receptacle egg1 tray1)
(in-receptacle flour1 tray1)
; They pick up the tomato.
; Number of subgoals: 1
(holding tomato1)
; They slice the tomato in the chopping board.
; Number of subgoals: 1
(prepared slice tomato1)
; They place the sliced tomato on the tray with the dough.
; Number of subgoals: 1
(in-receptacle tomato1 tray1)
; They get the cheese.
; Number of subgoals: 1
(holding cheese1)
; They add the cheese to the tray.
; Number of subgoals: 1
(in-receptacle cheese1 tray1)
; They get the basil.
; Number of subgoals: 1
(holding basil1)
; They add the basil to the tray.
; Number of subgoals: 1
(in-receptacle basil1 tray1)
; They bake the tray in the oven.
; Number of subgoals: 1
(forall (?f - food) (imply (in-receptacle ?f tray1) (cooked bake ?f)))
; They transfer everything on the baking tray to the plate.
; Number of subgoals: 1
(forall (?f - food) (imply (cooked bake ?f) (in-receptacle ?f plate1)))
