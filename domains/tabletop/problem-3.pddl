(define (problem blocks-3)
  (:domain blocks)
  (:objects
    table - block
    block1 - block
    block2 - block
    block3 - block)
  (:init
    (on table block1)
    (on block1 block2)
    (on block2 block3)
    (= (size table) 8)
    (= (size block1) 3)
    (= (size block2) 2)
    (= (size block3) 1)
    (= (amounton table) 3)
    (= (amounton block1) 2)
    (= (amounton block2) 1)
    (= (amounton block3) 0))
  (:goal (holding block1)))
