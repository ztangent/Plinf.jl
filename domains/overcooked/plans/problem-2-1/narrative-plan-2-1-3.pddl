(move start-loc food-loc)
(pick-up tuna1 food-loc)
(move food-loc stove-loc)
(place-in tuna1 pan1 stove-loc)
(cook grill pan1 stove1 stove-loc)
; They place tuna in the pan for grilling.
(pick-up pan1 stove-loc)
(move stove-loc plate-loc)
(transfer pan1 plate1 plate-loc)
; They transfer the grilled tuna to a plate.
