# hardcoded experiment sequences

#experiment 1a - backtracking
actions = ["(unstack o e)", "(stack o w)", "(unstack e c)",
        "(stack e r)", "(unstack o w)", "(stack o c)",
        "(unstack w p)", "(stack w e)", "(unstack o c)",
        "(stack o w)", "(pick-up p)", "(stack p o)"]

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

#experiment 4b - intermediate matching goal
actions = ["(unstack a r)", "(stack a w)",
        "(pick-up r)", "(stack r w)", "(unstack d e)",
        "(stack d r)"]
