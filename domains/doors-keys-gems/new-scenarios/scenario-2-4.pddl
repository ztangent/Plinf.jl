;; ASCII ;;
; W: wall, D: door, k: key, g: gem, G: goal-gem, s: start, .: empty
(define (problem doors-keys-gems-8)
  (:domain doors-keys-gems)
  (:objects
    up down left right - direction
    key1 key2 key3 - key
    gem1 gem2 gem3 - gem)
  (:init (= (xdiff up) 0) (= (ydiff up) 1)
         (= (xdiff down) 0) (= (ydiff down) -1)
         (= (xdiff right) 1) (= (ydiff right) 0)
         (= (xdiff left) -1) (= (ydiff left) 0)
         (= (width) 8) (= (height) 8) (= (xpos) 8) (= (ypos) 1)
         (wall 2 2) (wall 2 3) (wall 2 4) (wall 2 5)
         (wall 2 6) (wall 2 7) (wall 2 8)
         (wall 4 2) (wall 4 3) (wall 4 5) (wall 4 6) (wall 4 7)
         (wall 5 2) (wall 5 3) (wall 5 5) (wall 5 6) (wall 5 7)
         (wall 6 2) (wall 6 7)
         (wall 7 2) (wall 7 5) (wall 7 6) (wall 7 7)
         (wall 8 2) (wall 8 7) (wall 8 8)
         (door 3 6) (door 5 4) (door 8 5) (door 6 5)
         (doorloc 3 6) (doorloc 5 4) (doorloc 8 5) (doorloc 6 5)
         (at gem1 1 8) (at gem3 8 6) (at gem2 6 6)
         (itemloc 1 8) (itemloc 8 6) (itemloc 6 6)
         (at key1 1 1) (at key2 3 8) (at key3 7 8)
         (itemloc 1 1) (itemloc 3 8) (itemloc 7 8)
         )
  (:goal (has gem2))
)
