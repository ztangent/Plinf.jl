; ................
; ...s.........i..
; ..WWWWW.........
; ....i...........
; ................
; ................
; ......fffff.....
; ......fffff.....
; ................
; ................
; ..........fff...
; ...W......fcf...
; .i.W............
; ...W............
; ...W............
; ...W............
(define (problem ai2thor-2d-problem)
  (:domain ai2thor-2d)
  (:objects container1 fixed1 fixed10 fixed11 fixed12 fixed13 fixed14 fixed15
            fixed2 fixed3 fixed4 fixed5 fixed6 fixed7 fixed8 fixed9 - fixed
            item1 item2 item3 target1 - item)
  (:init (= (width) (16))
         (= (height) (16))
         (= (xpos) (4))
         (= (ypos) (15))
         (handsfree)
         (wall 4 1)
         (wall 4 2)
         (wall 4 3)
         (= (xobj item1) (2))
         (= (yobj item1) (4))
         (wall 4 4)
         (wall 4 5)
         (= (xobj fixed1) (11))
         (= (yobj fixed1) (5))
         (= (xobj fixed2) (12))
         (= (yobj fixed2) (5))
         (= (xobj fixed3) (13))
         (= (yobj fixed3) (5))
         (= (xobj fixed4) (11))
         (= (yobj fixed4) (6))
         (= (xobj target1) (12))
         (= (yobj target1) (6))
         (= (xobj container1) (12))
         (= (yobj container1) (6))
         (receptacle container1)
         (openable container1)
         (inside target1 container1)
         (hidden target1)
         (= (xobj fixed5) (13))
         (= (yobj fixed5) (6))
         (= (xobj fixed6) (7))
         (= (yobj fixed6) (9))
         (= (xobj fixed7) (8))
         (= (yobj fixed7) (9))
         (= (xobj fixed8) (9))
         (= (yobj fixed8) (9))
         (= (xobj fixed9) (10))
         (= (yobj fixed9) (9))
         (= (xobj fixed10) (11))
         (= (yobj fixed10) (9))
         (= (xobj fixed11) (7))
         (= (yobj fixed11) (10))
         (= (xobj fixed12) (8))
         (= (yobj fixed12) (10))
         (= (xobj fixed13) (9))
         (= (yobj fixed13) (10))
         (= (xobj fixed14) (10))
         (= (yobj fixed14) (10))
         (= (xobj fixed15) (11))
         (= (yobj fixed15) (10))
         (= (xobj item2) (5))
         (= (yobj item2) (13))
         (wall 3 14)
         (wall 4 14)
         (wall 5 14)
         (wall 6 14)
         (wall 7 14)
         (= (xobj item3) (14))
         (= (yobj item3) (15)))
  (:goal (and (retrieve target1)))
)
