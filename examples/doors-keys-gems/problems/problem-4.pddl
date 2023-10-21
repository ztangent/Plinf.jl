;; ASCII ;;
; W: wall, D: door, k: key, g: gem, G: goal-gem, s: start, .: empty
; ....k....
; .WWW.WDW.
; .W.WkW.W.
; .W.WWW.W.
; .W.WGW.W.
; .W.WDW.W.
; .W.....W.
; .WWWgWWW.
; ..sWWWg..
(define (problem doors-keys-gems-4)
  (:domain doors-keys-gems)
  (:objects door1 door2 - door key1 key2 - key gem1 gem2 gem3 - gem)
  (:init (locked door1)
         (locked door2)
         (= (walls)
            (transpose (bit-mat
               (bit-vec 0 0 0 0 0 0 0 0 0)
               (bit-vec 0 1 1 1 0 1 0 1 0)
               (bit-vec 0 1 0 1 0 1 0 1 0)
               (bit-vec 0 1 0 1 1 1 0 1 0)
               (bit-vec 0 1 0 1 0 1 0 1 0)
               (bit-vec 0 1 0 1 0 1 0 1 0)
               (bit-vec 0 1 0 0 0 0 0 1 0)
               (bit-vec 0 1 1 1 0 1 1 1 0)
               (bit-vec 0 0 0 1 1 1 0 0 0))))
         (= (xloc door1) 7)
         (= (yloc door1) 2)
         (= (xloc door2) 5)
         (= (yloc door2) 6)
         (= (xloc key1) 5)
         (= (yloc key1) 3)
         (= (xloc key2) 5)
         (= (yloc key2) 1)
         (= (xloc gem1) 7)
         (= (yloc gem1) 9)
         (= (xloc gem2) 5)
         (= (yloc gem2) 8)
         (= (xloc gem3) 5)
         (= (yloc gem3) 5)
         (= (xpos) 3)
         (= (ypos) 9))
  (:goal (has gem3))
)
