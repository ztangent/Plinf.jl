;; ASCII ;;
; W: wall, D: door, k: key, g: gem, G: goal-gem, s: start, .: empty
; g..W...g
; k..D.Wk.
; .WWWWWWD
; .W..D.W.
; .W..W.W.
; ....W.W.
; WWW.W.W.
; s...W..G
(define (problem doors-keys-gems-3)
  (:domain doors-keys-gems)
  (:objects door1 door2 door3 - door key1 key2 - key gem1 gem2 gem3 - gem)
  (:init (locked door1)
         (locked door2)
         (locked door3)
         (= (walls)
            (transpose (bit-mat
               (bit-vec 0 0 0 1 0 0 0 0)
               (bit-vec 0 0 0 0 0 1 0 0)
               (bit-vec 0 1 1 1 1 1 1 0)
               (bit-vec 0 1 0 0 0 0 1 0)
               (bit-vec 0 1 0 0 1 0 1 0)
               (bit-vec 0 0 0 0 1 0 1 0)
               (bit-vec 1 1 1 0 1 0 1 0)
               (bit-vec 0 0 0 0 1 0 0 0))))
         (= (xloc door1) 4)
         (= (yloc door1) 2)
         (= (xloc door2) 8)
         (= (yloc door2) 3)
         (= (xloc door3) 5)
         (= (yloc door3) 4)
         (= (xloc key1) 1)
         (= (yloc key1) 2)
         (= (xloc key2) 7)
         (= (yloc key2) 2)
         (= (xloc gem1) 1)
         (= (yloc gem1) 1)
         (= (xloc gem2) 8)
         (= (yloc gem2) 1)
         (= (xloc gem3) 8)
         (= (yloc gem3) 8)
         (= (xpos) 1)
         (= (ypos) 8))
  (:goal (has gem3))
)
