; Salad bar
(define (problem build-a-meal-problem-1-1)
    (:domain build-a-meal)
    (:objects
        lettuce cucumber - food ; Food types
        slice chop - prepare-method ; Preparation methods
    )
    (:init
        ; Method declarations
        (has-prepare-method slice lettuce)
        (has-prepare-method chop lettuce)
        ; Initial preparation states
        (prepared slice lettuce)
    )
    (:goal
        (and (prepared slice lettuce)
             (selected lettuce))
    )
)
