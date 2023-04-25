"Converts an (x, y) position to a corresponding goal term."
pos_to_terms(pos::Tuple{Int, Int}) =
    [parse_pddl("(== (xpos) $(pos[1]))"), parse_pddl("(== (ypos) $(pos[2]))")]

"Converts a goal term to an (x, y) position."
goal_to_pos(term::Term) =
    (term.args[1].args[2].name, term.args[2].args[2].name)
