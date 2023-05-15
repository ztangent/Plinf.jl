; They pick up the tuna.
; Number of subgoals: 1
(holding tuna1)
; They slice the tuna on the chopping board.
; Number of subgoals: 1
(prepared slice tuna1)
; They transfer the sliced tuna to the plate.
; Number of subgoals: 1
(in-receptacle tuna1 plate1)
; They pick up the rice.
; Number of subgoals: 1
(holding rice1)
; They put the rice in a pot of water.
; Number of subgoals: 1
(in-receptacle rice1 pot1)
; They boil the pot on the stove.
; Number of subgoals: 1
((forall (?f - food) (imply (in-receptacle ?f pot1) (cooked boil ?f))))
; When the rice is cooked, they transfer the rice from the pot to the plate of sliced tuna.
; Number of subgoals: 1
(in-receptacle rice1 plate1)
; They pick up the nori.
; Number of subgoals: 1
(holding nori1)
; They assemble the nori with the rice and tuna in the plate.
; Number of subgoals: 1
(in-receptacle nori1 plate1)
