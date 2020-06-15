(define (domain campus)

	(:requirements :strips :typing :action-costs)
	(:types place)

	(:constants
		bank watson_theater hayman_theater davis_theater jones_theater
		bookmark_cafe library cbs psychology_bldg angazi_cafe tav - place
	)
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
	)

	(:functions
		(total-cost) - number
	)
	(:action move
		:parameters(?src - place ?dst - place)
		:precondition (and (at ?src ) )
		:effect ( and
				(at ?dst)
				(increase (total-cost) 1)
				(not (at ?src))
			)
	)
	(:action activity-banking
		:parameters()
		:precondition (and (at bank))
		:effect (and
				(banking)
				(increase (total-cost) 1)
			)
	)
	(:action activity-take-lecture-1
		:parameters()
		:precondition (and (at watson_theater))
		:effect (and
				(lecture-1-taken)
				(increase (total-cost) 1)
			)
	)
	(:action activity-take-lecture-2
		:parameters()
		:precondition (and (at hayman_theater) (breakfast) (lecture-1-taken))
		:effect (and
				(lecture-2-taken)
				(increase (total-cost) 1)
			)
	)
	(:action activity-take-lecture-3
		:parameters()
		:precondition (and (at davis_theater) (group-meeting-2) (banking))
		:effect	(and
				(lecture-3-taken)
				(increase (total-cost) 1)
			)
	)
	(:action activity-take-lecture-4
		:parameters()
		:precondition (and (at jones_theater) (lecture-3-taken))
		:effect (and
				(lecture-4-taken)
				(increase (total-cost) 1)
			)
	)
	(:action activity-group-meeting-1
		:parameters()
		:precondition (and (at bookmark_cafe) (lecture-1-taken) (breakfast))
		:effect (and
				(group-meeting-1)
				(increase (total-cost) 1)
			)
	)
	(:action activity-group-meeting-1
		:parameters()
		:precondition (and (at library) (lecture-1-taken) (breakfast))
		:effect (and
				(group-meeting-1)
				(increase (total-cost) 1)
			)
	)
	(:action activity-group-meeting-1
		:parameters()
		:precondition (and (at cbs) (lecture-1-taken) (breakfast))
		:effect (and
				(group-meeting-1)
				(increase (total-cost) 1)
			)
	)
	(:action activity-group-meeting-2
		:parameters()
		:precondition (and (at library))
		:effect (and
				(group-meeting-2)
				(increase (total-cost) 1)
			)
	)
	(:action activity-group-meeting-2
		:parameters()
		:precondition (and (at cbs))
		:effect (and
				(group-meeting-2)
				(increase (total-cost) 1)
			)
	)
	(:action activity-group-meeting-2
		:parameters()
		:precondition (and (at psychology_bldg))
		:effect (and
				(group-meeting-2)
				(increase (total-cost) 1)
			)
	)
	(:action activity-group-meeting-3
		:parameters()
		:precondition (and (at angazi_cafe) (lecture-4-taken))
		:effect (and
				(group-meeting-3)
				(increase (total-cost) 1)
			)
	)
	(:action activity-group-meeting-3
		:parameters()
		:precondition (and (at psychology_bldg) (lecture-4-taken))
		:effect (and
				(group-meeting-3)
				(increase (total-cost) 1)
			)
	)
	(:action activity-coffee
		:parameters()
		:precondition (and (at tav) (lecture-2-taken) (group-meeting-1))
		:effect (and
				(coffee)
				(increase (total-cost) 1)
			)
	)
	(:action activity-coffee
		:parameters ()
		:precondition (and (at angazi_cafe) (lecture-2-taken) (group-meeting-1))
		:effect (and
				(coffee)
				(increase (total-cost) 1)
			)
	)
	(:action activity-coffee
		:parameters ()
		:precondition (and (at bookmark_cafe) (lecture-2-taken) (group-meeting-1))
		:effect (and
				(coffee)
				(increase (total-cost) 1)
			)
	)
	(:action activity-breakfast
		:parameters()
		:precondition (and (at tav))
		:effect (and
				(breakfast)
				(increase (total-cost) 1)
			)
	)
	(:action activity-breakfast
		:parameters ()
		:precondition (and (at angazi_cafe))
		:effect (and
				(breakfast)
				(increase (total-cost) 1)
			)
	)
	(:action activity-breakfast
		:parameters ()
		:precondition (and (at bookmark_cafe))
		:effect (and
				(breakfast)
				(increase (total-cost) 1)
			)
	)
	(:action activity-lunch
		:parameters ()
		:precondition (and (at tav))
		:effect (and
				(lunch)
				(increase (total-cost) 1)
			)
	)
	(:action activity-lunch
		:parameters ()
		:precondition (and (at bookmark_cafe))
		:effect (and
				(lunch)
				(increase (total-cost) 1)
			)
	)
)
