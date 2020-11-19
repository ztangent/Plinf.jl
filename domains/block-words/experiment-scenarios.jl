# hardcoded experiment sequences

# Dictionary of Actions
action_dict = Dict()

#experiment 1a - backtracking
action_dict["1a1"] = ["(unstack o e)", "(stack o w)", "(unstack e c)",
                "(stack e r)", "(unstack o w)", "(stack o c)",
                "(unstack w p)", "(stack w e)", "(unstack o c)",
                "(stack o w)", "(pick-up p)", "(stack p o)"]

#experiment 2- misspelled word
action_dict["2a"] = ["(unstack p r)", "(put-down p)", "(unstack c e)",
                "(stack c p)", "(pick-up e)", "(stack e r)",
                "(pick-up o)", "(stack o e)", "(pick-up w)",
                "(stack w o)", "(unstack c p)", "(stack c w)",
                "(unstack c w)", "(put-down c)", "(unstack w o)",
                "(put-down w)", "(unstack o e)", "(put-down o)",
                "(pick-up w)", "(stack w e)", "(pick-up o)",
                "(stack o w)", "(pick-up c)", "(stack c o)"]

#experiment 3- moving irrelevant blocks
action_dict["3a"] = ["(pick-up a)", "(stack a b)", "(unstack a b)",
                "(put-down a)", "(pick-up b)", "(stack b a)",
                "(unstack b a)", "(put-down b)"]

#experiment 4a - initial configuration matches goal state
action_dict["4a"]= ["(unstack c r)", "(stack c p)", "(unstack r o)",
                "(stack r e)", "(unstack o w)", "(stack o r)",
                "(unstack c p)", "(stack c o)"]

#experiment 4b1 - intermediate matching goal
action_dict["4b1"] = ["(unstack a r)", "(stack a w)", "(pick-up r)",
                "(stack r a)", "(unstack d e)", "(stack d r)"]

#experiment 4b2 - intermediate matching goal
action_dict["4b2"] = ["(unstack a w)", "(stack a r)", "(unstack e p)",
                "(stack e a)", "(pick-up w)", "(stack w e)"]

#experiment 4c - rhyming suffix (not a goal state)
action_dict["4c"]= ["(unstack a e)", "(stack a r)", "(unstack e p)",
                "(stack e a)", "(pick-up w)", "(stack w e)"]

# Get action list for respective action
function get_action(action)
        return action_dict[action]
end
