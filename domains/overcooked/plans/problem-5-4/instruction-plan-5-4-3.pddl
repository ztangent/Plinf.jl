(move start-loc food-loc)
(pick-up milk1 food-loc)
(move food-loc blend-loc)
(place-in milk1 blender-jug1 blend-loc)
; Add milk to the blender jug.
(move blend-loc food-loc)
(pick-up strawberry1 food-loc)
(move food-loc blend-loc)
(place-in strawberry1 blender-jug1 blend-loc)
(combine blend blender-jug1 blender1 blend-loc)
; Add strawberry to the blender jug, then blend everything together.
(pick-up blender-jug1 blend-loc)
(move blend-loc glass-loc)
(transfer blender-jug1 glass1 glass-loc)
; Pour the blended contents of the jug into a glass.
