; They pick up milk.
; Number of subgoals: 1
(holding milk1)
; They pour the milk into the blender jug.
; Number of subgoals: 1
(in-receptacle milk1 blender-jug1)
; They place chocolate into the blender jug.
; Number of subgoals: 1
(in-receptacle chocolate1 blender-jug1)
; They add ice to the blender jug.
; Number of subgoals: 1
(in-receptacle ice1 blender-jug1)
; They blend everything in the blender jug.
; Number of subgoals: 1
(forall (?f - food) (imply (in-receptacle ?f blender-jug1) (combined blend ?f)))
; They pour the blended mixture into a glass.
; Number of subgoals: 1
(forall (?f - food) (imply (combined blend ?f) (in-receptacle ?f glass1)))
