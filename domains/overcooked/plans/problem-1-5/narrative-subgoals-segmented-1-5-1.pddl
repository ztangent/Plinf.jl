; They pick up the avocado.
; Number of subgoals: 1
(holding avocado1)
; They slice the avocado on the chopping board.
; Number of subgoals: 1
(prepared slice avocado1)
; They place the lettuce on the chopping board.
; Number of subgoals: 1
(in-receptacle lettuce1 board1)
; They place the tomato on the chopping board.
; Number of subgoals: 1
(in-receptacle tomato1 board1)
; They place the cheese on the chopping board.
; Number of subgoals: 1
(in-receptacle cheese1 board1)
; They chop the lettuce on the chopping board.
; Number of subgoals: 1
(prepared chop lettuce1)
; They slice the tomato on the chopping board.
; Number of subgoals: 1
(prepared slice tomato1)
; They slice the cheese on the chopping board.
; Number of subgoals: 1
(prepared slice cheese1)
; They transfer everything on the chopping board to the plate.
; Number of subgoals: 1
(forall (?f - food) (imply (is-prepared ?f) (in-receptacle ?f plate1)))
; They place bacon on the chopping board.
; Number of subgoals: 1
(in-receptacle bacon1 board1)
; They put on gloves.
; Number of subgoals: 1
(holding glove1)
; They crumble bacon onto the chopping board.
; Number of subgoals: 1
(prepared crumble bacon1)
; They transfer the crumbled bacon from the chopping board to the pan.
; Number of subgoals: 1
(in-receptacle bacon1 pan1)
; They grill the pan on the stove.
; Number of subgoals: 1
(cooked grill bacon1)
; They transfer the bacon from the pan to the plate.
; Number of subgoals: 1
(in-receptacle bacon1 plate1)
; They pick up an egg.
; Number of subgoals: 1
(holding egg1)
; They place the egg in a pot on the stove.
; Number of subgoals: 1
(in-receptacle egg1 pot1)
; They boil the pot on the stove.
; Number of subgoals: 1
(cooked boil egg1)
; They transfer the egg from the pot to the plate.
; Number of subgoals: 1
(in-receptacle egg1 plate1)
; They add salad dressing to the plate of food.
; Number of subgoals: 1
(in-receptacle salad-dressing1 plate1)
