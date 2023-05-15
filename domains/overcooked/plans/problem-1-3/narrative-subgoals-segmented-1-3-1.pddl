; They move the chopping board to where the food is located.
; Number of subgoals: 2
(object-at-loc board1 food-loc)
(not (holding board1))
; They place the cucumber on the chopping board.
; Number of subgoals: 1
(in-receptacle cucumber1 board1)
; They place the onion on the chopping board.
; Number of subgoals: 1
(in-receptacle onion1 board1)
; They pick up the knife.
; Number of subgoals: 1
(holding knife1)
; They chop the onion.
; Number of subgoals: 1
(prepared chop onion1)
; They chop the cucumber.
; Number of subgoals: 1
(prepared chop cucumber1)
; They put down the knife.
; Number of subgoals: 1
(not (holding knife1))
; They place the tomato on the chopping board.
; Number of subgoals: 1
(in-receptacle tomato1 board1)
; They place the olive on the chopping board.
; Number of subgoals: 1
(in-receptacle olive1 board1)
; They chop the tomato.
; Number of subgoals: 1
(prepared chop tomato1)
; They chop the olive.
; Number of subgoals: 1
(prepared chop olive1)
; They find the gloves.
; Number of subgoals: 1
(holding glove1)
; They place the feta cheese on the chopping board.
; Number of subgoals: 1
(in-receptacle feta-cheese1 board1)
; They put on the gloves.
; Number of subgoals: 1
(holding glove1)
; They crumble feta cheese on the chopping board using the gloves.
; Number of subgoals: 1
(prepared crumble feta-cheese1)
; They transfer everything on the chopping board to the plate.
; Number of subgoals: 1
(forall (?f - food) (imply (is-prepared ?f) (in-receptacle ?f plate1)))
