; Goal 1: Plain Donut
        (exists (?egg - food ?chocolate - food ?flour - food ?plate - receptacle)
                (and (food-type egg ?egg)
                     (food-type flour ?flour)
                     (food-type chocolate ?chocolate)
                     (receptacle-type plate ?plate)
                     (combined-with mix ?egg ?flour)
                     (combined-with mix ?flour ?chocolate)
                     (cooked-with deep-fry ?egg ?flour)
                     (cooked-with deep-fry ?flour ?chocolate)
                     (in-receptacle ?egg ?plate)
                     (in-receptacle ?chocolate ?plate)
                     (in-receptacle ?flour ?plate)))
; Goal 2: Chocolate donut
        (exists (?egg - food ?chocolate - food ?flour - food ?plate - receptacle)
                (and (food-type egg ?egg)
                     (food-type flour ?flour)
                     (food-type chocolate ?chocolate)
                     (receptacle-type plate ?plate)
                     (combined-with mix ?egg ?flour)
                     (combined-with mix ?flour ?chocolate)
                     (cooked-with deep-fry ?egg ?flour)
                     (cooked-with deep-fry ?flour ?chocolate)
                     (in-receptacle ?egg ?plate)
                     (in-receptacle ?chocolate ?plate)
                     (in-receptacle ?flour ?plate)))
; Goal 3: Strawberry donut
        (exists (?egg - food ?strawberry - food ?flour - food ?plate - receptacle)
                (and (food-type egg ?egg)
                     (food-type flour ?flour)
                     (food-type strawberry ?strawberry)
                     (receptacle-type plate ?plate)
                     (combined-with mix ?egg ?flour)
                     (combined-with mix ?flour ?strawberry)
                     (cooked-with deep-fry ?egg ?flour)
                     (cooked-with deep-fry ?flour ?strawberry)
                     (in-receptacle ?egg ?plate)
                     (in-receptacle ?strawberry ?plate)
                     (in-receptacle ?flour ?plate)))
; Goal 4: Apple donut
        (exists (?egg - food ?apple - food ?flour - food ?plate - receptacle)
                (and (food-type egg ?egg)
                     (food-type flour ?flour)
                     (food-type apple ?apple)
                     (receptacle-type plate ?plate)
                     (prepared slice ?apple)
                     (combined-with mix ?egg ?flour)
                     (combined-with mix ?flour ?apple)
                     (cooked-with deep-fry ?egg ?flour)
                     (cooked-with deep-fry ?flour ?apple)
                     (in-receptacle ?egg ?plate)
                     (in-receptacle ?apple ?plate)
                     (in-receptacle ?flour ?plate)))
; Goal 5: Strawberry filled chocolate donut
        (exists (?egg - food ?strawberry - food ?chocolate - food ?flour - food ?plate - receptacle)
                (and (food-type egg ?egg)
                     (food-type flour ?flour)
                     (food-type strawberry ?strawberry)
                     (food-type chocolate ?chocolate)
                     (receptacle-type plate ?plate)
                     (combined-with mix ?egg ?flour)
                     (combined-with mix ?flour ?strawberry)
                     (combined-with mix ?strawberry ?chocolate)
                     (cooked-with deep-fry ?egg ?flour)
                     (cooked-with deep-fry ?flour ?strawberry)
                     (cooked-with deep-fry ?strawberry ?chocolate)
                     (in-receptacle ?egg ?plate)
                     (in-receptacle ?strawberry ?plate)
                     (in-receptacle ?chocolate ?plate)
                     (in-receptacle ?flour ?plate)))