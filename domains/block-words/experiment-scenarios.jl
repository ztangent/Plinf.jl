# hardcoded experiment sequences

#experiment 2- misspelled word
actions = ["(unstack p r)", "(put-down p)", "(unstack c e)",
        "(stack c p)", "(pick-up e)", "(stack e r)",
        "(pick-up o)", "(stack o e)", "(pick-up w)",
        "(stack w o)", "(unstack c p)", "(stack c w)",
        "(unstack c w)", "(put-down c)", "(unstack w o)",
        "(put-down w)", "(unstack o e)", "(put-down o)",
        "(pick-up w)", "(stack w e)", "(pick-up o)",
        "(stack o w)", "(pick-up c)",
        "(stack c o)"]

#experiment 3- moving irrelevant blocks
actions = ["(pick-up a)", "(stack a b)", "(unstack a b)",
        "(put-down a)", "(pick-up b)", "(stack b a)",
        "(unstack b a)", "(put-down b)"]
