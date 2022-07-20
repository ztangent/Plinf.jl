;Patisserie/Bakery with honey cakes and donuts as a goal
(define (problem overcooked-problem-5)
	(:domain overcooked)
	(:objects
		egg honey flour chocolate - ftype ; Food types
		mixing-bowl plate - rtype ; Receptacle types
		mixer oven deep-fryer - atype ; Appliance types
		mix - prepare-method ; Preparation methods
		bake deep-fry - cook-method ; Cooking methods
		egg1 honey1 flour1 chocolate1 - food ; Food objects
		mixing-bowl1 plate1 - receptacle ; Receptacle objects
		mixer1 oven1 fryer1 - appliance ; Appliance objects
		start-loc food-loc mix-loc oven-loc fryer-loc plate-loc - location ; Locations
	)
	(:init
		; Type declarations
		(food-type honey honey1)
		(food-type flour flour1)
		(food-type egg egg1)
		(food-type chocolate chocolate1)
		(receptacle-type mixing-bowl mixing-bowl1)
		(receptacle-type plate plate1)
		(appliance-type oven oven1)
		(appliance-type deep-fryer fryer1)
		(appliance-type mixer mixer1)
		; Method declarations
		(has-combine-method mix mixing-bowl mixer)
		(has-cook-method bake mixing-bowl oven)
		; Initial agent state
		(handempty)
		(agent-at-loc start-loc)
		; Initial food locations
		(object-at-loc honey1 food-loc)
		(object-at-loc flour1 food-loc)
		(object-at-loc egg1 food-loc)
		(object-at-loc chocolate1 food-loc)
		; Receptacle, tool, and appliance locations
		(object-at-loc mixer1 mix-loc)
		(object-at-loc mixing-bowl1 mix-loc)
		(object-at-loc oven1 oven-loc)
		(object-at-loc plate1 plate-loc)
		(object-at-loc fryer1 fryer-loc)
		; Whether receptacles are located on appliances
		(in-appliance mixing-bowl mixer)
		(occupied mixer)
	)
	(:goal
	(exists (?egg - food ?honey - food ?flour - food ?plate - receptacle)
        (and (food-type egg ?egg)
             (food-type flour ?flour)
             (food-type honey ?honey)
             (combined-with mix ?egg ?flour)
             (combined-with mix ?flour ?honey)
             (cooked-with bake ?egg ?flour)
             (cooked-with bake ?flour ?honey)
             (in-receptacle ?egg ?plate)
             (in-receptacle ?honey ?plate)
             (in-receptacle ?flour ?plate)))
	)
)
