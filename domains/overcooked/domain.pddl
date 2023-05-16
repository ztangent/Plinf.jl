(define (domain overcooked)
  (:requirements :adl :typing :equality)
  (:types
    location - object ; Locations of objects and the agent
    food receptacle tool - item ; Objects that can be held and moved
    item appliance - physical ; Objects that have physical locations
    ftype rtype ttype atype - type ; Food, receptacle, tool and appliance types
    prepare-method combine-method cook-method - method ; Methods for cooking, etc
  )
  (:predicates
    ;; Static predicates

    ; Whether food ingredient ?f is of type ?ty
    (food-type ?ty - ftype ?f - food)
    ; Whether receptacle ?r is of type ?ty
    (receptacle-type ?ty - rtype ?r - receptacle)
    ; Whether tool ?t is of type ?ty
    (tool-type ?ty - ttype ?t - tool)
    ; Whether appliance ?a has type ?ty
    (appliance-type ?ty - atype ?a - appliance)

    ; Whether ?r-typed receptacle and ?t-typed tool can prepare via method ?m
    (has-prepare-method ?m - prepare-method ?r - rtype ?t - ttype)
    ; Whether ?r-typed receptacle and ?a-typed appliance can combine via method ?m
    (has-combine-method ?m - combine-method ?r - rtype ?a - atype)
    ; Whether ?r-typed receptacle and ?a-typed appliance can cook via method ?m
    (has-cook-method ?m - cook-method ?r - rtype ?a - atype)

    ;; Dynamic predicates

    ; Whether agent is at location ?l
    (agent-at-loc ?l - location)
    ; Whether object is at location ?l
    (object-at-loc ?o - physical ?l - location)

    ; Whether the agent is not holding anything
    (handempty)
    ; Whether the agent is holding item ?i
    (holding ?i - item)

    ; Whether food item ?i is in or on receptacle ?r
    (in-receptacle ?i - food ?r - receptacle)
    ; Whether item ?i is in or on appliance ?a
    (in-appliance ?i - item ?a - appliance)
    ; Whether appliance ?a is occupied
    (occupied ?a - appliance)

    ; Whether food item ?f is prepared
    (is-prepared ?f - food)
    ; Whether food item ?f was prepared using method ?m
    (prepared ?m - prepare-method ?f - food)

    ; Whether food item ?f is combined
    (is-combined ?f - food)
    ; Whether food item ?f was combined using method ?m
    (combined ?m - combine-method ?f - food)
    ; Whether food items ?f1 and ?f2 were combined together using method ?m
    (combined-with ?m - combine-method ?f1 ?f2 - food)

    ; Whether food item ?f is cooked
    (is-cooked ?f - food)
    ; Whether food item ?f was cooked using method ?m
    (cooked ?m - cook-method ?f - food)
    ; Whether food items ?f1 and ?f2 were cooked together using method ?m
    (cooked-with ?m - cook-method ?f1 ?f2 - food)

    ; Whether receptacle ?r has been served
    (served ?r - receptacle)
  )

  ;; ACTIONS ;;
  ; Move from location ?l1 to location ?l2
  (:action move
   :parameters (?l1 ?l2 - location)
   :precondition (and (agent-at-loc ?l1) (not (= ?l1 ?l2)))
   :effect (and (agent-at-loc ?l2) (not (agent-at-loc ?l1)))
  )

  ; Pick up item ?i at location ?l
  (:action pick-up
   :parameters (?i - item ?l - location)
   :precondition (and (handempty) (agent-at-loc ?l) (object-at-loc ?i ?l))
   :effect (and (holding ?i) (not (object-at-loc ?i ?l)) (not (handempty))
                (forall (?a - appliance)
                        (when (object-at-loc ?a ?l)
                              (and (not (occupied ?a))
                                   (not (in-appliance ?i ?a))))))
  )

  ; Put down item ?i at location ?l
  (:action put-down
   :parameters (?i - item ?l - location)
   :precondition (and (agent-at-loc ?l) (holding ?i)
                      (forall (?a - appliance)
                              (imply (object-at-loc ?a ?l) (not (occupied ?a)))))
   :effect (and (handempty) (object-at-loc ?i ?l) (not (holding ?i))
                (forall (?a - appliance)
                        (when (object-at-loc ?a ?l)
                              (and (occupied ?a) (in-appliance ?i ?a)))))
  )

  ; Take out food item ?i in receptacle ?r at location ?l
  (:action take-out
   :parameters (?i - food ?r - receptacle ?l - location)
   :precondition (and (handempty) (in-receptacle ?i ?r)
                      (agent-at-loc ?l) (object-at-loc ?r ?l)
                      (not (is-combined ?i)) (not (is-cooked ?i)))
   :effect (and (holding ?i) (not (in-receptacle ?i ?r)) (not (handempty)))
  )

  ; Place food item ?i in receptacle ?r at location ?l
  (:action place-in
   :parameters (?i - food ?r - receptacle ?l - location)
   :precondition (and (holding ?i) (agent-at-loc ?l) (object-at-loc ?r ?l))
   :effect (and (handempty) (in-receptacle ?i ?r) (not (holding ?i)))
  )

  ; Transfer all items in held receptacle ?src to receptacle ?dst at location ?l
  (:action transfer
   :parameters (?src ?dst - receptacle ?l - location)
   :precondition (and (holding ?src) (agent-at-loc ?l) (object-at-loc ?dst ?l)
                      (not (= ?src ?dst)))
   :effect (forall (?i - food)
                   (when (in-receptacle ?i ?src)
                         (and (in-receptacle ?i ?dst)
                              (not (in-receptacle ?i ?src)))))
  )

  ; Prepare a piece of food ?f in receptacle ?r using tool ?t via method ?m
  (:action prepare
   :parameters (?m - prepare-method ?r - receptacle ?t - tool
                ?f - food ?l - location)
   :precondition (and (holding ?t) (in-receptacle ?f ?r)
                      (agent-at-loc ?l) (object-at-loc ?r ?l)
                      (not (is-prepared ?f)) (not (is-combined ?f))
                      (not (is-cooked ?f))
                      (exists (?rt - rtype ?tt - ttype)
                              (and (receptacle-type ?rt ?r)
                                   (tool-type ?tt ?t)
                                   (has-prepare-method ?m ?rt ?tt))))
   :effect (and (is-prepared ?f) (prepared ?m ?f))
  )

  ; Combine ingredients in receptacle ?r using appliance ?a via method ?m
  (:action combine
   :parameters (?m - combine-method ?r - receptacle ?a - appliance ?l - location)
   :precondition (and (in-appliance ?r ?a)
                      (agent-at-loc ?l) (object-at-loc ?a ?l)
                      (exists (?rt - rtype ?at - atype)
                              (and (receptacle-type ?rt ?r)
                                   (appliance-type ?at ?a)
                                   (has-combine-method ?m ?rt ?at)))
                      (forall (?f - food)
                              (imply (in-receptacle ?f ?r)
                                     (and (not (is-combined ?f))
                                           (not (is-cooked ?f))))))
   :effect (forall (?f - food)
                    (when (in-receptacle ?f ?r)
                          (and (is-combined ?f) (combined ?m ?f)
                              (forall (?f2 - food)
                                      (when (and (in-receptacle ?f2 ?r)
                                                 (not (= ?f ?f2)))
                                            (combined-with ?m ?f ?f2))))))
  )

  ; Cook ingredients in receptacle ?r using appliance ?a via method ?m
  (:action cook
   :parameters (?m - cook-method ?r - receptacle ?a - appliance ?l - location)
   :precondition (and (in-appliance ?r ?a)
                      (agent-at-loc ?l) (object-at-loc ?a ?l)
                      (exists (?rt - rtype ?at - atype)
                              (and (receptacle-type ?rt ?r)
                                   (appliance-type ?at ?a)
                                   (has-cook-method ?m ?rt ?at)))
                      (forall (?f - food)
                              (imply (in-receptacle ?f ?r)
                                     (not (is-cooked ?f)))))
   :effect (forall (?f - food)
                    (when (in-receptacle ?f ?r)
                          (and (is-cooked ?f) (cooked ?m ?f)
                               (forall (?f2 - food)
                                       (when (and (in-receptacle ?f2 ?r)
                                                  (not (= ?f ?f2)))
                                             (cooked-with ?m ?f ?f2))))))
  )

  ; Serve receptacle ?r
  (:action serve
   :parameters (?r - receptacle ?l - location)
   :precondition (and (agent-at-loc ?l) (object-at-loc ?r ?l)
                      (not (served ?r)))
   :effect (served ?r)
  )

  ;; END ACTIONS ;;
)
