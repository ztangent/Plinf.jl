; Goal 1: Greek salad
        (exists (?onion - food ?tomato - food ?cucumber - food ?olive - food ?feta-cheese - food ?plate - receptacle)
                (and (food-type olive ?olive)
                     (food-type tomato ?tomato)
                     (food-type cucumber ?cucumber)
                     (food-type onion ?onion)
                     (food-type feta-cheese ?feta-cheese)
                     (receptacle-type plate ?plate)
                     (prepared chop ?olive)
                     (prepared chop ?tomato)
                     (prepared chop ?cucumber)
                     (prepared chop ?onion)
                     (prepared crumble ?feta-cheese)
                     (in-receptacle ?olive ?plate)
                     (in-receptacle ?feta-cheese ?plate)
                     (in-receptacle ?cucumber ?plate)
                     (in-receptacle ?onion ?plate)
                     (in-receptacle ?tomato ?plate)))
; Goal 2: Sliced tomato and cucumber
        (exists (?tomato - food ?cucumber - food ?plate - receptacle)
                (and (food-type tomato ?tomato)
                     (food-type cucumber ?cucumber)
                     (receptacle-type plate ?plate)
                     (prepared slice ?tomato)
                     (prepared slice ?cucumber)
                     (in-receptacle ?cucumber ?plate)
                     (in-receptacle ?tomato ?plate)))
; Goal 3: Sliced cucumber, chopped onion, and feta cheese
        (exists (?cucumber - food ?onion - food ?feta-cheese - food ?plate - receptacle)
                (and (food-type onion ?onion)
                     (food-type cucumber ?cucumber)
                     (food-type feta-cheese ?feta-cheese)
                     (receptacle-type plate ?plate)
                     (prepared chop ?onion)
                     (prepared slice ?cucumber)
                     (prepared crumble ?feta-cheese)
                     (in-receptacle ?onion ?plate)
                     (in-receptacle ?cucumber ?plate)
                     (in-receptacle ?feta-cheese ?plate)))
; Goal 4: Crumbled feta cheese and tomato
        (exists (?feta-cheese - food ?tomato - food ?plate - receptacle)
                (and (food-type feta-cheese ?feta-cheese)
                     (food-type tomato ?tomato)
                     (receptacle-type plate ?plate)
                     (prepared slice ?tomato)
                     (prepared crumble ?feta-cheese)
                     (in-receptacle ?tomato ?plate)
                     (in-receptacle ?feta-cheese ?plate)))
; Goal 5: Crumbled feta cheese and chopped olive
        (exists (?olive - food ?feta-cheese - food ?plate - receptacle)
                (and (food-type olive ?olive)
                     (food-type feta-cheese ?feta-cheese)
                     (receptacle-type plate ?plate)
                     (prepared chop ?olive)
                     (prepared crumble ?feta-cheese)
                     (in-receptacle ?olive ?plate)
                     (in-receptacle ?feta-cheese ?plate)))
