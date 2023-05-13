(move start-loc food-loc)
(pick-up hamburger-bun1 food-loc)
; They pick up a hamburger bun. This involves moving to the hamburger bun, and then picking it up.
(move food-loc plate-loc)
(place-in hamburger-bun1 plate1 plate-loc)
; They place the hamburger bun on the plate. This involves moving to the plate, and then placing the hamburger bun on the plate.
(move plate-loc food-loc)
(pick-up beef1 food-loc)
; They pick up the beef. This involves moving to the beef, and then picking it up.
(move food-loc stove-loc)
(place-in beef1 pan1 stove-loc)
; They place the beef on a pan on the stove. This involves moving to the stove, and then placing the beef on the pan.
(cook grill pan1 stove1 stove-loc)
; They grill the pan on the stove. This involves no additional actions.
(pick-up pan1 stove-loc)
(move stove-loc plate-loc)
(transfer pan1 plate1 plate-loc)
; They transfer the grilled beef to the plate. This involves picking up the pan, moving to the plate, and then transferring the grilled beef to the plate.
(put-down pan1 plate-loc)
(move plate-loc food-loc)
(pick-up cheese1 food-loc)
; They pick up cheese. This involves first putting down the pan, moving to the cheese, then picking it up.
(move food-loc chop-loc)
(place-in cheese1 board1 chop-loc)
(pick-up knife1 chop-loc)
(prepare slice board1 knife1 cheese1 chop-loc)
; They slice the cheese on the chopping board. This involves moving to the chopping board, picking up the knife, and then slicing the cheese.
(put-down knife1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
(move plate-loc food-loc)
; They put the sliced cheese on the plate with the hamburger bun and grilled beef. This involves first putting down the knife, then picking up the chopping board, moving to the plate, and transferring the sliced cheese to the plate.
(put-down board1 food-loc)
(pick-up potato1 food-loc)
(place-in potato1 board1 food-loc)
(move food-loc chop-loc)
(pick-up knife1 chop-loc)
(move chop-loc food-loc)
(prepare slice board1 knife1 potato1 food-loc)
; They slice the potato on the chopping board. This involves first putting down the chopping board, then placing the potato on the chopping board, picking up the knife, and slicing the potato.
(put-down knife1 food-loc)
(pick-up board1 food-loc)
(move food-loc fryer-loc)
(transfer board1 basket1 fryer-loc)
(cook deep-fry basket1 fryer1 fryer-loc)
; They deep fry the slices of potato. This involves first putting down the knife, then picking up the chopping board, moving to the fryer, transferring the potato from the board to the frying basket, and deep frying the potato.
(move fryer-loc chop-loc)
(put-down board1 chop-loc)
(move chop-loc fryer-loc)
(pick-up basket1 fryer-loc)
(move fryer-loc plate-loc)
(transfer basket1 plate1 plate-loc)
; They transfer the fried slices of potato to the plate with the hamburger bun, grilled beef, and cheese. This involves first putting down the chopping board, then picking up the frying basket, moving to the plate, and transferring the fried slices of potato to the plate.
