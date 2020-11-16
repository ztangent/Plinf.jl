# hardcoded experiment sequences

#experiment 3- Moving irrelevant blocks
a  = :a
b = :b

pickupA = Compound(Symbol("pick-up"), @julog Term[a])
putdownA = Compound(Symbol("put-down"), @julog Term[a])
stackA = @julog stack(a, b)
unstackA = @julog unstack(a, b)

pickupB = Compound(Symbol("pick-up"), @julog Term[b])
putdownB = Compound(Symbol("put-down"), @julog Term[b])
stackB = @julog stack(b, a)
unstackB = @julog unstack(b, a)

state1 = execute(pickupA, state, domain)
state2 = execute(stackA, state1, domain)
state3 = execute(unstackA, state2, domain)
state4 = execute(putdownA, state3, domain)
state5 = execute(pickupB, state4, domain)
state6 = execute(stackB, state5, domain)
state7 = execute(unstackB, state6, domain)
state8 = execute(putdownB, state7, domain)
traj1 = [state, state1, state2, state3, state4, state5, state6, state7, state8]
