# hardcoded experiment sequences

# Dictionary of Actions
action_dict = Dict()

# Dictionary of Goal Space
goal_space_dict = Dict()

#Category 1: Control
action_dict["1-1"] = ["(unstack o e)", "(stack o w)", "(unstack e c)",
                        "(put-down e)", "(pick-up r)", "(stack r e)",
                        "(unstack o w)", "(stack o r)", "(pick-up c)",
                        "(stack c o)"]
goal_space_dict["1-1"] = ["power", "cower", "crow", "core", "pore"]
#
action_dict["1-2"] = ["(unstack p a)", "(put-down p)", "(unstack a r)",
                        "(stack a d)", "(pick-up w)",
                        "(stack w a)"]
goal_space_dict["1-2"] = ["wad", "reap", "war", "wade", "draw"]

action_dict["1-3"] = ["(unstack a r)", "(stack a w)", "(pick-up r)",
                "(stack r a)", "(unstack d e)", "(stack d r)"]
goal_space_dict["1-3"] = ["raw", "paw", "draw", "war", "wear"]

action_dict["1-4"]= ["(unstack a e)", "(stack a r)", "(unstack e p)",
                "(stack e a)", "(pick-up w)", "(stack w e)"]
goal_space_dict["1-4"] = ["raw", "paw", "draw", "war", "wear"]


#Category 2: actions mistakes
action_dict["2-1"] = ["(unstack a d)", "(stack a p)", "(unstack a p)",
                        "(stack a r)", "(unstack w e)", "(put-down w)", "(pick-up e)",
                        "(stack e a)", "(pick-up p)", "(stack p e)"]
goal_space_dict["2-1"] = ["wad", "reap", "war", "wade", "draw"]

action_dict["2-2"] = ["(pick-up a)", "(stack a r)", "(unstack e d)",
                        "(stack e w)", "(unstack e w)", "(stack e a)"]
goal_space_dict["2-2"] = ["wad", "reap", "war", "wade", "draw"]

action_dict["2-3"] = ["(unstack c e)", "(put-down c)", "(pick-up w)",
                        "(stack w e)", "(unstack o p)", "(stack o p)",
                        "(unstack w e)", "(put-down w)", "(pick-up r)",
                        "(stack r e)", "(unstack o p)", "(stack o r)",
                        "(pick-up c)","(stack c o)"]
goal_space_dict["2-3"] = ["wad", "reap", "war", "wade", "draw"]

action_dict["2-4"] = ["(unstack d a)", "(put-down d)", "(unstack a e)",
                "(stack a w)", "(pick-up p)", "(stack p a)", "(pick-up d)",
                "(put-down d)", "(unstack p a)", "(put-down p)","(pick-up r)",
                "(stack r a)", "(pick-up d)","(stack d r)"]
goal_space_dict["2-4"] = ["raw", "paw", "draw", "war", "wear"]

#Category 3: plans mistakes
action_dict["3-1"] = ["(unstack o e)", "(stack o w)", "(unstack e c)",
                "(stack e r)", "(unstack o w)", "(stack o c)",
                "(unstack w p)", "(stack w e)", "(unstack o c)",
                "(stack o w)", "(pick-up p)", "(stack p o)"]
goal_space_dict["3-1"] = ["power", "cower", "crow", "core", "pore"]

action_dict["3-2"] = ["(unstack e p)", "(stack e r)", "(unstack p w)",
                "(stack p o)", "(pick-up w)", "(stack w e)",
                "(unstack p o)", "(put-down p)", "(unstack o c)",
                "(stack o w)", "(pick-up c)", "(stack c o)"]
goal_space_dict["3-2"] = ["power", "cower", "crow", "core", "pore"]

action_dict["3-3"] = ["(unstack e w)", "(stack e r)", "(unstack w p)",
                "(stack w e)", "(unstack c o)", "(stack c p)",
                "(pick-up o)", "(stack o w)", "(unstack c p)",
                "(put-down c)", "(pick-up p)", "(stack p o)"]
goal_space_dict["3-3"] = ["power", "cower", "crow", "core", "pore"]

action_dict["3-4"] = ["(unstack w e)", "(stack w p)", "(unstack e o)",
                "(put-down e)", "(pick-up r)", "(stack r e)",
                "(pick-up o)", "(stack o r)", "(unstack w p)",
                "(stack w c)", "(pick-up p)", "(stack p o)"]
goal_space_dict["3-4"] = ["power", "cower", "crow", "core", "pore"]

action_dict["3-5"] = ["(unstack r w)", "(stack r e)", "(unstack c p)",
                "(stack c r)", "(unstack p o)", "(put-down p)",
                "(unstack c r)", "(stack c w)", "(pick-up o)",
                "(stack o r)", "(unstack c w)", "(stack c o)"]
goal_space_dict["3-5"] = ["power", "cower", "crow", "core", "pore"]

action_dict["3-6"] = ["(unstack p r)", "(stack p o)", "(unstack e c)",
                "(put-down e)", "(unstack p o)", "(stack p e)",
                "(pick-up r)", "(stack r o)", "(pick-up c)",
                "(stack c r)"]
goal_space_dict["3-6"] = ["power", "cower", "crow", "core", "pore"]

#Category 4: goals mistakes
action_dict["4-1"] = ["(unstack e c)", "(stack e r)", "(unstack o p)",
                "(stack o e)", "(pick-up w)", "(stack w o)", "(pick-up c)",
                "(stack c w)", "(unstack c w)", "(put-down c)", "(unstack w o)",
                "(put-down w)", "(unstack o e)", "(put-down o)",
                "(pick-up w)", "(stack w e)", "(pick-up o)",
                "(stack o w)", "(pick-up c)", "(stack c o)"]
goal_space_dict["4-1"] = ["power", "cower", "crow", "core", "pore"]

action_dict["4-2"] = ["(unstack o r)", "(stack o e)", "(unstack r w)",
                "(stack r o)", "(unstack p c)", "(stack p r)",
                "(unstack p r)", "(put-down p)", "(unstack r o)",
                "(stack r p)", "(unstack o e)", "(stack o w)",
                "(unstack r p)", "(stack r e)", "(unstack o w)",
                "(stack o r)", "(pick-up p)", "(stack p o)"]
goal_space_dict["4-2"] = ["power", "cower", "crow", "core", "pore"]

action_dict["4-3"] = ["(unstack e d)", "(stack e r)", "(unstack a p)",
                "(stack a e)", "(unstack p w)", "(stack p a)",
                "(unstack p a)", "(put-down p)", "(unstack a e)",
                "(put-down a)", "(unstack e r)", "(stack e d)",
                "(pick-up a)", "(stack a r)", "(unstack e d)",
                "(stack e a)", "(pick-up p)", "(stack p e)"]
goal_space_dict["4-3"] = ["ear", "reap", "pear", "wade", "draw"]

action_dict["4-4"] = ["(unstack p w)", "(stack p e)", "(pick-up a)",
                "(stack a r)", "(pick-up w)", "(stack w a)",
                "(unstack w a)", "(put-down w)", "(unstack a r)",
                "(stack a w)", "(unstack r d)", "(stack r a)",
                "(pick-up d)", "(stack d r)"]
goal_space_dict["4-4"] = ["ear", "reap", "pear", "wade", "draw"]

#
# Tutorial and demo
action_dict["tutorial-demo"]= ["(unstack r d)", "(put-down r)", "(unstack e p)",
                "(stack e r)", "(unstack w a)", "(stack w p)", "(pick-up a)",
                "(stack a e)", "(unstack a e)", "(put-down a)", "(unstack e r)",
                 "(put-down e)", "(pick-up a)", "(stack a r)", "(pick-up e)",
                 "(stack e a)"]
goal_space_dict["tutorial-demo"] = ["ear", "reap", "pear", "wade", "draw"]

action_dict["tutorial-tutorial"]= ["(unstack e o)", "(stack e r)",
                                "(unstack w c)", "(stack w p)", "(unstack w p)",
                                "(stack w e)", "(pick-up o)", "(stack o w)",
                                "(pick-up p)", "(stack p o)"]
goal_space_dict["tutorial-tutorial"] = ["power", "cower", "crow", "core", "pore"]


# Get action list for respective experiment
function get_action(experiment)
        return action_dict[experiment]
end

# Get goal space list for respective experiment
function get_goal_space(experiment)
        return goal_space_dict[experiment]
end
