import torch
import torch.nn as nn
import torch.utils.data as data
import torch.nn.functional as F
import torch.nn.utils.rnn as rnn


def train_lstm(goal_dim, x_train, x_test, train_goal_idx_pairs,
               test_goal_idx_pairs):
    y_train = [pair[1] for pair in train_goal_idx_pairs]
    y_test = [pair[1] for pair in test_goal_idx_pairs]

    model = LSTM_conv_array_vector(goal_dim)
    return train_model(model, x_train, x_test, y_train, y_test,
                       train_goal_idx_pairs, test_goal_idx_pairs)


def test_lstm(model, test_dl, sorted_goal_idx_pairs_test):
    all_y_preds = []
    for x_mat, x_vec, y, length in test_dl:
        x_mat, x_vec = x_mat.float(), x_vec.float()
        y_pred, all_y_pred, lengths, cnn = model(x_mat, x_vec, length)
        for i, length in enumerate(lengths):
            prob_idx, true_goal, obs_idx = sorted_goal_idx_pairs_test[i]
            #for t in range(x_mat.size()[1]):
            for t in range(lengths[i]):
                probs = all_y_pred[i][t]
                all_y_preds.append((prob_idx, obs_idx, true_goal, t, probs.tolist()))
    return all_y_preds


def train_model(model, x_train, x_test, y_train, y_test, train_goal_idx_pairs,
                test_goal_idx_pairs, epochs=400, lr=0.001):
    sorted_train_pairs = sorted(zip(x_train, y_train, train_goal_idx_pairs),
                                key=lambda pair: len(pair[0]), reverse=True)
    sorted_y_train = [y for (x, y, pairs) in sorted_train_pairs]
    sorted_x_train = [x for (x, y, pairs) in sorted_train_pairs]
    sorted_goal_idx_pairs_train = [pairs for (x, y, pairs) in sorted_train_pairs]

    sorted_test_pairs = sorted(zip(x_test, y_test, test_goal_idx_pairs),
                               key=lambda pair: len(pair[0]), reverse=True)
    sorted_y_test = [y for (x, y, pairs) in sorted_test_pairs]
    sorted_x_test = [x for (x, y, pairs) in sorted_test_pairs]
    sorted_goal_idx_pairs_test = [pairs for (x, y, pairs) in sorted_test_pairs]

    x_train_lens = [len(x) for x in sorted_x_train]
    x_train_padded = pad_sequence(sorted_x_train, x_train_lens)
    x_train_padded_matrix = [[x_train[0] for x_train in x_trains] for x_trains in x_train_padded]
    x_train_padded_vector = [[x_train[1] for x_train in x_trains] for x_trains in x_train_padded]
    x_train_matrix_tensor = torch.ShortTensor(x_train_padded_matrix)
    x_train_vector_tensor = torch.ShortTensor(x_train_padded_vector)

    x_test_lens = [len(x) for x in sorted_x_test]
    x_test_padded = pad_sequence(sorted_x_test, x_test_lens)
    x_test_padded_matrix = [[x_test[0] for x_test in x_tests] for x_tests in x_test_padded]
    x_test_padded_vector = [[x_test[1] for x_test in x_tests] for x_tests in x_test_padded]
    x_test_matrix_tensor = torch.ShortTensor(x_test_padded_matrix)
    x_test_vector_tensor = torch.ShortTensor(x_test_padded_vector)

    train_batch_size = len(y_train)
    train_ds = GoalsDataset((x_train_matrix_tensor, x_train_vector_tensor, x_train_lens), sorted_y_train)
    train_dl = data.DataLoader(train_ds, batch_size=train_batch_size)

    test_batch_size = len(y_test)
    test_ds = GoalsDataset((x_test_matrix_tensor, x_test_vector_tensor, x_test_lens), sorted_y_test)
    test_dl = data.DataLoader(test_ds, batch_size=test_batch_size)

    parameters = filter(lambda p: p.requires_grad, model.parameters())
    optimizer = torch.optim.Adam(parameters, lr=lr)

    all_y_preds_train = []
    all_y_preds_test = []
    train_top1 = None
    train_posterior = None
    test_top1 = None
    test_posterior = None
    #last_cnn = torch.zeros(train_batch_size, x_train_lens[0], 64)
    for i in range(epochs):
        model.train()
        sum_loss = 0.0
        total = 0
        for x_mat, x_vec, y, length in train_dl:
            x_mat, x_vec = x_mat.float(), x_vec.float()
            y_pred, all_y_pred, lengths, cnn = model(x_mat, x_vec, length)
            #print(abs(last_cnn-cnn))
            #print(torch.sum(abs(last_cnn-cnn)))
            #last_cnn = cnn
            optimizer.zero_grad()
            loss = F.cross_entropy(y_pred, y)
            loss.backward()
            optimizer.step()
            sum_loss += loss.item()*y.shape[0]
            total += y.shape[0]
        if i % 50 == 0:
            # top1_correct_train, posterior_correct_train = prop_correct(model, train_dl)
            # top1_correct_test, posterior_correct_test = prop_correct(model, test_dl)
            # print("train loss %.3f, train Top-1 accuracy %.3f, train posterior\
            #         accuracy %.3f, test Top-1 accuracy %.3f, test posterior\
            #         accuracy %.3f" % (sum_loss/total, top1_correct_train,
            #                           posterior_correct_train, top1_correct_test,
            #                           posterior_correct_test))
            for x_mat, x_vec, y, length in train_dl:
                x_mat, x_vec = x_mat.float(), x_vec.float()
                y_pred, all_y_pred, lengths, cnn = model(x_mat, x_vec, length)
                for j, length in enumerate(lengths):
                    prob_idx, true_goal, obs_idx = sorted_goal_idx_pairs_train[j]
                    for t in range(lengths[j]):
                        probs = all_y_pred[j][t]
                        all_y_preds_train.append((prob_idx, i, obs_idx, true_goal, t, probs.tolist()))
            for x_mat, x_vec, y, length in test_dl:
                x_mat, x_vec = x_mat.float(), x_vec.float()
                y_pred, all_y_pred, lengths, cnn = model(x_mat, x_vec, length)
                for j, length in enumerate(lengths):
                    prob_idx, true_goal, obs_idx = sorted_goal_idx_pairs_test[j]
                    for t in range(lengths[j]):
                        probs = all_y_pred[j][t]
                        all_y_preds_test.append((prob_idx, i, obs_idx, true_goal, t, probs.tolist()))
        if i == epochs - 1:
            train_top1, train_posterior = prop_correct(model, train_dl)
            test_top1, test_posterior = prop_correct(model, test_dl)
        # if i % 10 == 0:
        #     top1_correct_train, posterior_correct_train = prop_correct(model, train_dl)
        #     top1_correct_test, posterior_correct_test = prop_correct(model, test_dl)
        #     print("train loss %.3f, train Top-1 accuracy %.3f, train posterior\
        #        accuracy %.3f, test Top-1 accuracy %.3f, test posterior\
        #        accuracy %.3f" % (sum_loss/total, top1_correct_train,
        #                          posterior_correct_train, top1_correct_test,
        #                         posterior_correct_test))
    #plot_predictions(model, test_dl, directory, domain, train_probs,
    #                 test_probs, sorted_goal_idx_pairs_test, test_optimality)
    return model, test_dl, sorted_goal_idx_pairs_test, all_y_preds_train, all_y_preds_test, train_top1, train_posterior, test_top1, test_posterior


def pad_sequence(sorted_x, x_lens):
    x_padded = []
    const_len = x_lens[0]
    pad_val0 = [16 * [0] for i in range(16)]
    pad_val1 = 10 * [0]
    pad_val = (pad_val0, pad_val1)
    for i, length in enumerate(x_lens):
        padded_seq = sorted_x[i]
        for j in range(const_len - length):
            padded_seq.append(pad_val)
        x_padded.append(padded_seq)
    return x_padded


def prop_correct(model, dl):
    top1_correct = 0
    posterior_correct = 0
    total = 0
    for x_mat, x_vec, y, length in dl:
        x_mat, x_vec = x_mat.float(), x_vec.float()
        y_pred, all_y_pred, lengths, cnn = model(x_mat, x_vec, length)
        pred_prob, pred_idx = torch.max(y_pred, 1)
        top1_correct += (pred_idx == y).float().sum()
        posterior_correct += ((pred_prob > 0.99) & (pred_idx == y)).float().sum()
        total += y.shape[0]
    return top1_correct/total, posterior_correct/total


class GoalsDataset(data.Dataset):
    def __init__(self, X, Y):
        self.X = X
        self.y = Y

    def __len__(self):
        length = len(self.y)
        return length

    def __getitem__(self, idx):
        item = self.X[0][idx], self.X[1][idx], self.y[idx], self.X[2][idx]
        return item


class LSTM_conv_array_vector(nn.Module):
    def __init__(self, goal_count):
        super().__init__()
        flattened_array_size = 64
        vector_size = 10
        linear_len = flattened_array_size + vector_size
        self.hidden_dim = flattened_array_size
        self.layer1 = nn.Sequential(
            nn.Conv2d(1, 4, kernel_size=2, stride=2),
            nn.ReLU())
        #nn.MaxPool2d(kernel_size=2, stride=2))
        self.layer2 = nn.Sequential(
            nn.Conv2d(4, 4, kernel_size=3, stride=1, padding=1),
            nn.ReLU())
        #nn.MaxPool2d(kernel_size=2, stride=2))
        self.layer3 = nn.Sequential(
            nn.Conv2d(4, 4, kernel_size=2, stride=2),
            nn.ReLU())
        #nn.MaxPool2d(kernel_size=2, stride=2))
        self.drop_out = nn.Dropout()
        self.lstm = nn.LSTM(linear_len, flattened_array_size, batch_first=True)
        self.linear = nn.Linear(flattened_array_size, goal_count)

    def CNN(self, x_mat):
        out = self.layer1(x_mat)
        # if x_mat[0, 0, 1, 1] != 0:
        #     print(out[0, :, ])
        out = self.layer2(out)
        out = self.layer3(out)
        out = torch.flatten(out, start_dim=1)
        return out

    def forward(self, x_mat, x_vec, s):
        x_mat = torch.unsqueeze(x_mat, 2)
        packed = rnn.pack_padded_sequence(x_mat, s, batch_first=True)
        out = [self.CNN(torch.unsqueeze(x_i, 0)) for x_i in packed.data]
        new_packed = rnn.PackedSequence(out, packed.batch_sizes, packed.sorted_indices, packed.unsorted_indices)
        #out = torch.unbind(x_mat, dim=1)
        #out = [self.CNN(torch.unsqueeze(x_i, 1)) for x_i in out]
        cnn = self.CNN(new_packed)
        # for i in range(1, len(out)):
        #     print(i)
        #     print(torch.sum(abs(out[i] - out[i-1])))
        #cnn = torch.stack(out, dim=1)

        out = rnn.pad_packed_sequence(cnn, batch_first=True)
        out = torch.cat((out, x_vec), axis=2)
        packed = rnn.pack_padded_sequence(out, s, batch_first=True)
        out, (ht, ct) = self.lstm(out)

        # Get final timestep output for all samples
        out_final_unnorm = self.linear(ht[0])
        out_final = F.softmax(out_final_unnorm)

        # Get output from all timesteps for all samples
        all_out, lengths = rnn.pad_packed_sequence(out, batch_first=True)
        all_out_unnorm = self.linear(all_out)
        all_out = F.softmax(all_out_unnorm, dim=2)

        return out_final, all_out, lengths, cnn
