; They place the rice in a pot on the stove.
; Number of subgoals: 1
(in-receptacle rice1 pot1)
; They boil the pot on the stove.
; Number of subgoals: 1
((forall (?f - food) (imply (in-receptacle ?f pot1) (cooked boil ?f))))
; After the rice is cooked, they transfer the rice to the plate.
; Number of subgoals: 1
(in-receptacle rice1 plate1)
; They slice the salmon on the chopping board.
; Number of subgoals: 1
(prepared slice salmon1)
; They transfer the sliced salmon to the plate of rice.
; Number of subgoals: 2
(in-receptacle salmon1 plate1)
; They pick up the nori.
; Number of subgoals: 1
(holding nori1)
; They assemble the nori with the rice and salmon in the plate.
; Number of subgoals: 1
(in-receptacle nori1 plate1)
