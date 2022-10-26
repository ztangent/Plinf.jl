; Delicatessen/Burger Joint with cheeseburgers as a goal
(define (problem overcooked-problem-3)
	(:domain overcooked)
	(:objects
		bread cheese tuna beef chicken onion potato lettuce tomato pineapple mayo - ftype ; Food types
		chopping-board basket pan plate mixing-bowl - rtype ; Receptacle types
		knife spoon - ttype ; Tool types
		stove deep-fryer - atype ; Appliance types
		slice chop mince mix - prepare-method ; Preparation methods
		grill fry - cook-method ; Cooking methods
		bread1 cheese1 tuna1 beef1 chicken1 onion1 potato1 lettuce1 tomato1 pineapple1 mayo1 - food ; Food objects
	    board1 basket1 pan1 plate1 bowl1 - receptacle ; Receptacle objects
		knife1 spoon1 - tool ; Tool objects
		stove1 fryer1 - appliance ; Appliance objects
		start-loc food-loc chop-loc fryer-loc stove-loc plate-loc - location ; Locations
	)
	(:init
		; Type declarations
		(food-type bread bread1)
		(food-type beef beef1)
		(food-type tuna tuna1)
		(food-type cheese cheese1)
		(food-type onion onion1)
		(food-type potato potato1)
		(food-type chicken chicken1)
		(food-type lettuce lettuce1)
		(food-type tomato tomato1)
		(food-type pineapple pineapple1)
		(food-type mayo mayo1)
		(receptacle-type chopping-board board1)
		(receptacle-type plate plate1)
		(receptacle-type mixing-bowl bowl1)
		(receptacle-type pan pan1)
		(tool-type knife knife1)
		(appliance-type stove stove1)
		(appliance-type deep-fryer fryer1)
		; Method declarations
		(has-prepare-method slice chopping-board knife)
		(has-prepare-method mince chopping-board knife)
		(has-prepare-method chop chopping-board knife)
		(has-cook-method grill pan stove)
		(has-cook-method fry pan stove)
		(has-cook-method fry basket deep-fryer)
		(has-combine-method mix mixing-bowl spoon)
		; Initial agent state
		(handempty)
		(agent-at-loc start-loc)
		; Initial food locations
		(object-at-loc bread1 food-loc)
		(object-at-loc tuna1 food-loc)
		(object-at-loc cheese1 food-loc)
		(object-at-loc beef1 food-loc)
		(object-at-loc onion1 food-loc)
		(object-at-loc potato1 food-loc)
		(object-at-loc chicken1 food-loc)
		(object-at-loc lettuce1 food-loc)
		(object-at-loc tomato1 food-loc)
		(object-at-loc pineapple1 food-loc)
		(object-at-loc mayo1 food-loc)
		; Receptacle, tool, and appliance locations
		(object-at-loc board1 chop-loc)
		(object-at-loc knife1 chop-loc)
		(object-at-loc pan1 stove-loc)
		(object-at-loc stove1 stove-loc)
		(object-at-loc plate1 plate-loc)
		(object-at-loc fryer1 fryer-loc)
		; Whether receptacles are located on appliances
		(in-appliance pan1 stove1)
		(occupied stove1)
	)
	(:goal
(exists (?bread - food ?tuna - food ?cheese - food ?lettuce - food ?tomato - food ?mayo - food ?plate - receptacle ?mixing-bowl - receptacle)
        (and (food-type tuna ?tuna)
             (food-type bread ?bread)
             (food-type cheese ?cheese)
			 (food-type lettuce ?lettuce)
             (food-type bread ?tomato)
             (food-type cheese ?mayo)
			 (receptacle-type plate ?plate)
             (combined-with ?tuna ?mayo)
             (prepared slice ?cheese)
			 (prepared slice ?tomato)
			 (prepared slice ?lettuce)
             (in-receptacle ?bread ?plate)
             (in-receptacle ?tuna ?plate)
			 (in-receptacle ?lettuce ?plate)
             (in-receptacle ?tomato ?plate)
			 (in-receptacle ?mayo ?plate)
             (in-receptacle ?cheese ?plate)))
	)
)
