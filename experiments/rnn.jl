torch = pyimport("torch")
nn = torch.nn
rnn = nn.utils.rnn
F = nn.functional
data = torch.utils.data

function get_arg_dims(argtypes, type_counts)
    dims = []
    for (i, argtype) in enumerate(argtypes)
        # Assuming one object can't be passed as multiple inputs to a predicate
        dim = type_counts[argtype] - count(isequal(argtype), argtypes[1:i-1])
        push!(dims, dim)
    end
    return dims
end

#= Within the ordered objects, finds the index position of the given object among
the other objects of the given type =#
function get_object_type_index(ordered_objects, type_map, type, object_name)
    count = 1
    for object in ordered_objects
        if object == object_name
            return count
        end
        if type_map[object] == type
            count += 1
        end
    end
    return nothing
end

function calculate_vector_sublengths(predtypes, predicate_names, type_counts)
    vec_sublens = [1]
    for name in predicate_names
        argtypes = predtypes[name]
        # Making a single boolean if the predicate takes no arguments
        if length(argtypes) == 0
            dims = [1]
        else
            dims = get_arg_dims(argtypes, type_counts)
        end

        push!(vec_sublens, vec_sublens[length(vec_sublens)] + prod(dims))
    end
    return vec_sublens
end

function set_bools(fact::Compound, base_idx, ordered_objects, type_map, type_counts, predtypes)
    args = fact.args
    argtypes = predtypes[fact.name]
    ordered_object_types = [type_map[obj_name] for obj_name in ordered_objects]
    arg_order_idxs = [findfirst(isequal(arg.name), ordered_objects) for arg in args]
    num_args = length(args)
    idx = base_idx
    terms = []
    for (i, arg) in enumerate(args)
        object_name = arg.name
        type = type_map[object_name]
        baseline = get_object_type_index(ordered_objects, type_map, type, object_name)
        # Get the number of other args of the same type and prior to the current
        # arg alphabetically before the current arg in order of the ordered objects
        repeat_count = 0
        for (j, arg_order_idx) in enumerate(arg_order_idxs[1:i-1])
            if type_map[args[j].name] == type && arg_order_idx < arg_order_idxs[i]
                repeat_count += 1
            end
        end
        #repeat_count = count(isequal(type), ordered_object_types[1:args_ordered_idx-1])
        push!(terms, baseline - repeat_count)
    end
    for (i, term) in enumerate(terms)
        dims = get_arg_dims(argtypes, type_counts)
        remaining = dims[i+1:length(dims)]
        multiplicand = 1
        if length(remaining) != 0
            multiplicand = prod(remaining)
        end
        idx += (term - 1) * multiplicand
    end
    return idx
end

function set_bools(fact::Const, base_idx, ordered_objects, type_map, type_counts, predtypes)
    return base_idx
end

"Convert from block-words PDDL state representation to RNN input representation"
function block_words_RNN_conversion(domain::Domain, state::State)
    predicates, predtypes, fluents = domain.predicates, domain.predtypes, domain.functions
    types, facts = state.types, state.facts

    # Map each object name to its type name
    type_map = Dict(term.args[1].name => term.name for term in types)

    # Get the number of each type of object
    type_counts = Dict(type.name => 0 for type in types)
    for type in types
        type_counts[type.name] += 1
    end

    # Alphabetized names of predicates, objects, and fluents
    ordered_predicates = sort(collect(keys(predicates)))
    println(ordered_predicates)
    ordered_objects = sort([term.args[1].name for term in types])
    println(ordered_objects)
    ordered_fluents = sort(collect(keys(fluents)))

    pred_start_idxs = calculate_vector_sublengths(predtypes, ordered_predicates,
                                                  type_counts)
    vec_len = pred_start_idxs[length(pred_start_idxs)] + length(ordered_fluents) - 1
    encoding = zeros(vec_len)
    for fact in facts
        println(fact)
        base_idx = pred_start_idxs[findfirst(isequal(fact.name), ordered_predicates)]
        idx = set_bools(fact, base_idx, ordered_objects, type_map, type_counts, predtypes)
        println(idx)
        encoding[idx] = 1
    end
    for (fluent, val) in fluents
        idx += 1
        encoding[idx] = val
    end
    return encoding
end

"Convert from gems, keys, doors PDDL state representation to RNN input representation"
function gems_keys_doors_RNN_conversion(state::State)
    encoding = []
    types = state.types
    facts = state.facts
    fluents = state.fluents
    return encoding
end

"Inspired by https://jovian.ml/aakanksha-ns/lstm-multiclass-text-classification/."
@pydef mutable struct GoalsDataset <: data.Dataset
    function __init__(self, X, Y)
        self.X = X
        self.y = Y
    end

    function __len__(self)
        return len(self.y)
    end

    function __getitem__(self, idx)
        return torch.from_numpy(self.X[idx][0].astype(np.int32))
    end
end

"state_seqs is a list of sequences of states in a corresponding list of
observations, and goals is a list of the corresponding goal indices for those
observations."
function train_lstm(domain, observations, fnames, poss_goals)
    # TODO: Change to accept blocks-word or grid-world
    x_train = [[block_words_RNN_conversion(domain, state) for state in observation] for observation in observations]
    y_train = getindex.(get_idx_from_fn.(fnames), 2)
    vec_rep_dim = length(x_train[1][1])
    # TODO: Change to a power of 2 instead
    hidden_dim = vec_rep_dim
    goal_dim = length(poss_goals)
    model = LSTM_variable_input(vec_rep_dim, hidden_dim, goal_count)
    train_model(model, x_train, y_train)
end

"Inspired by https://jovian.ml/aakanksha-ns/lstm-multiclass-text-classification/."
function train_model(model, x_train, y_train, epochs=10, lr=0.001):
    train_ds = GoalsDataset(x_train, y_train)
    train_dl = data.DataLoader(train_ds, batch_size=batch_size, shuffle=True)

    parameters = filter(lambda p: p.requires_grad, model.parameters())
    optimizer = torch.optim.Adam(parameters, lr=lr)

    for i in range(epochs):
        model.train()
        sum_loss = 0.0
        total = 0
        for x, y, l in train_dl:
            x = x.long()
            y = y.long()
            y_pred = model(x, l)
            optimizer.zero_grad()
            loss = F.cross_entropy(y_pred, y)
            loss.backward()
            optimizer.step()
            sum_loss += loss.item()*y.shape[1]
            total += y.shape[1]
        if i % 5 == 1:
            print("train loss $(sum_loss/total), val loss $val_loss, val accuracy $val_acc, and val rmse $val_rmse")

"Inspired by https://jovian.ml/aakanksha-ns/lstm-multiclass-text-classification/."
@pydef mutable struct LSTM_variable_input <: nn.Module
    function __init__(self, vec_rep_dim, hidden_dim, goal_count)
        super().__init__()
        self.hidden_dim = hidden_dim
        self.lstm = nn.LSTM(vec_rep_dim, hidden_dim, batch_first=True)
        self.linear = nn.Linear(hidden_dim, goal_count)
    end

    function forward(self, xs):
        out_pack, (ht, ct) = self.lstm(xs)
        out_unnorm = self.linear(ht[-1])
        out = F.Softmax(out_unnorm)
        return out
    end
end
