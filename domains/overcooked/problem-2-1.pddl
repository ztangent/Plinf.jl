; Sushi bar with fish sushi as a goal
(define (problem overcooked-problem-2)
	(:domain overcooked)
	(:objects
		fish rice nori cucumber - ftype ; Food types
		chopping-board pot plate - rtype ; Receptacle types
		knife - ttype ; Tool types
		stove - atype ; Appliance types
		slice - prepare-method ; Preparation methods
		boil - cook-method ; Cooking methods
		fish1 rice1 nori1 cucumber1 - food ; Food objects
		board1 pot1 plate1 - receptacle ; Receptacle objects
		knife1 - tool ; Tool objects
		stove1 - appliance ; Appliance objects
		start-loc food-loc chop-loc stove-loc plate-loc - location ; Locations
	)
	(:init
		; Type declarations
		(food-type fish fish1)
		(food-type rice rice1)
		(food-type nori nori1)
		(food-type cucumber cucumber1)
		(receptacle-type chopping-board board1)
		(receptacle-type pot pot1)
		(receptacle-type plate plate1)
		(tool-type knife knife1)
		(appliance-type stove stove1)
		; Method declarations
		(has-prepare-method slice chopping-board knife)
		(has-cook-method boil pot stove)
		; Initial agent state
		(handempty)
		(agent-at-loc start-loc)
		; Initial food locations
		(object-at-loc fish1 food-loc)
		(object-at-loc rice1 food-loc)
		(object-at-loc nori1 food-loc)
		(object-at-loc cucumber1 food-loc)
		; Receptacle, tool, and appliance locations
		(object-at-loc board1 chop-loc)
		(object-at-loc knife1 chop-loc)
		(object-at-loc pot1 stove-loc)
		(object-at-loc stove1 stove-loc)
		(object-at-loc plate1 plate-loc)
		; Whether receptacles are located on appliances
		(in-appliance pot1 stove1)
		(occupied stove1)
	)
	(:goal
		(exists (?nori - food ?rice - food ?fish - food ?plate - receptacle)
	   (and (food-type nori ?nori)
	        (food-type rice ?rice)
	        (food-type fish ?fish)
					(receptacle-type plate ?plate)
	        (prepared slice ?fish)
	        (cooked boil ?rice)
	        (in-receptacle ?nori ?plate)
	        (in-receptacle ?rice ?plate)
	        (in-receptacle ?fish ?plate)))
	)
)
