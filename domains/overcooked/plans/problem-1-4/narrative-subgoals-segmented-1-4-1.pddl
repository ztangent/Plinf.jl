; They move the chopping board to where the food is located.
; Number of subgoals: 2
(object-at-loc board1 food-loc)
(not (holding board1))
; They place tomato in the chopping board.
; Number of subgoals: 1
(in-receptacle tomato1 board1)
; They place lettuce in the chopping board.
; Number of subgoals: 1
(in-receptacle lettuce1 board1)
; They find the knife.
; Number of subgoals: 1
(holding knife1)
; They slice the tomato.
; Number of subgoals: 1
(prepared slice tomato1)
; They slice the lettuce.
; Number of subgoals: 1
(prepared slice lettuce1)
; They place cucumber in the chopping board.
; Number of subgoals: 1
(in-receptacle cucumber1 board1)
; They slice the cucumber.
; Number of subgoals: 1
(prepared slice cucumber1)
; They put down the knife.
; Number of subgoals: 1
(not (holding knife1))
; They transfer everything on the chopping board to a plate.
; Number of subgoals: 1
(forall (?f - food) (imply (is-prepared ?f) (in-receptacle ?f plate1)))
; They put down the chopping board.
; Number of subgoals: 1
(not (holding board1))
; They pick up the salad dressing.
; Number of subgoals: 1
(holding salad-dressing1)
; They add salad dressing to the plate.
; Number of subgoals: 1
(in-receptacle salad-dressing1 plate1)
; They place onion in the chopping board.
; Number of subgoals: 1
(in-receptacle onion1 board1)
; They slice the onion.
; Number of subgoals: 1
(prepared slice onion1)
; They transfer the sliced onion to the plate.
; Number of subgoals: 1
(in-receptacle onion1 plate1)
