# hardcoded experiment sequences

# Dictionary of Actions
action_dict = Dict()

# Dictionary of Goal Space
goal_space_dict = Dict()

#experiment 1a - backtracking - letter need later
action_dict["1-1"] = ["(unstack o e)", "(stack o w)", "(unstack e c)",
                "(stack e r)", "(unstack o w)", "(stack o c)",
                "(unstack w p)", "(stack w e)", "(unstack o c)",
                "(stack o w)", "(pick-up p)", "(stack p o)"]
goal_space_dict["1-1"] = ["power", "cower", "crow", "core", "pore"]

action_dict["1-2"] = ["(unstack e p)", "(stack e r)", "(unstack p w)",
                "(stack p o)", "(pick-up w)", "(stack w e)",
                "(unstack p o)", "(put-down p)", "(unstack o c)",
                "(stack o w)", "(pick-up c)", "(stack c o)"]
goal_space_dict["1-2"] = ["power", "cower", "crow", "core", "pore"]

#experiment 1a - backtracking - letter on goal
action_dict["1-3"] = ["(unstack r w)", "(stack r e)", "(unstack c p)",
                "(stack c r)", "(unstack p o)", "(put-down p)",
                "(unstack c r)", "(stack c w)", "(pick-up o)",
                "(stack o r)", "(unstack c w)", "(stack c o)"]
goal_space_dict["1-3"] = ["power", "cower", "crow", "core", "pore"]

action_dict["1-4"] = ["(unstack p r)", "(stack p o)", "(unstack e c)",
                "(put-down e)", "(unstack p o)", "(stack p e)",
                "(pick-up r)", "(stack r o)", "(pick-up c)",
                "(stack c r)"]
goal_space_dict["1-4"] = ["power", "cower", "crow", "core", "pore"]


#experiment 2- misspelled word
action_dict["2-1"] = ["(unstack p r)", "(put-down p)", "(unstack c e)",
                "(stack c p)", "(pick-up e)", "(stack e r)",
                "(pick-up o)", "(stack o e)", "(pick-up w)",
                "(stack w o)", "(unstack c p)", "(stack c w)",
                "(unstack c w)", "(put-down c)", "(unstack w o)",
                "(put-down w)", "(unstack o e)", "(put-down o)",
                "(pick-up w)", "(stack w e)", "(pick-up o)",
                "(stack o w)", "(pick-up c)", "(stack c o)"]
goal_space_dict["2-1"] = ["power", "cower", "crow", "core", "pore"]

action_dict["2-2"] = ["(unstack o r)", "(stack o e)", "(unstack r w)",
                "(stack r o)", "(unstack p c)", "(stack p r)",
                "(unstack p r)", "(put-down p)", "(unstack r o)",
                "(stack r p)", "(unstack o e)", "(stack o w)",
                "(unstack r p)", "(stack r e)", "(unstack o w)",
                "(stack o r)", "(pick-up p)", "(stack p o)"]
goal_space_dict["2-2"] = ["power", "cower", "crow", "core", "pore"]

action_dict["2-3"] = ["(unstack r a)", "(stack r p)", "(unstack a w)",
                "(stack a r)", "(unstack e d)", "(stack e a)",
                "(unstack e a)", "(put-down e)", "(unstack a r)",
                "(stack a e)", "(unstack r p)", "(stack r w)",
                "(unstack a e)", "(stack a p)", "(pick-up e)",
                "(stack e a)", "(unstack r w)", "(stack r e)"]
goal_space_dict["2-3"] = ["ear", "reap", "pear", "wade", "draw"]

action_dict["2-4"] = ["(unstack p w)", "(stack p e)", "(pick-up a)",
                "(stack a r)", "(pick-up w)", "(stack w a)",
                "(unstack w a)", "(put-down w)", "(unstack a r)",
                "(stack a w)", "(unstack r d)", "(stack r a)",
                "(pick-up d)", "(stack d r)"]
goal_space_dict["2-4"] = ["wad", "reap", "war", "wade", "draw"]

#experiment 3- moving irrelevant blocks
action_dict["3-1"] = ["(unstack d c)", "(put-down d)", "(unstack w r)",
                "(put-down w)", "(unstack a p)", "(stack a r)",
                "(unstack p e)", "(stack p d)", "(pick-up w)",
                "(stack w a)"]
goal_space_dict["3-1"] = ["cower", "war", "wear", "crow", "core"]

action_dict["3-2"] = ["(unstack d o)", "(put-down d)", "(unstack w c)",
                "(put-down w)", "(unstack o p)", "(stack o c)",
                "(pick-up w)", "(stack w o)", "(pick-up p)",
                "(stack p d)", "(unstack a e)", "(put-down a)",
                "(unstack w o)", "(stack w e)", "(unstack o c)",
                "(stack o w)", "(pick-up c)", "(stack c o)"]
goal_space_dict["3-2"] = ["cower", "war", "wear", "crow", "core"]

action_dict["3-3"] = ["(unstack d p)", "(stack d a)", "(pick-up c)",
                "(stack c d)", "(unstack e w)", "(put-down e)",
                "(unstack p o)", "(put-down p)", "(pick-up r)",
                "(stack r e)", "(pick-up w)", "(stack w p)",
                "(pick-up o)", "(stack o r)", "(unstack c d)",
                "(stack c o)"]
goal_space_dict["3-3"] = ["cower", "war", "wear", "crow", "core"]

action_dict["3-4"] = ["(unstack a d)", "(put-down a)", "(unstack d e)",
                "(put-down d)", "(unstack p r)", "(stack p d)",
                "(unstack c w)", "(put-down c)", "(unstack w o)",
                "(put-down w)", "(pick-up o)", "(stack o w)",
                "(unstack p d)", "(put-down p)", "(pick-up r)",
                "(stack r o)", "(pick-up c)", "(stack c r)"]
goal_space_dict["3-4"] = ["cower", "war", "wear", "crow", "core"]

#experiment 4a - initial configuration matches goal state
action_dict["4-1"]= ["(unstack c r)", "(stack c p)", "(unstack r o)",
                "(stack r e)", "(unstack o w)", "(stack o r)",
                "(unstack c p)", "(stack c o)"]
goal_space_dict["4-1"] = ["power", "cower", "crow", "core", "pore"]

#experiment 4b1 - intermediate matching goal
action_dict["4-2"] = ["(unstack a r)", "(stack a w)", "(pick-up r)",
                "(stack r a)", "(unstack d e)", "(stack d r)"]
goal_space_dict["4-2"] = ["raw", "paw", "draw", "war", "wear"]

#experiment 4b2 - intermediate matching goal
action_dict["4-3"] = ["(unstack a w)", "(stack a r)", "(unstack e p)",
                "(stack e a)", "(pick-up w)", "(stack w e)"]
goal_space_dict["4-3"] = ["ear", "paw", "dear", "war", "wear"]

#experiment 4c - rhyming suffix (not a goal state)
action_dict["4-4"]= ["(unstack a e)", "(stack a r)", "(unstack e p)",
                "(stack e a)", "(pick-up w)", "(stack w e)"]
goal_space_dict["4-4"] = ["raw", "paw", "draw", "war", "wear"]

# Get action list for respective experiment
function get_action(experiment)
        return action_dict[experiment]
end

# Get goal space list for respective experiment
function get_goal_space(experiment)
        return goal_space_dict[experiment]
end
