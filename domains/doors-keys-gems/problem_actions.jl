#=
POSSIBLE ACTIONS
    (pickup item)
        item is key, gem
        item must exist at current position
    (unlock key dir)
        dir is up, down, left, right
        key must be in possession
        door must exist at position+dir
    (up)
    (down)
    (right)
    (left)
=#

# Dictionary of Actions
action_dict = Dict()

action_dict["2-sub-0"] = ["(down)", "(down)", "(right)", "(right)",
                        "(up)", "(up)", "(pickup key1)", "(up)", "(up)",
                        "(unlock key1 right)", "(right)", "(right)",
                        "(down)", "(down)", "(down)", "(pickup gem1)" ]

action_dict["2-sub-1"] = ["(down)", "(down)", "(right)", "(right)",
                        "(up)", "(up)", "(pickup key1)", "(up)", "(down)",
                        "(down)", "(down)", "(unlock key1 right)",
                        "(right)", "(right)", "(up)", "(pickup gem1)" ]


action_dict["3-sub-0"] = ["(right)", "(right)", "(right)", "(up)",
                        "(up)", "(left)", "(left)", "(left)",
                        "(up)", "(up)", "(up)", "(up)", "(up)",
                        "(pickup gem1)"]


action_dict["3-sub-0"] = ["(right)", "(right)", "(right)", "(up)",
                        "(up)", "(left)", "(left)", "(left)",
                        "(up)", "(up)", "(up)", "(up)", "(up)",
                        "(pickup gem1)"]

# Get action list for respective experiment
function get_action(experiment)
        return action_dict[experiment]
end
