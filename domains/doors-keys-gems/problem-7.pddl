;; ASCII ;;
; W: wall, D: door, k: key, g: gem, G: goal-gem, s: start, .: empty
; WgWWkWWgW
; W.WW.WWDW
; W..D.D..W
; WWWW.WWWW
; .......D.
; .WWW.WWW.
; .WWW.WWWD
; .WWWDWWW.
; sWWk.kWWG
(define (problem doors-keys-gems-7)
  (:domain doors-keys-gems)
  (:objects door1 door2 door3 door4 door5 door6 - door
            key1 key2 key3 - key
            gem1 gem2 gem3 - gem)
  (:init (locked door1)
         (locked door2)
         (locked door3)
         (locked door4)
         (locked door5)
         (locked door6)
         (= (walls)
            (transpose (bit-mat
               (bit-vec 1 0 1 1 0 1 1 0 1)
               (bit-vec 1 0 1 1 0 1 1 0 1)
               (bit-vec 1 0 0 0 0 0 0 0 1)
               (bit-vec 1 1 1 1 0 1 1 1 1)
               (bit-vec 0 0 0 0 0 0 0 0 0)
               (bit-vec 0 1 1 1 0 1 1 1 0)
               (bit-vec 0 1 1 1 0 1 1 1 0)
               (bit-vec 0 1 1 1 0 1 1 1 0)
               (bit-vec 0 1 1 0 0 0 1 1 0))))
         (= (xloc door5) 9)
         (= (xloc key2) 6)
         (= (xloc door3) 6)
         (= (xloc key1) 4)
         (= (xloc door6) 5)
         (= (xloc door4) 8)
         (= (xloc gem2) 8)
         (= (xloc door1) 8)
         (= (xloc door2) 4)
         (= (xloc key3) 5)
         (= (xloc gem3) 9)
         (= (xloc gem1) 2)
         (= (yloc door5) 7)
         (= (yloc key2) 9)
         (= (yloc door3) 3)
         (= (yloc key1) 9)
         (= (yloc door6) 8)
         (= (yloc door4) 5)
         (= (yloc gem2) 1)
         (= (yloc door1) 2)
         (= (yloc door2) 3)
         (= (yloc key3) 1)
         (= (yloc gem3) 9)
         (= (yloc gem1) 1)
         (= (xpos) 1)
         (= (ypos) 9))
  (:goal (has gem3))
)
