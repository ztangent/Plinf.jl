(define (domain kitchen)
	(:requirements :strips :typing :action-costs)
	(:types objects useable)
	(:constants
		water_jug kettle cloth tea_bag cup sugar bowl milk
		cereal creamer cup sugar coffee bread cheese plate
		bread toaster butter knife peanut_butter spoon
		pill_box juice popcorn dressing salad_tosser
		lunch_bag - object
		microwave phone toaster plants - useable )
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
	)
	(:functions
		(total-cost)
	)
	(:action take
		:parameters (?obj - object )
		:precondition (and (dummy) )
		:effect ( and
				(taken ?obj)
				(increase (total-cost) 1)
			)
	)
	(:action use
		:parameters (?obj - useable )
		:precondition (and (dummy) )
		:effect (and
				(used ?obj)
				(increase (total-cost) 1)
			)
	)
	(:action activity-boil-water
		:parameters ()
		:precondition 	(and
					(taken water_jug)
					(taken kettle)
					(taken cloth)
				)
		:effect		(and
					(water_boiled)
					(increase (total-cost) 1)
				)
	)
	(:action activity-make-tea-1
		:parameters ()
		:precondition	(and
					(taken tea_bag)
					(taken cup)
					(taken sugar)
					(water_boiled)
				)
		:effect		(and
					(made_tea)
					(increase (total-cost) 1)
				)
	)
	(:action activity-make-tea-2
		:parameters ()
		:precondition	(and
					(taken tea_bag)
					(taken cup)
					(taken sugar)
					(taken milk)
					(water_boiled)
				)
		:effect		(and
					(made_tea)
					(increase (total-cost) 1)
				)
	)
	(:action activity-make-tea-3
		:parameters ()
		:precondition	(and
					(taken tea_bag)
					(taken cup)
					(water_boiled)
				)
		:effect		(and
					(made_tea)
					(increase (total-cost) 1)
				)
	)
	(:action activity-make-cereals
		:parameters ()
		:precondition	(and
					(taken bowl)
					(taken cereal)
					(taken milk)
				)
		:effect		(and
					(made_cereals)
					(increase (total-cost) 1)
				)
	)
	(:action activity-make-coffee-1
		:parameters ()
		:precondition	(and
					(taken cup)
					(taken coffee)
					(taken creamer)
					(taken sugar)
					(water_boiled)
				)
		:effect		(and
					(made_coffee)
					(increase (total-cost) 1)
				)
	)
	(:action activity-make-coffee-2
		:parameters ()
		:precondition	(and
					(taken cup)
					(taken coffee)
					(taken milk)
					(taken sugar)
					(water_boiled)
				)
		:effect		(and
					(made_coffee)
					(increase (total-cost) 1)
				)
	)
	(:action activity-make-cheese-sandwich
		:parameters ()
		:precondition	(and
					(taken bread)
					(taken cheese)
					(taken plate)
				)
		:effect		(and
					(made_cheese_sandwich)
					(increase (total-cost) 1)
				)
	)
	(:action activity-make-toast
		:parameters ()
		:precondition	(and
					(taken bread)
					(used toaster)
				)
		:effect		(and
					(made_toast)
					(increase (total-cost) 1)
				)
	)
	(:action activity-make-buttered-toast
		:parameters ()
		:precondition	(and
					(made_toast)
					(taken butter)
					(taken knife)
				)
		:effect		(and
					(made_buttered_toast)
					(increase (total-cost) 1)
				)
	)
	(:action activity-make-peanut-butter-sandwich
		:parameters ()
		:precondition	(and
					(taken bread)
					(taken peanut_butter)
					(taken knife)
					(taken plate)
				)
		:effect		(and
					(made_peanut_butter_sandwich)
					(increase (total-cost) 1)
				)
	)
	(:action activity-pack-lunch-1
		:parameters ()
		:precondition	(and
					(taken lunch_bag)
					(made_cheese_sandwich)
				)
		:effect		(and
					(lunch_packed)
					(increase (total-cost) 1)
				)
	)
	(:action activity-pack-lunch-2
		:parameters ()
		:precondition	(and
					(taken lunch_bag)
					(made_peanut_butter_sandwich)
				)
		:effect		(and
					(lunch_packed)
					(increase (total-cost) 1)
				)
	)
	(:action activity-make-breakfast-1
		:parameters ()
		:precondition	(and
					(made_tea)
					(taken spoon)
					(made_cereals)
					(made_buttered_toast)
				)
		:effect		(and
					(made_breakfast)
					(increase (total-cost) 1)
				)
	)
	(:action activity-make-breakfast-2
		:parameters ()
		:precondition	(and
					(made_coffee)
					(taken spoon)
					(made_cereals)
					(made_buttered_toast)
				)
		:effect		(and
					(made_breakfast)
					(increase (total-cost) 1)
				)
	)
	(:action activity-make-salad-1
		:parameters ()
		:precondition	(and
					(taken bowl)
					(taken plate)
					(taken dressing)
					(taken salad_tosser)
				)
		:effect		(and
					(made_salad)
					(increase (total-cost) 1)
				)
	)
	(:action activity-make-salad-2
		:parameters ()
		:precondition	(and
					(taken bowl)
					(taken plate)
					(taken salad_tosser)
				)
		:effect		(and
					(made_salad)
					(increase (total-cost) 1)
				)
	)
	(:action activity-make-dinner-1
		:parameters ()
		:precondition	(and
					(made_salad)
				)
		:effect		(and
					(made_dinner)
					(increase (total-cost) 1)
				)
	)
	(:action activity-make-dinner-2
		:parameters ()
		:precondition	(and
					(made_cheese_sandwich)
				)
		:effect		(and
					(made_dinner)
					(increase (total-cost) 1)
				)
	)
	(:action activity-make-dinner-3
		:parameters ()
		:precondition	(and
					(made_salad)
					(made_cheese_sandwich)
				)
		:effect		(and
					(made_dinner)
					(increase (total-cost) 1)
				)
	)
	(:action activity-take-medicine
		:parameters ()
		:precondition	(and
					(taken pill_box)
				)
		:effect		(and
					(taken_medicine)
					(increase (total-cost) 1)
				)
	)
	(:action activity-watch-movie
		:parameters ()
		:precondition	(and
					(taken popcorn)
					(used microwave)
				)
		:effect		(and
					(watching_movie)
					(increase (total-cost) 1)
				)
	)
	(:action activity-wipe-counter
		:parameters ()
		:precondition	(and
					(taken cloth)
				)
		:effect		(and
					(counter_wiped)
					(increase (total-cost) 1)
				)
	)
	(:action activity-tend-plants
		:parameters ()
		:precondition	(and
					(taken water_jug)
					(used plants)
				)
		:effect		(and
					(plants_tended)
					(increase (total-cost) 1)
				)
	)
	(:action activity-drink-juice
		:parameters ()
		:precondition	(and
					(taken juice)
					(taken cup)
				)
		:effect		(and
					(drank_juice)
					(increase (total-cost) 1)
				)
	)
	(:action activity-leave-for-work
		:parameters ()
		:precondition	(and
					(made_breakfast)
					(lunch_packed)
					(plants_tended)
				)
		:effect		(and
					(leaving_for_work)
					(increase (total-cost) 1)
				)
	)
	(:action activity-go-to-bed
		:parameters ()
		:precondition	(and
					(made_dinner)
					(taken_medicine)
				)
		:effect		(and
					(going_to_bed)
					(increase (total-cost) 1)
				)
	)
)
