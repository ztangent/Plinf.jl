; They mix the flour and egg in the mixing bowl.
; Number of subgoals: 2
(combined mix egg1)
(combined mix flour1)
; The find the ham and place it on the chopping board.
; Number of subgoals: 1
(in-receptacle ham1 board1)
; They find the tomato and place it on the chopping board.
; Number of subgoals: 1
(in-receptacle tomato1 board1)
; They slice the tomato on the chopping board.
; Number of subgoals: 1
(prepared slice tomato1)
; They slice the ham on the chopping board.
; Number of subgoals: 1
(prepared slice ham1)
; They pick up the cheese.
; Number of subgoals: 1
(holding cheese1)
; They place the cheese on the chopping board.
; Number of subgoals: 1
(in-receptacle cheese1 board1)
; They go to the mixing bowl and pick it up.
; Number of subgoals: 1
(holding mixing-bowl1)
; They transfer the egg and flour mixture to the tray.
; Number of subgoals: 2
(in-receptacle egg1 tray1)
(in-receptacle flour1 tray1)
; They transfer everything from the chopping board onto the tray.
; Number of subgoals: 1
(forall (?f - food) (imply (is-prepared ?f) (in-receptacle ?f tray1)))
; They put down the chopping board.
; Number of subgoals: 1
(not (holding board1))
; They place the pineapple on the chopping board.
; Number of subgoals: 1
(in-receptacle pineapple1 board1)
; They chop the pineapple on the chopping board.
; Number of subgoals: 1
(prepared chop pineapple1)
; They place the chopped pineapple into the tray.
; Number of subgoals: 1
(in-receptacle pineapple1 tray1)
; They bake the tray in the oven.
; Number of subgoals: 1
(forall (?f - food) (imply (in-receptacle ?f tray1) (cooked bake ?f)))
; They transfer the baked food in the tray to the plate.
; Number of subgoals: 1
(forall (?f - food) (imply (cooked bake ?f) (in-receptacle ?f plate1)))
