;; ASCII ;;
; W: wall, F: furniture, c: cylinder, b: block, s: start, .: empty
; sWF
; cW.
; b..
(define (problem ai2thor-2d-problem-1)
  (:domain ai2thor-2d)
  (:objects cylinder1 - cylinder block1 - block)
  (:init (= (width) (3))
         (= (height) (3))
         (= (xpos) (1))
         (= (ypos) (3))
         (handsfree)
         (= (xitem block1) (1))
         (= (yitem block1) (1))
         (= (xitem cylinder1) (1))
         (= (yitem cylinder1) (2))
         (wall 2 2)
         (wall 2 3)
         (furniture 3 3))
  (:goal (transfer block1 3 2))
)
