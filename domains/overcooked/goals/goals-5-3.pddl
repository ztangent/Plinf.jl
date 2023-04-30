; A tasty chocolate donut made from eggs, flour, and chocolate, mixed together and then deep fried.
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
; A tasty donut made from eggs and flour mixed together and then deep fried.
        (exists (?egg - food ?flour - food ?plate - receptacle)
                (and (food-type egg ?egg)
                     (food-type flour ?flour)
                     (receptacle-type plate ?plate)
                     (combined-with mix ?egg ?flour)
                     (cooked-with deep-fry ?egg ?flour)
                     (in-receptacle ?egg ?plate)
                     (in-receptacle ?flour ?plate)))
; A yummy strawberry donut made from eggs, flour mixed together, filled with strawberries and then deep fried.
        (exists (?egg - food ?strawberry - food ?flour - food ?plate - receptacle)
                (and (food-type egg ?egg)
                     (food-type flour ?flour)
                     (food-type strawberry ?strawberry)
                     (receptacle-type plate ?plate)
                     (combined-with mix ?egg ?flour)
                     (cooked-with deep-fry ?egg ?flour)
                     (cooked-with deep-fry ?flour ?strawberry)
                     (in-receptacle ?egg ?plate)
                     (in-receptacle ?strawberry ?plate)
                     (in-receptacle ?flour ?plate)))
; A delicious apple fritter made from eggs, flour, and sliced apples, mixed together and then deep fried.
        (exists (?egg - food ?apple - food ?flour - food ?plate - receptacle)
                (and (food-type egg ?egg)
                     (food-type flour ?flour)
                     (food-type apple ?apple)
                     (receptacle-type plate ?plate)
                     (prepared slice ?apple)
                     (combined-with mix ?egg ?flour)
                     (cooked-with deep-fry ?egg ?flour)
                     (cooked-with deep-fry ?flour ?apple)
                     (in-receptacle ?egg ?plate)
                     (in-receptacle ?apple ?plate)
                     (in-receptacle ?flour ?plate)))
;A yummy strawberry-filled chocolate donut made from eggs and flour mixed together and deep fried, filled with strawberry jelly and covered in chocolate.
        (exists (?egg - food ?strawberry - food ?chocolate - food ?flour - food ?plate - receptacle)
                (and (food-type egg ?egg)
                     (food-type flour ?flour)
                     (food-type strawberry ?strawberry)
                     (food-type chocolate ?chocolate)
                     (receptacle-type plate ?plate)
                     (combined-with mix ?egg ?flour)
                     (combined-with mix ?flour ?chocolate)
                     (cooked-with deep-fry ?egg ?flour)
                     (cooked-with deep-fry ?flour ?strawberry)
                     (cooked-with deep-fry ?strawberry ?chocolate)
                     (in-receptacle ?egg ?plate)
                     (in-receptacle ?strawberry ?plate)
                     (in-receptacle ?chocolate ?plate)
                     (in-receptacle ?flour ?plate)))