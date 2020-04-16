(define (problem continuum-2d-1)
  (:domain continuum-2d)
  (:objects
    goal_area - area
  )
  (:init
    (= width 10) (= height 10)
    (= xpos 1) (= ypos 1)
    (wall 3 3 4 10) (wall 6 0 7 7)
    (extent goal_area 8 8 9 9)
  )
  (:goal (in_area goal_area xpos ypos))
)
