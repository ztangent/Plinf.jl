;; ASCII ;;
; W: wall, D: door, k: key, g: gem, G: goal-gem, s: start, .: empty
; .WWkWGWG
; .WW.W.W.
; .WW.W.WD
; ......W.
; .WWWW.WD
; ........
; WWWW.WWW
; WkkD....
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
    (= xpos 2) (= ypos 5)
    (wall 1 1) (wall 1 2)
    (wall 2 2) (wall 2 4) (wall 2 6) (wall 2 7)
    (wall 2 8)
    (wall 3 2) (wall 3 4) (wall 3 6) (wall 3 7)
    (wall 3 8)
    (wall 4 2) (wall 4 4)
    (wall 5 4) (wall 5 6) (wall 5 7) (wall 5 8)
    (wall 6 2)
    (wall 7 2) (wall 7 4) (wall 7 5) (wall 7 6)
    (wall 7 7) (wall 7 8)
    (wall 8 2)
    (door 4 1) (door 8 4) (door 8 6)
    (doorloc 4 1) (doorloc 8 4) (doorloc 8 6)
    (at key1 4 8) (at key2 2 1) (at key3 3 1)
    (at gem1 8 1) (at gem2 6 8) (at gem3 8 8)
    (itemloc 4 8) (itemloc 2 1) (itemloc 3 1)
    (itemloc 8 1) (itemloc 6 8) (itemloc 8 8)
  )
  (:goal (has gem3))
)
