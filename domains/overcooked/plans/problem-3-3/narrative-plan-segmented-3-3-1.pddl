(move start-loc food-loc)
(pick-up hamburger-bun1 food-loc)
; They pick up a hamburger bun.
(move food-loc plate-loc)
(place-in hamburger-bun1 plate1 plate-loc)
; They place the hamburger bun on the plate.
(move plate-loc food-loc)
(pick-up beef1 food-loc)
; They pick up the beef.
(move food-loc stove-loc)
(place-in beef1 pan1 stove-loc)
; They place the beef on a pan on the stove.
(cook grill pan1 stove1 stove-loc)
; They grill the pan on the stove.
(pick-up pan1 stove-loc)
(move stove-loc plate-loc)
(transfer pan1 plate1 plate-loc)
; They transfer the grilled beef to the plate.
(put-down pan1 plate-loc)
(move plate-loc food-loc)
(pick-up cheese1 food-loc)
; They pick up cheese.
(move food-loc chop-loc)
(place-in cheese1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 cheese1 chop-loc)
; They slice the cheese on the chopping board.
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
(move plate-loc food-loc)
; They put the sliced cheese on the plate with the hamburger bun and grilled beef.
(put-down board1 food-loc)
(pick-up potato1 food-loc)
(place-in potato1 board1 food-loc)
(move food-loc chop-loc)
(pick-up knife1 chop-loc)
(move chop-loc food-loc)
(prepare slice board1 knife1 potato1 food-loc)
; They slice the potato on the chopping board.
(put-down knife1 food-loc)
(pick-up board1 food-loc)
(move food-loc fryer-loc)
(transfer board1 basket1 fryer-loc)
(cook deep-fry basket1 fryer1 fryer-loc)
; They deep fry the slices of potato.
(move fryer-loc chop-loc)
(put-down board1 chop-loc)
(move chop-loc fryer-loc)
(pick-up basket1 fryer-loc)
(move fryer-loc plate-loc)
(transfer basket1 plate1 plate-loc)
; They transfer the fried slices of potato to the plate with the hamburger bun, grilled beef, and cheese.
