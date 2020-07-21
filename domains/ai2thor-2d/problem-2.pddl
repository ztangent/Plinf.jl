;; ASCII ;;
; W: wall, F: furniture, c: cylinder, b: block, s: start, .: empty
; .....
; .WcF.
; sW.F.
; .WbF.
; .....
(define (problem ai2thor-2d-problem-2)
  (:domain ai2thor-2d)
  (:objects cylinder1 - cylinder block1 - block)
  (:init (= (width) (5))
         (= (height) (5))
         (= (xpos) (1))
         (= (ypos) (3))
         (handsfree)
         (wall 2 2)
         (= (xitem block1) (3))
         (= (yitem block1) (2))
         (furniture 4 2)
         (wall 2 3)
         (furniture 4 3)
         (wall 2 4)
         (= (xitem cylinder1) (3))
         (= (yitem cylinder1) (4))
         (furniture 4 4))
  (:goal (transfer cylinder1 5 1))
)
