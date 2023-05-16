(move start-loc food-loc)
(pick-up milk1 food-loc)
(move food-loc blend-loc)
(place-in milk1 blender-jug1 blend-loc)
; Pick up milk and pour it into the blender jug.
(move blend-loc food-loc)
(pick-up chocolate1 food-loc)
(move food-loc blend-loc)
(place-in chocolate1 blender-jug1 blend-loc)
; Place chocolate into the blender jug.
(move blend-loc food-loc)
(pick-up ice1 food-loc)
(move food-loc blend-loc)
(place-in ice1 blender-jug1 blend-loc)
; Add ice to the blender jug.
(combine blend blender-jug1 blender1 blend-loc)
; Blend everything in the blender jug.
(pick-up blender-jug1 blend-loc)
(move blend-loc glass-loc)
(transfer blender-jug1 glass1 glass-loc)
; Pour the blended mixture into a glass.
