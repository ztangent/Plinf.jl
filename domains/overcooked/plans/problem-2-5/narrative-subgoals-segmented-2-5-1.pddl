; They place the rice in the pot on the stove.
; Number of subgoals: 1
(in-receptacle rice1 pot1)
; They boil the pot on the stove.
; Number of subgoals: 1
(forall (?f - food) (imply (in-receptacle ?f pot1) (cooked boil ?f)))
; They transfer the boiled rice onto a plate.
; Number of subgoals: 2
(in-receptacle rice1 plate1)
; Then they slice crab on a chopping board.
; Number of subgoals: 1
(prepared slice crab1)
; They place the sliced crab on the plate with the rice.
; Number of subgoals: 1
(in-receptacle crab1 plate1)
; They add cucumber to the plate of sliced crab.
; Number of subgoals: 1
(in-receptacle cucumber1 plate1)
; They add avocado to the plate of sliced crab.
; Number of subgoals: 1
(in-receptacle avocado1 plate1)
; They add nori to the plate of sliced crab.
; Number of subgoals: 1
(in-receptacle nori1 plate1)
