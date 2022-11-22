; Salad bar with sliced lettuce as a goal
(define (problem overcooked-problem-1-1)
	(:domain overcooked)
	(:objects
		tomato lettuce cucumber cheese bacon egg avocado chicken feta-cheese olive onion salad-dressing - ftype ; Food types
		chopping-board plate pot - rtype ; Receptacle types
		knife glove - ttype ; Tool types
		mixer stove - atype ; Appliance types
		slice crumble chop - prepare-method ; Preparation methods
		boil - cook-method ; Cooking methods
		mix - combine-method ; Combination methods
		tomato1 lettuce1 cucumber1 cheese1 bacon1 egg1 avocado1 chicken1 feta-cheese1 olive1 onion1 salad-dressing1 - food ; Food objects
		board1 plate1 pot1 - receptacle ; Receptacle objects
		knife1 glove1 - tool ; Tool objects
		mixer1 stove1 - appliance ; Appliance types
		start-loc food-loc chop-loc plate-loc stove-loc mix-loc - location ; Locations
	)
	(:init
		; Type declarations
		(food-type tomato tomato1)
		(food-type lettuce lettuce1)
		(food-type cucumber cucumber1)
		(food-type cheese cheese1)
		(food-type bacon bacon1)
		(food-type egg egg1)
		(food-type avocado avocado1)
		(food-type chicken chicken1)
		(food-type olive olive1)
		(food-type onion onion1)
		(food-type feta-cheese feta-cheese1)
		(food-type salad-dressing salad-dressing1)
		(receptacle-type chopping-board board1)
		(receptacle-type plate plate1)
		(receptacle-type pot pot1)
		(tool-type knife knife1)
		(tool-type glove glove1)
		(appliance-type stove stove1)
		(appliance-type mixer mixer1)
		; Method declarations
		(has-prepare-method slice chopping-board knife)
		(has-prepare-method crumble chopping-board glove)
		(has-prepare-method chop chopping-board knife)
		(has-cook-method boil pot stove)
		(has-combine-method mix mixing-bowl mixer)
		; Initial agent state
		(handempty)
		(agent-at-loc start-loc)
		; Initial food locations
		(object-at-loc tomato1 food-loc)
		(object-at-loc lettuce1 food-loc)
		(object-at-loc cucumber1 food-loc)
		(object-at-loc cheese1 food-loc)
		(object-at-loc egg1 food-loc)
		(object-at-loc bacon1 food-loc)
		(object-at-loc avocado1 food-loc)
		(object-at-loc chicken1 food-loc)
		(object-at-loc feta-cheese1 food-loc)
		(object-at-loc onion1 food-loc)
		(object-at-loc olive1 food-loc)
		(object-at-loc salad-dressing1 food-loc)
		; Initial receptacle and tool locations
		(object-at-loc board1 chop-loc)
		(object-at-loc knife1 chop-loc)
		(object-at-loc glove1 chop-loc)
		; Initial appliance locations
		(object-at-loc mixing-bowl1 mix-loc)
		(object-at-loc stove1 stove-loc)
		;Maybe glove fixed to agent location
		(object-at-loc plate1 plate-loc)
		(object-at-loc pot1 stove-loc)
		; Whether receptacles are located on appliances
		(in-appliance pot1 stove1)
		(occupied stove1)
	)
	(:goal
		(exists (?lettuce - food ?tomato - food ?cheese - food ?bacon - food ?avocado - food ?egg - food ?salad-dressing - food ?plate - receptacle)
		        (and (food-type lettuce ?lettuce)
					 (food-type tomato ?tomato) 
					 (food-type cheese ?cheese)
					 (food-type bacon ?bacon)
					 (food-type egg ?egg)
					 (food-type avocado ?avocado)
					 (food-type salad-dressing ?salad-dressing)
                     (receptacle-type plate ?plate)
					 (cooked boil ?egg)
					 (prepared chop ?lettuce)
					 (prepared slice ?tomato)
					 (prepared slice ?cheese)
					 (prepared crumble ?bacon)
					 (prepared slice ?avocado)
					 (in-receptacle ?salad-dressing ?plate)
					 (in-receptacle ?lettuce ?plate)
					 (in-receptacle ?tomato ?plate)
					 (in-receptacle ?cheese ?plate)
					 (in-receptacle ?egg ?plate)
					 (in-receptacle ?avocado ?plate)
                     (in-receptacle ?bacon ?plate)))
	)
)
