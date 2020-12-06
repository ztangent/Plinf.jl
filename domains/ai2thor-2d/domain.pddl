(define (domain ai2thor-2d)
    (:requirements :fluents :adl :typing)
    (:types movable fixed - object
            item - movable)
    (:predicates
        (wall ?x ?y) ; whether there is a wall at (x, y)
        (obstacle ?x ?y) ; whether there is an obstacle at (x, y)
        (receptacle ?o - object) ; whether an object is a receptable
        (openable ?o - object) ; whether an object is openable
        (isopen ?o - object) ; whether an openable object is open
        (inside ?i - item ?o - object) ; whether an item is inside a container
        (hidden ?i - item) ; whether an item is hidden (inside a container)
        (has ?i - item) ; whether the agent is carrying the item
        (handsfree) ; whether the agent has their hands free
        (on ?o - object) ; whether the agent is co-located with an object
        (adjacent ?o - object) ; whether the agent is adjacent to an object
        (reach ?x ?y) ; whether the agent is at location (x, y)
        (retrieve ?i - item) ; whether the agent has retrieved item i
        (transfer ?i - item ?x ?y) ; whether the item has been placed at (x, y)
    )
    (:derived (obstacle ?x ?y) (or
        (wall ?x ?y)
        (exists (?f - fixed) (and (= (xobj ?f) ?x) (= (yobj ?f) ?y)))
    ))
    (:derived (on ?o) (and (= (xpos) (xobj ?o)) (= (ypos) (yobj ?o))))
    (:derived (adjacent ?o) (or
        (and (= (+ (xpos) 1) (xobj ?o)) (= (ypos) (yobj ?o)))
        (and (= (- (xpos) 1) (xobj ?o)) (= (ypos) (yobj ?o)))
        (and (= (+ (ypos) 1) (yobj ?o)) (= (xpos) (xobj ?o)))
        (and (= (- (ypos) 1) (yobj ?o)) (= (xpos) (xobj ?o)))
    ))
    (:derived (reach ?x ?y) (and (= (xpos) ?x) (= (ypos) ?y)))
    (:derived (retrieve ?i) (has ?i))
    (:derived (transfer ?i ?x ?y)
              (and (= (xobj ?i) ?x) (= (yobj ?i) ?y) (not (has ?i))))
    (:functions (xpos) (ypos) (width) (height)
                (xobj ?i - item) (yobj ?i - item))
    (:action pickup
     :parameters (?i - item)
     :precondition (and (handsfree) (not (hidden ?i))
                        (or (on ?i) (adjacent ?i)))
     :effect (and (has ?i)
                  (forall (inside ?i ?o) (not (inside ?i ?o)))
                  (assign (xobj ?i) (xpos)) (assign (yobj ?i) (ypos)))
    )
    (:action drop
     :parameters (?i - item)
     :precondition (has ?i)
     :effect (and (handsfree) (not (has ?i)))
    )
    (:action put
     :parameters (?i - item ?r - object)
     :precondition (and (has ?i) (receptacle ?r)
                        (imply (openable ?r) (isopen ?r))
                        (adjacent ?r))
     :effect (and (handsfree) (not (has ?i)) (inside ?i ?r)
                  (assign (xobj ?i) (xobj ?r)) (assign (yobj ?i) (yobj ?r)))
    )
    (:action open
     :parameters (?o - object)
     :precondition (and (openable ?o) (not (isopen ?o)) (adjacent ?o))
     :effect (and (isopen ?o)
                  (forall (inside ?i ?o) (not (hidden ?i))))
    )
    (:action close
     :parameters (?o - object)
     :precondition (and (openable ?o) (isopen ?o) (adjacent ?o))
     :effect (and (not (isopen ?o))
                  (forall (inside ?i ?o) (hidden ?i)))
    )
    (:action up
     :precondition (and (< ypos height) (not (obstacle xpos (+ ypos 1))))
     :effect (and (increase ypos 1)
                  (forall (has ?i) (increase (yobj ?i) 1)))
    )
    (:action down
     :precondition (and (> ypos 1) (not (obstacle xpos (- ypos 1))))
     :effect (and (decrease ypos 1)
                  (forall (has ?i) (decrease (yobj ?i) 1)))
    )
    (:action right
     :precondition (and (< xpos width) (not (obstacle (+ xpos 1) ypos)))
     :effect (and (increase xpos 1)
                  (forall (has ?i) (increase (xobj ?i) 1)))
    )
    (:action left
     :precondition (and (> xpos 1) (not (obstacle (- xpos 1) ypos)))
     :effect (and (decrease xpos 1)
                  (forall (has ?i) (decrease (xobj ?i) 1)))
    )
)
