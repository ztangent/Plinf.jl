; They mix the flour and egg in the mixing bowl to become a dough.
; Number of subgoals: 2
(combined mix flour1)
(combined mix egg1)
; They transfer the egg-and-flour dough to the tray.
; Number of subgoals: 2
(in-receptacle egg1 tray1)
(in-receptacle flour1 tray1)
; They pick up the chopping board.
; Number of subgoals: 1
(holding board1)
; They place the chopping board next to the food.
; Number of subgoals: 2
(object-at-loc board1 food-loc)
(not (holding board1))
; They place mushroom on the chopping board.
; Number of subgoals: 1
(in-receptacle mushroom1 board1)
; They add onion to the chopping board.
; Number of subgoals: 1
(in-receptacle onion1 board1)
; They add olive to the chopping board.
; Number of subgoals: 1
(in-receptacle olive1 board1)
; They slice the onion on the chopping board.
; Number of subgoals: 1
(prepared slice onion1)
; They slice the olive on the chopping board.
; Number of subgoals: 1
(prepared slice olive1)
; They slice the mushroom on the chopping board.
; Number of subgoals: 1
(prepared slice mushroom1)
; They place tomato on the chopping board.
; Number of subgoals: 1
(in-receptacle tomato1 board1)
; They slice the tomato.
; Number of subgoals: 1
(prepared slice tomato1)
; They transfer everything on the chopping board into the tray.
; Number of subgoals: 1
(forall (?f - food) (imply (is-prepared ?f) (in-receptacle ?f tray1)))
; They add cheese to the tray.
; Number of subgoals: 1
(in-receptacle cheese1 tray1)
; They bake the tray in the oven.
; Number of subgoals: 1
(forall (?f - food) (imply (in-receptacle ?f tray1) (cooked bake ?f)))
; They transfer the baked food in the tray to the plate.
; Number of subgoals: 1
(forall (?f - food) (imply (cooked bake ?f) (in-receptacle ?f plate1)))
