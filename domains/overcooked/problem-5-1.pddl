;Patisserie/Bakery with honey cakes and donuts as a goal
(define (problem overcooked-problem-5)
	(:domain overcooked)
	(:objects
		chocolate strawberry orange peach grape apple - ftype ; Food types
		chopping-board mixing-bowl plate basket - rtype ; Receptacle types
		knife - ttype ; Tool types
		mixer oven deep-fryer - atype ; Appliance types
		mix - combine-method ; Combine methods
		slice - prepare-method ; Preparation methods
		bake deep-fry - cook-method ; Cooking methods
		chocolate1 strawberry1 orange1 peach1  grape1 apple1 - food ; Food objects
		board1 mixing-bowl1 plate1 basket1 - receptacle ; Receptacle objects
		knife1 - tool ; Tool types
		mixer1 oven1 fryer1 - appliance ; Appliance objects
		start-loc food-loc mix-loc oven-loc fryer-loc plate-loc - location ; Locations
	)
	(:init
		; Type declarations
		(food-type chocolate chocolate1)
		(food-type strawberry strawberry1)
		(food-type peach peach1)
		(food-type orange orange1)
		(food-type grape grape1)
		(food-type apple apple1)
		(receptacle-type mixing-bowl mixing-bowl1)
		(receptacle-type plate plate1)
		(receptacle-type basket basket1)
		(appliance-type oven oven1)
		(appliance-type deep-fryer fryer1)
		(appliance-type mixer mixer1)
		; Method declarations
		(has-combine-method mix mixing-bowl mixer)
		(has-prepare-method slice chopping-board knife)
		(has-cook-method bake mixing-bowl oven)
		(has-cook-method deep-fry basket deep-fryer)
		; Initial agent state
		(handempty)
		(agent-at-loc start-loc)
		; Initial food locations
		(object-at-loc chocolate1 food-loc)
		(object-at-loc strawberry1 food-loc)
		(object-at-loc peach1 food-loc)
		(object-at-loc orange1 food-loc)
		(object-at-loc grape1 food-loc)
		(object-at-loc apple1 food-loc)
		; Receptacle, tool, and appliance locations
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
	(exists (?orange - food ?peach - food ?grape - food ?plate - receptacle)
        (and (food-type orange ?orange)
             (food-type peach ?peach)
             (food-type grape ?grape)
			 (receptacle-type plate ?plate)
			 (prepared slice ?orange)
			 (prepared slice ?peach)
			 (prepared slice ?grape)
             (in-receptacle ?orange ?plate)
             (in-receptacle ?peach ?plate)
             (in-receptacle ?grape ?plate)))
	)
)
