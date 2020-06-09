(define (domain kitchen)
    (:requirements :strips :typing)
    (:types object useable)
    (:predicates
        (taken ?o - object)
        (used ?o - useable)
        (water_boiled)
        (made_tea)
        (made_cereals)
        (made_coffee)
        (made_cheese_sandwich)
        (made_toast)
        (made_buttered_toast)
        (made_peanut_butter_sandwich)
        (lunch_packed)
        (made_breakfast)
        (made_salad)
        (made_dinner)
        (taken_medicine)
        (watching_movie)
        (phone_call_tended)
        (counter_wiped)
        (plants_tended)
        (drank_juice)
        (leaving_for_work)
        (going_to_bed)
        (dummy)
        (is-water-jug ?x - object)
        (is-keetle ?x - object)
        (is-cloth ?x - object)
        (is-tea-bag ?x - object)
        (is-cup ?x - object)
        (is-sugar ?x - object)
        (is-bowl ?x - object)
        (is-milk ?x - object)
        (is-cereal ?x - object)
        (is-creamer ?x - object)
        (is-coffee ?x - object)
        (is-bread ?x - object)
        (is-cheese ?x - object)
        (is-plate ?x - object)
        (is-butter ?x - object)
        (is-knife ?x - object)
        (is-peanut-butter ?x - object)
        (is-spoon ?x - object)
        (is-pill-box ?x - object)
        (is-juice ?x - object)
        (is-popcorn ?x - object)
        (is-dressing ?x - object)
        (is-salad-tosser ?x - object)
        (is-lunch-bag ?x - object)
        (is-microwave ?x - useable)
        (is-phone ?x - useable)
        (is-toaster ?x - useable)
        (is-plants ?x - useable)
    )
    (:action take
        :parameters (?obj - object )
        :precondition (and (dummy) )
        :effect (and
                (taken ?obj)
                            )
    )
    (:action use
        :parameters (?obj - useable )
        :precondition (and (dummy) )
        :effect (and
                (used ?obj)
                            )
    )
    (:action activity-boil-water
        :parameters (?x - object ?y - object ?z - object)
        :precondition   (and
                    (taken ?x) (is-water-jug ?x)
                    (taken ?y) (is-keetle ?y)
                    (taken ?z) (is-cloth ?z)
                )
        :effect     (and
                    (water_boiled)
                                    )
    )
    (:action activity-make-tea-1
        :parameters (?x - object ?y - object ?z - object)
        :precondition   (and
                    (taken ?x) (is-tea-bag ?x)
                    (taken ?y) (is-cup ?y)
                    (taken ?z) (is-sugar ?z)
                    (water_boiled)
                )
        :effect     (and
                    (made_tea)
                                    )
    )
    (:action activity-make-tea-2
        :parameters (?w - object ?x - object ?y - object ?z - object)
        :precondition   (and
                    (taken ?w) (is-tea-bag ?w)
                    (taken ?x) (is-cup ?x)
                    (taken ?y) (is-sugar ?y)
                    (taken ?z) (is-milk ?z)
                    (water_boiled)
                )
        :effect     (and
                    (made_tea)
                                    )
    )
    (:action activity-make-tea-3
        :parameters (?x - object ?y - object)
        :precondition   (and
                    (taken ?x) (is-tea-bag ?x)
                    (taken ?y) (is-cup ?y)
                    (water_boiled)
                )
        :effect     (and
                    (made_tea)
                                    )
    )
    (:action activity-make-cereals
        :parameters (?x - object ?y - object ?z - object)
        :precondition   (and
                    (taken ?x) (is-bowl ?x)
                    (taken ?y) (is-cereal ?y)
                    (taken ?z) (is-milk ?z)
                )
        :effect     (and
                    (made_cereals)
                                    )
    )
    (:action activity-make-coffee-1
        :parameters (?w - object ?x - object ?y - object ?z - object)
        :precondition   (and
                    (taken ?x) (is-cup ?x)
                    (taken ?y) (is-coffee ?y)
                    (taken ?z) (is-creamer ?z)
                    (taken ?w) (is-sugar ?w)
                    (water_boiled)
                )
        :effect     (and
                    (made_coffee)
                                    )
    )
    (:action activity-make-coffee-2
        :parameters (?w - object ?x - object ?y - object ?z - object)
        :precondition   (and
                    (taken ?x) (is-cup ?x)
                    (taken ?y) (is-coffee ?y)
                    (taken ?z) (is-milk ?z)
                    (taken ?w) (is-sugar ?w)
                    (water_boiled)
                )
        :effect     (and
                    (made_coffee)
                                    )
    )
    (:action activity-make-cheese-sandwich
        :parameters (?x - object ?y - object ?z - object)
        :precondition   (and
                    (taken ?x) (is-bread ?x)
                    (taken ?y) (is-cheese ?y)
                    (taken ?z) (is-plate ?z)
                )
        :effect     (and
                    (made_cheese_sandwich)
                                    )
    )
    (:action activity-make-toast
        :parameters (?x - object ?y - useable)
        :precondition   (and
                    (taken ?x) (is-bread ?x)
                    (used ?y) (is-toaster ?y)
                )
        :effect     (and
                    (made_toast)
                                    )
    )
    (:action activity-make-buttered-toast
        :parameters (?x - object ?y - object)
        :precondition   (and
                    (made_toast)
                    (taken ?x) (is-butter ?x)
                    (taken ?y) (is-knife ?y)
                )
        :effect     (and
                    (made_buttered_toast)
                                    )
    )
    (:action activity-make-peanut-butter-sandwich
        :parameters (?w - object ?x - object ?y - object ?z - object)
        :precondition   (and
                    (taken ?x) (is-bread ?x)
                    (taken ?y) (is-peanut-butter ?y)
                    (taken ?z) (is-knife ?z)
                    (taken ?w) (is-plate ?w)
                )
        :effect     (and
                    (made_peanut_butter_sandwich)
                                    )
    )
    (:action activity-pack-lunch-1
        :parameters (?x - object)
        :precondition   (and
                    (taken ?x) (is-lunch-bag ?x)
                    (made_cheese_sandwich)
                )
        :effect     (and
                    (lunch_packed)
                                    )
    )
    (:action activity-pack-lunch-2
        :parameters (?x - object)
        :precondition   (and
                    (taken ?x) (is-lunch-bag ?x)
                    (made_peanut_butter_sandwich)
                )
        :effect     (and
                    (lunch_packed)
                                    )
    )
    (:action activity-make-breakfast-1
        :parameters (?x - object)
        :precondition   (and
                    (made_tea)
                    (taken ?x) (is-spoon ?x)
                    (made_cereals)
                    (made_buttered_toast)
                )
        :effect     (and
                    (made_breakfast)
                                    )
    )
    (:action activity-make-breakfast-2
        :parameters (?x - object)
        :precondition   (and
                    (made_coffee)
                    (taken ?x) (is-spoon ?x)
                    (made_cereals)
                    (made_buttered_toast)
                )
        :effect     (and
                    (made_breakfast)
                                    )
    )
    (:action activity-make-salad-1
        :parameters (?w - object ?x - object ?y - object ?z - object)
        :precondition   (and
                    (taken ?x) (is-bowl ?x)
                    (taken ?y) (is-plate ?y)
                    (taken ?z) (is-dressing ?z)
                    (taken ?w) (is-salad-tosser ?w)
                )
        :effect     (and
                    (made_salad)
                                    )
    )
    (:action activity-make-salad-2
        :parameters (?x - object ?y - object ?z - object)
        :precondition   (and
                    (taken ?x) (is-bowl ?x)
                    (taken ?y) (is-plate ?y)
                    (taken ?z) (is-salad-tosser ?z)
                )
        :effect     (and
                    (made_salad)
                                    )
    )
    (:action activity-make-dinner-1
        :parameters ()
        :precondition   (and
                    (made_salad)
                )
        :effect     (and
                    (made_dinner)
                                    )
    )
    (:action activity-make-dinner-2
        :parameters ()
        :precondition   (and
                    (made_cheese_sandwich)
                )
        :effect     (and
                    (made_dinner)
                                    )
    )
    (:action activity-make-dinner-3
        :parameters ()
        :precondition   (and
                    (made_salad)
                    (made_cheese_sandwich)
                )
        :effect     (and
                    (made_dinner)
                                    )
    )
    (:action activity-take-medicine
        :parameters (?x - object)
        :precondition   (and
                    (taken ?x) (is-pill-box ?x)
                )
        :effect     (and
                    (taken_medicine)
                                    )
    )
    (:action activity-watch-movie
        :parameters (?x - object ?y - useable)
        :precondition   (and
                    (taken ?x) (is-popcorn ?x)
                    (used ?y) (is-microwave ?y)
                )
        :effect     (and
                    (watching_movie)
                                    )
    )
    (:action activity-wipe-counter
        :parameters (?x - object)
        :precondition   (and
                    (taken ?x) (is-cloth ?x)
                )
        :effect     (and
                    (counter_wiped)
                                    )
    )
    (:action activity-tend-plants
        :parameters (?x - object ?y - useable)
        :precondition   (and
                    (taken ?x) (is-water-jug ?x)
                    (used ?y) (is-plants ?y)
                )
        :effect     (and
                    (plants_tended)
                                    )
    )
    (:action activity-drink-juice
        :parameters (?x - object ?y - object)
        :precondition   (and
                    (taken ?x) (is-juice ?x)
                    (taken ?y) (is-cup ?y)
                )
        :effect     (and
                    (drank_juice)
                                    )
    )
    (:action activity-leave-for-work
        :parameters ()
        :precondition   (and
                    (made_breakfast)
                    (lunch_packed)
                    (plants_tended)
                )
        :effect     (and
                    (leaving_for_work)
                                    )
    )
    (:action activity-go-to-bed
        :parameters ()
        :precondition   (and
                    (made_dinner)
                    (taken_medicine)
                )
        :effect     (and
                    (going_to_bed)
                                    )
    )
)
