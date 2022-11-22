; Pizzeria with pepperoni pizza as a goal
(define (problem overcooked-problem-4)
	(:domain overcooked)
	(:objects
		egg flour tomato cheese sausage basil olive - ftype ; Food types
		chopping-board mixing-bowl tray plate - rtype ; Receptacle types
		knife - ttype ; Tool types
		mixer oven - atype ; Appliance types
		slice - prepare-method ; Preparation methods
		mix - combine-method ; Combine methods
		bake - cook-method ; Cooking methods
		egg1 flour1 tomato1 cheese1 sausage1 basil1 olive1 - food ; Food objects
		board1 tray1 plate1 mixing-bowl1 - receptacle ; Receptacle objects
		knife1 - tool ; Tool objects
		mixer1 oven1 - appliance ; Appliance objects
		start-loc food-loc mix-loc chop-loc oven-loc tray-loc plate-loc - location ; Locations
	)
	(:init
		; Type declarations
		(food-type egg egg1)
		(food-type flour flour1)
		(food-type tomato tomato1)
		(food-type cheese cheese1)
		(food-type basil basil1)
		(food-type sausage sausage1)
		(food-type olive olive1)
		(receptacle-type mixing-bowl mixing-bowl1)
		(receptacle-type chopping-board board1)
		(receptacle-type plate plate1)
		(receptacle-type tray tray1)
		(tool-type knife knife1)
		(appliance-type oven oven1)
		(appliance-type mixer mixer1)
		; Method declarations
		(has-prepare-method slice chopping-board knife)
		(has-cook-method bake tray oven)
		(has-combine-method mix mixing-bowl mixer)
		; Initial agent state
		(handempty)
		(agent-at-loc start-loc)
		; Initial food locations
		(object-at-loc egg1 food-loc)
		(object-at-loc flour1 food-loc)
		(object-at-loc tomato1 food-loc)
		(object-at-loc cheese1 food-loc)
		(object-at-loc sausage1 food-loc)
		(object-at-loc basil1 food-loc)
		(object-at-loc olive1 food-loc)
		; Receptacle, tool, and appliance locations
		(object-at-loc mixer1 mix-loc)
		(object-at-loc mixing-bowl1 mix-loc)
		(object-at-loc board1 chop-loc)
		(object-at-loc knife1 chop-loc)
		(object-at-loc oven1 oven-loc)
		(object-at-loc plate1 plate-loc)
		(object-at-loc tray1 tray-loc)
		; Whether receptacles are located on appliances
		(in-appliance mixing-bowl1 mixer1)
		(occupied mixer1)


	
	)
	(:goal
	(exists (?egg - food ?flour - food ?tomato - food ?cheese - food ?basil - food ?plate - receptacle)
        (and (food-type egg ?egg)
			 (food-type flour ?flour)
             (food-type tomato ?tomato)
             (food-type cheese ?cheese)
             (food-type basil ?basil)
			 (receptacle-type plate ?plate)
			 (prepared slice ?tomato)
			 (combined-with mix ?egg ?flour)
			 (cooked-with bake ?egg ?flour)
             (cooked-with bake ?tomato ?flour)
             (cooked-with bake ?tomato ?cheese)
             (cooked-with bake ?cheese ?basil)
             (in-receptacle ?tomato ?plate)
             (in-receptacle ?cheese ?plate)
             (in-receptacle ?basil ?plate)
			 (in-receptacle ?egg ?plate)
             (in-receptacle ?flour ?plate)))
	)
)
