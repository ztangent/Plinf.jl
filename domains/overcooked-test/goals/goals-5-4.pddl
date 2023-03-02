; A freshly made chocolate shake made of milk, ice, and chocolate served in a glass.
        (exists (?ice - food ?chocolate - food ?milk - food ?glass - receptacle)
                (and (food-type ice ?ice)
                     (food-type milk ?milk)
                     (food-type chocolate ?chocolate)
                     (receptacle-type glass ?glass)
                     (combined-with blend ?ice ?milk)
                     (combined-with blend ?milk ?chocolate)
                     (in-receptacle ?ice ?glass)
                     (in-receptacle ?chocolate ?glass)
                     (in-receptacle ?milk ?glass)))
; A glass of chocolate milk made of chocolate and milk served in a glass.
        (exists (?chocolate - food ?milk - food ?glass - receptacle)
                (and (food-type milk ?milk)
                     (food-type chocolate ?chocolate)
                     (receptacle-type glass ?glass)
                     (combined-with blend ?milk ?chocolate)
                     (in-receptacle ?chocolate ?glass)
                     (in-receptacle ?milk ?glass)))
; A glass of strawberry milk made of strawberries and milk served in a glass.
        (exists (?strawberry - food ?milk - food ?glass - receptacle)
                (and (food-type milk ?milk)
                     (food-type strawberry ?strawberry)
                     (receptacle-type glass ?glass)
                     (combined-with blend ?strawberry ?milk)
                     (in-receptacle ?strawberry ?glass)
                     (in-receptacle ?milk ?glass)))
; A smoothie made of watermelon, apple, grape, and ice served in a glass.
        (exists (?ice - food ?watermelon - food ?apple - food ?grape - food ?glass - receptacle)
                (and (food-type ice ?ice)
                     (food-type watermelon ?watermelon)
                     (food-type apple ?apple)
                     (food-type grape ?grape)
                     (receptacle-type glass ?glass)
                     (combined-with blend ?grape ?watermelon)
                     (combined-with blend ?watermelon ?apple)
                     (combined-with blend ?apple ?ice)
                     (in-receptacle ?apple ?glass)
                     (in-receptacle ?watermelon ?glass)
                     (in-receptacle ?grape ?glass)
                     (in-receptacle ?ice ?glass)))
; A smoothie made of watermelon, apple, and strawberries served in a glass.
        (exists (?ice - food ?watermelon - food ?apple - food ?strawberry - food ?glass - receptacle)
                (and (food-type ice ?ice)
                     (food-type watermelon ?watermelon)
                     (food-type apple ?apple)
                     (food-type strawberry ?strawberry)
                     (receptacle-type glass ?glass)
                     (combined-with blend ?strawberry ?watermelon)
                     (combined-with blend ?watermelon ?apple)
                     (combined-with blend ?apple ?ice)
                     (in-receptacle ?apple ?glass)
                     (in-receptacle ?watermelon ?glass)
                     (in-receptacle ?strawberry ?glass)
                     (in-receptacle ?ice ?glass)))