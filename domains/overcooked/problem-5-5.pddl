;Patisserie/Bakery with honey cakes and donuts as a goal
(define (problem overcooked-problem-5)
	(:domain overcooked)
	(:objects
		egg honey flour chocolate strawberry watermelon grape apple ice milk - ftype ; Food types
		blender-jug glass basket - rtype ; Receptacle types
		blender oven deep-fryer - atype ; Appliance types
		blend - combine-method ; Preparation methods
		bake deep-fry - cook-method ; Cooking methods
		egg1 honey1 flour1 chocolate1 strawberry1 watermelon1 grape1 apple1 ice1 milk1 - food ; Food objects
		blender-jug1 glass1 basket1 - receptacle ; Receptacle objects
		blender1 oven1 fryer1 - appliance ; Appliance objects
		start-loc food-loc blend-loc oven-loc fryer-loc glass-loc - location ; Locations
	)
	(:init
		; Type declarations
		(food-type honey honey1)
		(food-type flour flour1)
		(food-type ice ice1)
		(food-type egg egg1)
		(food-type chocolate chocolate1)
		(food-type strawberry strawberry1)
		(food-type watermelon watermelon1)
		(food-type grape grape1)
		(food-type apple apple1)
		(food-type milk milk1)
		(receptacle-type blender-jug blender-jug1)
		(receptacle-type glass glass1)
		(receptacle-type basket basket1)
		(appliance-type oven oven1)
		(appliance-type deep-fryer fryer1)
		(appliance-type blender blender1)
		; Method declarations
		(has-combine-method blend blender-jug blender)
		(has-cook-method deep-fry basket deep-fryer)
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
		(object-at-loc blender1 blend-loc)
		(object-at-loc blender-jug1 blend-loc)
		(object-at-loc basket1 fryer-loc)
		(object-at-loc oven1 oven-loc)
		(object-at-loc glass1 glass-loc)
		(object-at-loc fryer1 fryer-loc)
		; Whether receptacles are located on appliances
		(in-appliance blender-jug1 blender1)
		(in-appliance basket1 fryer1)
		(occupied blender1)
		(occupied fryer1)
	)
	(:goal
	(exists (?ice - food ?chocolate - food ?milk - food ?glass - receptacle)
        (and (food-type ice ?ice)
             (food-type milk ?milk)
             (food-type chocolate ?chocolate)
			 (receptacle-type glass ?glass)
             (combined-with blend ?ice ?milk)
             (combined-with blend ?milk ?chocolate)
             (in-receptacle ?ice ?glass)
             (in-receptacle ?chocolate ?glass)
             (in-receptacle ?milk ?glass)))
	)
)
