(define (domain build-a-meal)
  (:requirements :adl :typing :equality)
  (:types
    food - item ; Objects that can be held and moved
    prepare-method cook-method - method ; Methods for cooking, etc
  )
  (:predicates
    ;; Static predicates

    ; Whether a type of food $f can be prepared via method ?m
    (has-prepare-method ?m - prepare-method ?f -food )
    ; Whether a type of food $f can be cooked via method ?m
    (has-cook-method ?m - cook-method ?f -food )

    ;; Dynamic predicates

    ; Whether food item ?i has been selected by the user
    (selected ?i - food)

    ; Whether food item ?f is prepared
    (is-prepared ?f - food)
    ; Whether food item ?f was prepared using method ?m
    (prepared ?m - prepare-method ?f - food)

    ; Whether food item ?f is cooked
    (is-cooked ?f - food)
    ; Whether food item ?f was cooked using method ?m
    (cooked ?m - cook-method ?f - food)
  )

  ;; ACTIONS ;;

  ; Select item ?i
  (:action select
   :parameters (?i - item)
   :precondition (not (selected ?i))
   :effect (selected ?i)
  )

  ; Unselect item ?i
  (:action unselect
   :parameters (?i - item)
   :precondition (selected ?i)
   :effect (not (selected ?i))
  )

  ; Prepare a piece of food ?f via method ?m
  (:action prepare
   :parameters (?m - prepare-method ?f - food)
   :precondition (and (has-prepare-method ?m ?f) (not (is-prepared ?f)))
   :effect (and (is-prepared ?f) (prepared ?m ?f))
  )

  ; Unprepare a piece of food ?f currently prepared with method ?m
  (:action unprepare
   :parameters (?m - prepare-method ?f - food)
   :precondition (and (has-prepare-method ?m ?f)
                      (is-prepared ?f) (prepared ?m ?f))
   :effect (and (not (is-prepared ?f)) (not (prepared ?m ?f)))
  )

  ; Cook a piece of food ?f via method ?m
  (:action cook
   :parameters (?m - cook-method ?f - food)
   :precondition (and (has-cook-method ?m ?f) (not (is-cooked ?f)))
   :effect (and (is-cooked ?f) (cooked ?m ?f))
  )

  ; Uncook a piece of food ?f currently cooked with method ?m
  (:action uncook
   :parameters (?m - cook-method ?f - food)
   :precondition (and (has-cook-method ?m ?f)
                      (is-cooked ?f) (cooked ?m ?f))
   :effect (and (not (is-cooked ?f)) (not (cooked ?m ?f)))
  )

  ;; END ACTIONS ;;
)
