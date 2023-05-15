; They place flour in the mixing bowl.
; Number of subgoals: 1
(in-receptacle flour1 mixing-bowl1)
; They place the egg in the mixing bowl.
; Number of subgoals: 1
(in-receptacle egg1 mixing-bowl1)
; They add chocolate to the mixing bowl.
; Number of subgoals: 1
(in-receptacle chocolate1 mixing-bowl1)
; They mix everything in the mixing bowl.
; Number of subgoals: 1
(forall (?f - food) (imply (in-receptacle ?f mixing-bowl1) (combined mix ?f)))
; They transfer the chocolate, flour, and egg mixture into a fryer basket.
; Number of subgoals: 3
(in-receptacle flour1 basket1)
(in-receptacle chocolate1 basket1)
(in-receptacle egg1 basket1)
; They deep fry everything.
; Number of subgoals: 1
(forall (?f - food) (imply (in-receptacle ?f basket1) (cooked deep-fry ?f)))
; They transfer the deep fried food to a plate.
; Number of subgoals: 1
(forall (?f - food) (imply (cooked deep-fry ?f) (in-receptacle ?f plate1)))
