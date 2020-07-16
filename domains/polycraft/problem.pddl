(define (problem polycraft)
  (:domain polycraft)
  (:objects
    tree1 tree2 tree3 tree4 tree5 tree6 - wood
  )
  (:init
    (in-reach tree1) (in-reach tree2) (in-reach tree3)
    (in-reach tree4) (in-reach tree5) (in-reach tree6)
  )
  (:goal (has pogostick))
)
