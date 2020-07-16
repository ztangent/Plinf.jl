(define (domain polycraft)
    (:requirements :fluents :adl :typing)
    (:types wood - block item)
    (:constants log planks stick rubber axe treetap pogostick - item)
    (:predicates (has ?i - item) (in-reach ?b - block) (tapped ?w - wood))
    (:action break-wood
     :parameters (?w - wood)
     :precondition (and (in-reach ?w))
     :effect (and (has log) (not (in-reach ?w)))
    )
    (:action craft-planks
     :precondition (and (has log))
     :effect (and (has planks) (not (has log)))
    )
    (:action craft-sticks
     :precondition (and (has planks))
     :effect (and (has sticks) (not (has planks)))
    )
    (:action craft-axe
     :precondition (and (has planks) (has sticks))
     :effect (and (has axe) (not (has planks)) (not (has sticks)))
    )
    (:action craft-treetap
     :precondition (and (has planks) (has sticks))
     :effect (and (has treetap) (not (has planks)) (not (has sticks)))
    )
    (:action craft-pogostick
     :precondition (and (has planks) (has sticks) (has rubber))
     :effect (and (has pogostick)
                  (not (has planks)) (not (has sticks)) (not (has rubber)))
    )
    (:action place-treetap
     :parameters (?w - wood)
     :precondition (and (has treetap) (in-reach ?w))
     :effect (and (tapped ?w) (not (has treetap)))
    )
    (:action extract-rubber
     :parameters (?w - wood)
     :precondition (and (in-reach ?w) (tapped ?w))
     :effect (and (has rubber))
    )
)
