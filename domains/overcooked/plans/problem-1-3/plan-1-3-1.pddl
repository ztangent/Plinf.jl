(move start-loc chop-loc)
(pick-up board1 chop-loc)
(move chop-loc food-loc)
(put-down board1 food-loc)
(pick-up onion1 food-loc)
(place-in onion1 board1 food-loc)
(pick-up tomato1 food-loc)
(place-in tomato1 board1 food-loc)
(pick-up cucumber1 food-loc)
(place-in cucumber1 board1 food-loc)
(pick-up olive1 food-loc)
(place-in olive1 board1 food-loc)
(prepare chop board1 knife1 onion1 chop-loc)
(prepare chop board1 knife1 tomato1 chop-loc)
(prepare chop board1 knife1 cucumber1 chop-loc)
(prepare chop board1 knife1 olive1 chop-loc)
(pick-up feta-cheese1 food-loc)
(place-in feta-cheese1 board1 food-loc)
(pick-up board1 food-loc)
(move food-loc chop-loc)
(put-down board1 chop-loc)
(pick-up knife1 chop-loc)
(put-down knife1 chop-loc)
(pick-up glove1 chop-loc)
(prepare crumble board1 glove1 feta-cheese1 chop-loc)
; (prepared chop olive1) (prepared chop tomato1) (prepared chop cucumber1) (prepared chop onion1) (prepared crumble feta-cheese1)
(put-down glove1 chop-loc)
(pick-up board1 chop-loc)
(move chop-loc plate-loc)
(transfer board1 plate1 plate-loc)
; (in-receptacle olive1 plate1) (in-receptacle tomato1 plate1) (in-receptacle cucumber1 plate1) (in-receptacle onion1 plate1) (in-receptacle feta-cheese1 plate1)