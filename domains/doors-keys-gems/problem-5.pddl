;; ASCII ;;
; W: wall, D: door, k: key, g: gem, G: goal-gem, s: start, .: empty
; k.......k
; WWWWDWWWW
; WWWW.WWWW
; WWWW.WWWW
; .D..k..D.
; .WWW.WWW.
; .WWWsWWWD
; .WWW.WWW.
; gWWWgWWWG
(define (problem doors-keys-gems-5)
  (:domain doors-keys-gems)
  (:objects door1 door2 door3 door4 - door
            key1 key2 key3 - key
            gem1 gem2 gem3 - gem)
  (:init (locked door1)
         (locked door2)
         (locked door3)
         (locked door4)
         (= (walls)
            (transpose (bit-mat
               (bit-vec 0 0 0 0 0 0 0 0 0)
               (bit-vec 1 1 1 1 0 1 1 1 1)
               (bit-vec 1 1 1 1 0 1 1 1 1)
               (bit-vec 1 1 1 1 0 1 1 1 1)
               (bit-vec 0 0 0 0 0 0 0 0 0)
               (bit-vec 0 1 1 1 0 1 1 1 0)
               (bit-vec 0 1 1 1 0 1 1 1 0)
               (bit-vec 0 1 1 1 0 1 1 1 0)
               (bit-vec 0 1 1 1 0 1 1 1 0))))
         (= (xloc gem3) 9)
         (= (xloc key1) 5)
         (= (xloc key2) 1)
         (= (xloc door3) 8)
         (= (xloc door1) 5)
         (= (xloc door2) 2)
         (= (xloc door4) 9)
         (= (xloc gem1) 1)
         (= (xloc key3) 9)
         (= (xloc gem2) 5)
         (= (yloc gem3) 9)
         (= (yloc key1) 5)
         (= (yloc key2) 1)
         (= (yloc door3) 5)
         (= (yloc door1) 2)
         (= (yloc door2) 5)
         (= (yloc door4) 7)
         (= (yloc gem1) 9)
         (= (yloc key3) 1)
         (= (yloc gem2) 9)
         (= (xpos) 5)
         (= (ypos) 7))
  (:goal (has gem3))
)
