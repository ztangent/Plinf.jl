(define (domain blocks)
  (:requirements :fluents :equality)
  (:predicates
    (on ?x - bottomblock ?y - topblock)
    (holding ?x - block))
  (:functions (size ?x - block)
              (amounton ?x - block))
  (:derived (fits ?x - bottomblock ?y - topblock)
            (not (< (size ?x) (+ (amounton ?x) (size ?y)))))
  (:derived (handempty)
            (forall (?x) (not (holding ?x))))
  (:action pickup
    :parameters (?x ?y)
    :precondition (and (on ?x ?y) (= (amounton ?y) 0) (handempty))
    :effect
      (and (not (on ?x ?y))
           (holding ?y)
           (decrease (amounton ?x) (size ?y))))
  (:action putdown
    :parameters (?x ?y)
    :precondition (and (holding ?y) (fits ?x ?y))
    :effect
      (and (not (holding ?y))
           (on ?x ?y))
           (increase (amounton ?x) (size ?y))))
