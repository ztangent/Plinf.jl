; They slice the tuna on the chopping board.
; Number of subgoals: 1
(prepared slice tuna1)
; They place the sliced tuna on the plate.
; Number of subgoals: 1
(in-receptacle tuna1 plate1)
; They place the rice in a pot on the stove.
; Number of subgoals: 1
(in-receptacle rice1 pot1)
; They boil the pot on the stove.
; Number of subgoals: 1
((forall (?f - food) (imply (in-receptacle ?f pot1) (cooked boil ?f))))
; They transfer the cooked rice to the plate of sliced tuna.
; Number of subgoals: 1
(in-receptacle rice1 plate1)
