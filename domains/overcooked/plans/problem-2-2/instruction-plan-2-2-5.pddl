(move start-loc food-loc)
(pick-up tuna1 food-loc)
(move food-loc chop-loc)
(place-in tuna1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 tuna1 chop-loc)
; Find some raw tuna and slice it.
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc bowl-loc)
(transfer board1 bowl1 bowl-loc)
; Put the tuna in a bowl.
(move bowl-loc food-loc)
(put-down board1 food-loc)
(pick-up rice1 food-loc)
(move food-loc stove-loc)
(place-in rice1 pot1 stove-loc)
(cook boil pot1 stove2 stove-loc)
; Place rice in a pot and cook it on the stove.
(pick-up pot1 stove-loc)
(move stove-loc bowl-loc)
(transfer pot1 bowl1 bowl-loc)
; Add the cooked rice to the bowl.
