(move start-loc food-loc)
(pick-up rice1 food-loc)
(move food-loc stove-loc)
(place-in rice1 pot1 stove-loc)
(cook boil pot1 stove1 stove-loc)
; They find some rice and boil it on the stove.
(pick-up pot1 stove-loc)
(move stove-loc plate-loc)
(transfer pot1 plate1 plate-loc)
; After the rice is done cooking, they transfer it from the pot to the plate.
(put-down pot1 plate-loc)
(pick-up plate1 plate-loc)
(move plate-loc food-loc)
(put-down plate1 food-loc)
(pick-up cucumber1 food-loc)
(place-in cucumber1 plate1 food-loc)
; They place cucumber in the plate.
(pick-up avocado1 food-loc)
(place-in avocado1 plate1 food-loc)
(pick-up nori1 food-loc)
(place-in nori1 plate1 food-loc)
; They add avocado and nori to the plate.
