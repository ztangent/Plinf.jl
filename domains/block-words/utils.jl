using PDDL

function word_to_terms(word::String)
    top = Const(Symbol(word[1]))
    bottom = Const(Symbol(word[end]))
    terms = Term[Compound(:clear, [top]), Compound(:ontable, [bottom])]
    for (c1, c2) in zip(word[1:end-1], word[2:end])
        c1, c2 = Const(Symbol(c1)), Const(Symbol(c2))
        push!(terms, Compound(:on, [c1, c2]))
    end
    return terms
end
