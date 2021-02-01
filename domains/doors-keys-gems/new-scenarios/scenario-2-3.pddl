;; ASCII ;;
; W: wall, D: door, k: key, g: gem, G: goal-gem, s: start, .: empty
; GWGWWW..
; .W..WW.k
; DW..WW.k
; .WW.WW..
; .WW..D..
; .Dk.WWWW
; WWW..D..
; WWW.WWWG
(define (problem doors-keys-gems-3)
  (:domain doors-keys-gems)
  (:objects
    up down right left - direction
    key1 key2 key3 - key
    gem1 gem2 gem3 - gem
  )
  (:init
    (= (xdiff up) 0) (= (ydiff up) 1)
    (= (xdiff down) 0) (= (ydiff down) -1)
    (= (xdiff right) 1) (= (ydiff right) 0)
    (= (xdiff left) -1) (= (ydiff left) 0)
    (= width 8) (= height 8)
    (= xpos 4) (= ypos 1)
    (wall 1 1) (wall 1 2)
    (wall 2 1) (wall 2 2) (wall 2 4) (wall 2 5)
    (wall 2 6) (wall 2 7) (wall 2 8)
    (wall 3 1) (wall 3 2) (wall 3 4) (wall 3 5)
    (wall 4 8)
    (wall 5 1) (wall 5 3) (wall 5 5)
    (wall 5 6) (wall 5 7) (wall 5 8)
    (wall 6 1) (wall 6 3) (wall 6 5) (wall 6 6)
    (wall 6 7) (wall 6 8)
    (wall 7 1) (wall 7 3) (wall 8 3)
    (door 1 6) (door 2 3) (door 6 2) (door 6 4)
    (doorloc 1 6) (doorloc 2 3) (doorloc 6 2) (doorloc 6 4)
    (at key1 3 3) (at key2 8 8) (at key3 8 7)
    (at gem1 1 8) (at gem2 3 8) (at gem3 8 1)
    (itemloc 3 3) (itemloc 8 8) (itemloc 8 7)
    (itemloc 1 8) (itemloc 3 8) (itemloc 8 1)
  )
  (:goal (has gem3))
)
