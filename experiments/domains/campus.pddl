(define (domain campus)

    (:requirements :strips :typing)
    (:types place)

    (:predicates
        (at ?p - place )
        (banking)
        (lecture-1-taken)
        (lecture-2-taken)
        (lecture-3-taken)
        (lecture-4-taken)
        (group-meeting-1)
        (group-meeting-2)
        (group-meeting-3)
        (coffee)
        (breakfast)
        (lunch)
        (is-bank ?p - place)
        (is-watson-theater ?p - place)
        (is-hayman-theater ?p - place)
        (is-davis-theater ?p - place)
        (is-jones-theater ?p - place)
        (is-bookmark-cafe ?p - place)
        (is-library ?p - place)
        (is-cbs ?p - place)
        (is-psychology-bldg ?p - place)
        (is-angazi-cafe ?p - place)
        (is-tav ?p - place)
    )

    (:action move
        :parameters(?src - place ?dst - place)
        :precondition (and (at ?src ) )
        :effect (and
            (at ?dst)
            (not (at ?src))
        )
    )
    (:action activity-banking
        :parameters (?p - place)
        :precondition (and (at ?p) (is-bank ?p))
        :effect (and
                (banking)
                            )
    )
    (:action activity-take-lecture-1
        :parameters (?p - place)
        :precondition (and (at ?p) (is-watson-theater ?p))
        :effect (and
                (lecture-1-taken)
                            )
    )
    (:action activity-take-lecture-2
        :parameters (?p - place)
        :precondition (and (at ?p) (is-hayman-theater ?p) (breakfast) (lecture-1-taken))
        :effect (and
                (lecture-2-taken)
                            )
    )
    (:action activity-take-lecture-3
        :parameters (?p - place)
        :precondition (and (at ?p) (is-davis-theater ?p) (group-meeting-2) (banking))
        :effect (and
                (lecture-3-taken)
                            )
    )
    (:action activity-take-lecture-4
        :parameters (?p - place)
        :precondition (and (at ?p) (is-jones-theater ?p) (lecture-3-taken))
        :effect (and
                (lecture-4-taken)
                            )
    )
    (:action activity-group-meeting-1-1
        :parameters (?p - place)
        :precondition (and (at ?p) (is-bookmark-cafe ?p) (lecture-1-taken) (breakfast))
        :effect (and
                (group-meeting-1)
                            )
    )
    (:action activity-group-meeting-1-2
        :parameters (?p - place)
        :precondition (and (at ?p) (is-library ?p) (lecture-1-taken) (breakfast))
        :effect (and
                (group-meeting-1)
                            )
    )
    (:action activity-group-meeting-1-3
        :parameters (?p - place)
        :precondition (and (at ?p) (is-cbs ?p) (lecture-1-taken) (breakfast))
        :effect (and
                (group-meeting-1)
                            )
    )
    (:action activity-group-meeting-2-1
        :parameters (?p - place)
        :precondition (and (at ?p) (is-library ?p))
        :effect (and
                (group-meeting-2)
                            )
    )
    (:action activity-group-meeting-2-2
        :parameters (?p - place)
        :precondition (and (at ?p) (is-cbs ?p))
        :effect (and
                (group-meeting-2)
                            )
    )
    (:action activity-group-meeting-2-3
        :parameters (?p - place)
        :precondition (and (at ?p) (is-psychology-bldg ?p))
        :effect (and
                (group-meeting-2)
                            )
    )
    (:action activity-group-meeting-3-1
        :parameters (?p - place)
        :precondition (and (at ?p) (is-angazi-cafe ?p) (lecture-4-taken))
        :effect (and
                (group-meeting-3)
                            )
    )
    (:action activity-group-meeting-3-2
        :parameters (?p - place)
        :precondition (and (at ?p) (is-psychology-bldg ?p) (lecture-4-taken))
        :effect (and
                (group-meeting-3)
                            )
    )
    (:action activity-coffee-1
        :parameters (?p - place)
        :precondition (and (at ?p) (is-tav ?p) (lecture-2-taken) (group-meeting-1))
        :effect (and
                (coffee)
                            )
    )
    (:action activity-coffee-2
        :parameters (?p - place)
        :precondition (and (at ?p) (is-angazi-cafe ?p) (lecture-2-taken) (group-meeting-1))
        :effect (and
                (coffee)
                            )
    )
    (:action activity-coffee-3
        :parameters (?p - place)
        :precondition (and (at ?p) (is-bookmark-cafe ?p) (lecture-2-taken) (group-meeting-1))
        :effect (and
                (coffee)
                            )
    )
    (:action activity-breakfast-1
        :parameters (?p - place)
        :precondition (and (at ?p) (is-tav ?p))
        :effect (and
                (breakfast)
                            )
    )
    (:action activity-breakfast-2
        :parameters (?p - place)
        :precondition (and (at ?p) (is-angazi-cafe ?p))
        :effect (and
                (breakfast)
                            )
    )
    (:action activity-breakfast-3
        :parameters (?p - place)
        :precondition (and (at ?p) (is-bookmark-cafe ?p))
        :effect (and
                (breakfast)
                            )
    )
    (:action activity-lunch-1
        :parameters (?p - place)
        :precondition (and (at ?p) (is-tav ?p))
        :effect (and
                (lunch)
                            )
    )
    (:action activity-lunch-2
        :parameters (?p - place)
        :precondition (and (at ?p) (is-bookmark-cafe ?p))
        :effect (and
                (lunch)
                            )
    )
)
