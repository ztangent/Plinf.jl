(define (problem doors-keys-gems-2)
  (:domain doors-keys-gems)
  (:objects
    up down right left - direction
    key1 - key gem1 gem2 - gem
  )
  (:init
    (= (xdiff up) 0) (= (ydiff up) 1)
    (= (xdiff down) 0) (= (ydiff down) -1)
    (= (xdiff right) 1) (= (ydiff right) 0)
    (= (xdiff left) -1) (= (ydiff left) 0)
    (= width 5) (= height 5)
    (= xpos 1) (= ypos 3)
    (wall 2 2) (wall 2 3) (wall 2 4)
    (door 4 1) (wall 4 2) (wall 4 3) (wall 4 4) (door 4 5)
    (at key1 3 3) (at gem1 5 2) (at gem2 5 4)
  )
  (:goal (has gem1))
)
