;Patisserie/Bakery with honey cakes and donuts as a goal
(define (problem overcooked-problem-5)
	(:domain overcooked)
	(:objects
		egg honey flour chocolate strawberry watermelon grape apple - ftype ; Food types
		chopping-board mixing-bowl plate basket - rtype ; Receptacle types
		mixer oven deep-fryer - atype ; Appliance types
		knife - ttype ; Tool types
		mix - combine-method ; Combine methods
		slice - prepare-method ; Preparation methods
		bake deep-fry - cook-method ; Cooking methods
		egg1 honey1 flour1 chocolate1 strawberry1 watermelon1 grape1 apple1 - food ; Food objects
	    board1 mixing-bowl1 plate1 basket1 - receptacle ; Receptacle objects
		mixer1 oven1 fryer1 - appliance ; Appliance objects
		knife1 - tool ; Tool objects
		start-loc food-loc mix-loc oven-loc chop-loc fryer-loc plate-loc - location ; Locations
	)
	(:init
		; Type declarations
		(food-type honey honey1)
		(food-type flour flour1)
		(food-type egg egg1)
		(food-type chocolate chocolate1)
		(food-type strawberry strawberry1)
		(food-type watermelon watermelon1)
		(food-type grape grape1)
		(food-type apple apple1)
		(tool-type knife knife1)
		(receptacle-type mixing-bowl mixing-bowl1)
		(receptacle-type plate plate1)
		(receptacle-type basket basket1)
		(receptacle-type chopping-board board1)
		(appliance-type oven oven1)
		(appliance-type deep-fryer fryer1)
		(appliance-type mixer mixer1)
		; Method declarations
		(has-combine-method mix mixing-bowl mixer)
		(has-cook-method bake mixing-bowl oven)
		(has-cook-method deep-fry basket deep-fryer)
		(has-prepare-method slice chopping-board knife)
		; Initial agent state
		(handempty)
		(agent-at-loc start-loc)
		; Initial food locations
		(object-at-loc honey1 food-loc)
		(object-at-loc flour1 food-loc)
		(object-at-loc egg1 food-loc)
		(object-at-loc chocolate1 food-loc)
		(object-at-loc strawberry1 food-loc)
		(object-at-loc watermelon1 food-loc)
		(object-at-loc grape1 food-loc)
		(object-at-loc apple1 food-loc)
		; Receptacle, tool, and appliance locations
		(object-at-loc board1 chop-loc)
		(object-at-loc knife1 chop-loc)
		(object-at-loc mixer1 mix-loc)
		(object-at-loc mixing-bowl1 mix-loc)
		(object-at-loc basket1 fryer-loc)
		(object-at-loc oven1 oven-loc)
		(object-at-loc plate1 plate-loc)
		(object-at-loc fryer1 fryer-loc)
		; Whether receptacles are located on appliances
		(in-appliance mixing-bowl1 mixer1)
		(in-appliance basket1 fryer1)
		(occupied mixer1)
		(occupied fryer1)
	)
	(:goal
	(exists (?egg - food ?apple - food ?flour - food ?plate - receptacle)
        (and (food-type egg ?egg)
             (food-type flour ?flour)
             (food-type apple ?apple)
			 (receptacle-type plate ?plate)
			 (prepared slice ?apple)
             (combined-with mix ?egg ?flour)
             (combined-with mix ?flour ?apple)
             (cooked-with bake ?egg ?flour)
             (cooked-with bake ?flour ?apple)
             (in-receptacle ?egg ?plate)
			 (in-receptacle ?flour ?plate)
             (in-receptacle ?apple ?plate)))
	)
)
