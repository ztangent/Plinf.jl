using PyCall
torch = pyimport("torch")
np = pyimport("numpy")
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
    ordered_objects = sort([term.args[1].name for term in types])
    ordered_fluents = sort(collect(keys(fluents)))

    pred_start_idxs = calculate_vector_sublengths(predtypes, ordered_predicates,
                                                  type_counts)
    vec_len = pred_start_idxs[length(pred_start_idxs)] + length(ordered_fluents) - 1
    encoding = zeros(vec_len)
    for fact in facts
        # excluding eq
        if fact.name in ordered_predicates
            base_idx = pred_start_idxs[findfirst(isequal(fact.name), ordered_predicates)]
        else
            continue
        end
        idx = set_bools(fact, base_idx, ordered_objects, type_map, type_counts, predtypes)
        encoding[idx] = 1
    end
    for (fluent, val) in fluents
        idx += 1
        encoding[idx] = val
    end
    return encoding
end

# TODO: generalize from just doors-keys-gems
# TODO: generalize to variable number of gems
"Convert from gems, keys, doors PDDL state representation to RNN input representation"
function gems_keys_doors_RNN_conversion(domain::Domain, state::State)
    types = state.types
    facts = state.facts
    fluents = state.fluents
    objects = sort([type.args[1].name for type in types if type.name != :direction])
    width, height = fluents[:width], fluents[:height]
    gem_vals = Dict(:gem1 => 11, :gem2 => 13, :gem3 => 17)
    encoding_array = zeros(16, 16)
    for i=1:height, j=1:width
        encoding_array[i, j] = 1
    end
    encoding_vector = zeros(10)
    for fact in facts
        if fact.name == :wall
            val = 3
            x, y = fact.args
        elseif fact.name == :door
            val = 5
            x, y = fact.args
        elseif fact.name == :at
            item, x, y = fact.args
            if startswith(String(item.name), "key")
                val = 7
            else
                val = gem_vals[item.name]
            end
        elseif fact.name == :has
            items = fact.args
            for item in items
                obj_idx = findfirst(isequal(item.name), objects)
                encoding_vector[obj_idx] = 1
            end
            continue
        elseif fact.name == :doorloc || fact.name == :itemloc
            continue
        end
        y, x = y.name, x.name
        encoding_array[height - y + 1, x] *= val
    end
    agent_x, agent_y = fluents[:xpos], fluents[:ypos]
    encoding_array[height - agent_y + 1, agent_x] *= 2
    return encoding_array, encoding_vector
end

"Inspired by https://jovian.ml/aakanksha-ns/lstm-multiclass-text-classification/."
@pydef mutable struct GoalsDataset <: data.Dataset
    function __init__(self, X, Y)
        self.X = X
        self.y = Y
    end

    function __len__(self)
        l = length(self.y)
        return l
    end

    function __getitem__(self, idx)
        #println(torch.from_numpy(np.asarray(self.X[2][idx+1], dtype=np.long)))
        item = torch.from_numpy(np.asarray(self.X[1][idx+1], dtype=np.float32)), self.y[idx+1, :], torch.from_numpy(np.asarray(self.X[2][idx+1], dtype=np.long))
        return item
    end
end

"state_seqs is a list of sequences of states in a corresponding list of
observations, and goals is a list of the corresponding goal indices for those
observations."
function train_and_test_lstm(domain, observations, fnames, poss_goals)
    println(length(poss_goals))
    goal_dim = length(poss_goals)
    # TODO: Change to accept blocks-word or grid-world
    x_train = [[block_words_RNN_conversion(domain, state) for state in observation] for observation in observations]
    y_train = getindex.(get_idx_from_fn.(fnames), 1)

    println("y_train")
    println(y_train)

    vec_rep_dim = length(x_train[1][1])
    # TODO: Change to a power of 2 instead
    hidden_dim = vec_rep_dim
    model = LSTM_variable_input(vec_rep_dim, hidden_dim, goal_dim)
    train_model(model, x_train, y_train)
end

"Inspired by https://jovian.ml/aakanksha-ns/lstm-multiclass-text-classification/."
function train_model(model, x_train, y_train, batch_size=20, epochs=100, lr=0.001)
    rep_len = length(x_train[1][1])
    sorted_x_train = sort(x_train, by=length, rev=true)
    x_train_lens = length.(sorted_x_train)
    x_train_padded = []
    const_len = x_train_lens[1]
    pad_val = [0 for i=1:rep_len]
    for (i, len) in enumerate(x_train_lens)
        padded_seq = sorted_x_train[i]
        for j=1:const_len - len
            push!(padded_seq, pad_val)
        end
        push!(x_train_padded, padded_seq)
    end

    x_train_tensor = torch.ShortTensor(x_train_padded)
    train_ds = GoalsDataset((x_train_tensor, x_train_lens), y_train)
    train_dl = data.DataLoader(train_ds, batch_size=batch_size)

    parameters = pybuiltin(:filter)(p->p.requires_grad, model.parameters())
    optimizer = torch.optim.Adam(parameters, lr=lr)

    for i in 1:epochs
        model.train()
        sum_loss = 0.0
        total = 0
        for (x, y, l) in train_dl
            l = l.long()
            y_pred = model(x, l)
            optimizer.zero_grad()
            loss = F.cross_entropy(y_pred, y[1])
            loss.backward()
            optimizer.step()
            sum_loss += loss.item()*y.shape[1]
            total += y.shape[1]
        end
        correct = count_correct(model, train_dl).item()
        println(correct/total)
        println("train loss $(sum_loss/total), train accuracy $(correct/total)")
    end
end

function count_correct(model, train_dl)
    correct = 0
    for (x, y, l) in train_dl
        l = l.long()
        y_pred = model(x, l)
        pred = torch.argmax(y_pred)
        correct += pred == y
    end
    return correct
end

"Inspired by https://jovian.ml/aakanksha-ns/lstm-multiclass-text-classification/."
@pydef mutable struct LSTM_variable_input <: nn.Module
    function __init__(self, vec_rep_dim, hidden_dim, goal_count)
        pybuiltin(:super)(LSTM_variable_input, self).__init__()
        self.hidden_dim = hidden_dim
        self.lstm = nn.LSTM(vec_rep_dim, hidden_dim, batch_first=true)
        self.linear = nn.Linear(hidden_dim, goal_count)
    end

    function forward(self, x, l)
        #println(l)
        packed = rnn.pack_padded_sequence(x, l, batch_first=true)
        println(typeof(packed))
        input, batch_sizes, sorted_indices, unsorted_indices = packed
        println(batch_sizes)
        #println(size(packed[2]))
        out, (ht, ct) = self.lstm(packed)
        println(3)
        out_unnorm = self.linear(ht[1, length(ht)])
        println(4)
        out = F.softmax(out_unnorm)
        println(5)
        return torch.unsqueeze(out, 0)
    end
end
