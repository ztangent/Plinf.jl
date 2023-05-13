(move start-loc food-loc)
(pick-up milk1 food-loc)
; They pick up milk. This involves moving to the milk, and then picking it up.
(move food-loc blend-loc)
(place-in milk1 blender-jug1 blend-loc)
; They pour the milk into the blender jug. This involves moving to the blender jug, and then placing the milk in it.
(move blend-loc food-loc)
(pick-up chocolate1 food-loc)
(move food-loc blend-loc)
(place-in chocolate1 blender-jug1 blend-loc)
; They place chocolate into the blender jug. This involves picking up the chocolate, moving to the blender jug, and then placing the chocolate in it.
(move blend-loc food-loc)
(pick-up ice1 food-loc)
(move food-loc blend-loc)
(place-in ice1 blender-jug1 blend-loc)
; They add ice to the blender jug. This involves picking up the ice, moving to the blender jug, and then placing the ice in it.
(combine blend blender-jug1 blender1 blend-loc)
; They blend everything in the blender jug. This involves no additional actions.
(pick-up blender-jug1 blend-loc)
(move blend-loc glass-loc)
(transfer blender-jug1 glass1 glass-loc)
; They pour the blended mixture into a glass. This involves picking up the blender jug, moving to the glass, and then transferring the mixture into it.
