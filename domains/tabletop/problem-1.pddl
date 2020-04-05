(define (problem blocks-1)
  (:domain blocks)
  (:objects
    table - block
    block1 - block)
  (:init
    (on table block1)
    (size table 4)
    (size block1 1)
    (amounton table 1)
    (amounton block1 0))
  (:goal (holding block1)))
