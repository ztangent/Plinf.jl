; Salad bar with tomato and lettuce salad as goal
(define (problem overcooked-problem-1-3)
	(:domain overcooked)
	(:objects
		tomato olive feta-cheese cucumber onion - ftype ; Food types
		chopping-board plate - rtype ; Receptacle types
		knife glove - ttype ; Tool types
		slice crumble chop - prepare-method ; Preparation methods
		tomato1 olive1 feta-cheese1 cucumber1 onion1 - food ; Food objects
		board1 plate1 - receptacle ; Receptacle objects
		knife1 glove1 - tool ; Tool objects
		start-loc food-loc chop-loc plate-loc - location ; Locations
	)
	(:init
		; Type declarations
		(food-type tomato tomato1)
		(food-type cucumber cucumber1)
		(food-type onion onion1)
		(food-type feta-cheese feta-cheese1)
		(food-type olive olive1)
		(receptacle-type chopping-board board1)
		(receptacle-type plate plate1)
		(tool-type knife knife1)
		(tool-type glove glove1)
		; Method declarations
		(has-prepare-method slice chopping-board knife)
		(has-prepare-method crumble chopping-board glove)
		(has-prepare-method chop chopping-board knife)
		; Initial agent state
		(handempty)
		(agent-at-loc start-loc)
		; Initial food locations
		(object-at-loc tomato1 food-loc)
		(object-at-loc onion1 food-loc)
		(object-at-loc cucumber1 food-loc)
		(object-at-loc olive1 food-loc)
		(object-at-loc feta-cheese1 food-loc)
		; Initial receptacle and tool locations
		(object-at-loc board1 chop-loc)
		(object-at-loc knife1 chop-loc)
		(object-at-loc glove1 chop-loc)
		(object-at-loc plate1 plate-loc)
	)
	(:goal
		(exists (?lettuce - food ?onion - food ?tomato - food ?cucumber - food ?olive - food ?feta-cheese - food ?knife - tool ?glove - tool ?plate - receptacle)
		        (and (food-type olive ?olive)
					 (food-type tomato ?tomato)
                     (food-type cucumber ?cucumber)
					 (food-type onion ?onion)
					 (food-type feta-cheese ?feta-cheese)
					 (receptacle-type plate ?plate)
		             (prepared chop ?olive)
					 (prepared chop ?tomato)
					 (prepared chop ?cucumber)
					 (prepared chop ?onion)
					 (prepared crumble ?feta-cheese)
		             (in-receptacle ?lettuce ?plate)
					 (in-receptacle ?olive ?plate)
					 (in-receptacle ?feta-cheese ?plate)
					 (in-receptacle ?cucumber ?plate)
					 (in-receptacle ?onion ?plate)
					 (in-receptacle ?tomato ?plate)))
	)
)
