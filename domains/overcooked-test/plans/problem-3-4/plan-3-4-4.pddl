(move start-loc food-loc)
(pick-up cheese1 food-loc)
(move food-loc chop-loc)
(place-in cheese1 board1 chop-loc)
(move chop-loc food-loc)
(pick-up tomato1 food-loc)
(move food-loc chop-loc)
(place-in tomato1 board1 chop-loc)
(move chop-loc food-loc)
(pick-up lettuce1 food-loc)
(move food-loc chop-loc)
(place-in lettuce1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 tomato1 chop-loc)
(prepare slice board1 knife1 cheese1 chop-loc)
(prepare slice board1 knife1 lettuce1 chop-loc)
; (prepared slice cheese1) (prepared slice tomato1) (prepared slice lettuce1)
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; (in-receptacle cheese1 plate1) (in-receptacle tomato1 plate1) (in-receptacle lettuce1 plate1)
(move plate-loc food-loc)
(put-down board1 food-loc)
(pick-up potato1 food-loc)
(place-in potato1 board1 food-loc)
(move food-loc chop-loc)
(pick-up knife1 chop-loc)
(move chop-loc food-loc)
(prepare slice board1 knife1 potato1 food-loc)
; (prepared slice potato1)
(put-down knife1 food-loc)
(pick-up board1 food-loc)
(move food-loc fryer-loc)
(transfer board1 basket1 fryer-loc)
(cook deep-fry basket1 fryer1 fryer-loc)
; (cooked deep-fry potato1)
(move fryer-loc chop-loc)
(put-down board1 chop-loc)
(move chop-loc fryer-loc)
(pick-up basket1 fryer-loc)
(move fryer-loc plate-loc)
(transfer basket1 plate1 plate-loc)
; (in-receptacle potato1 plate1)
(move plate-loc food-loc)
(put-down basket1 food-loc)
(pick-up tuna1 food-loc)
(move food-loc mix-loc)
(place-in tuna1 mixing-bowl1 mix-loc)
(move mix-loc food-loc)
(pick-up mayo1 food-loc)
(move food-loc mix-loc)
(place-in mayo1 mixing-bowl1 mix-loc)
(combine mix mixing-bowl1 mixer1 mix-loc)
; (combined-with mix tuna1 mayo1)
(pick-up mixing-bowl1 mix-loc)
(move mix-loc plate-loc)
(transfer mixing-bowl1 plate1 plate-loc)
; (in-receptacle tuna1 plate1) (in-receptacle mayo1 plate1)
(put-down mixing-bowl1 plate-loc)
(move plate-loc food-loc)
(pick-up bread1 food-loc)
(move food-loc plate-loc)
(place-in bread1 plate1 plate-loc)
; (in-receptacle bread1 plate1)
