(define (problem blocks-2)
  (:domain blocks)
  (:objects
    table - block
    block1 - block
    block2 - block)
  (:init
    (on table block1)
    (holding block2)
    (= (size table) 4)
    (= (size block1) 1)
    (= (size block2) 2)
    (= (amounton table) 1)
    (= (amounton block1) 0)
    (= (amounton block2) 0))
  (:goal (holding block1)))
