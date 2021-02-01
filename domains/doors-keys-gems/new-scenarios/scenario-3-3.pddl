;; ASCII ;;
; W: wall, D: door, k: key, g: gem, G: goal-gem, s: start, .: empty
; WWWWWWWW
; k......W
; W.WWWW.W
; W.kD.W.W
; W.WW.W.W
; W.WGDW.W
; W.GWG..W
; WWWWWWWW
(define (problem doors-keys-gems-3)
  (:domain doors-keys-gems)
  (:objects
    up down right left - direction
    key1 key2 - key
    gem1 gem2 gem3 - gem
  )
  (:init
    (= (xdiff up) 0) (= (ydiff up) 1)
    (= (xdiff down) 0) (= (ydiff down) -1)
    (= (xdiff right) 1) (= (ydiff right) 0)
    (= (xdiff left) -1) (= (ydiff left) 0)
    (= width 8) (= height 8)
    (= xpos 7) (= ypos 6)
    (wall 1 1) (wall 1 2) (wall 1 3) (wall 1 4)
    (wall 1 5) (wall 1 6) (wall 1 8)
    (wall 2 1) (wall 2 8)
    (wall 3 1) (wall 3 3) (wall 3 4) (wall 3 6)
    (wall 3 8)
    (wall 4 1) (wall 4 2) (wall 4 4) (wall 4 6)
    (wall 4 8)
    (wall 5 1) (wall 5 6) (wall 5 8)
    (wall 6 1) (wall 6 3) (wall 6 4) (wall 6 5)
    (wall 6 6) (wall 6 8)
    (wall 7 1) (wall 7 8)
    (wall 8 1) (wall 8 2) (wall 8 3) (wall 8 4)
    (wall 8 5) (wall 8 6) (wall 8 7) (wall 8 8)
    (door 4 5) (door 5 3)
    (doorloc 4 5) (doorloc 5 3)
    (at key1 1 7) (at key2 3 5)
    (at gem1 3 2) (at gem2 4 3) (at gem3 5 2)
    (itemloc 1 7) (itemloc 3 5)
    (itemloc 3 2) (itemloc 4 3) (itemloc 5 2)
  )
  (:goal (has gem2))
)
