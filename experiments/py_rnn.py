import torch
import torch.nn as nn
import torch.utils.data as data
import torch.nn.functional as F
import torch.nn.utils.rnn as rnn
import matplotlib.pyplot as plt
import os


def train_lstm(output_directory, domain, train_probs, test_probs,
               goal_dim, x_train, x_test, train_goal_idx_pairs,
               test_goal_idx_pairs, test_optimality):
    y_train = [pair[1] for pair in train_goal_idx_pairs]
    y_test = [pair[1] for pair in test_goal_idx_pairs]

    vec_rep_dim = len(x_train[0][0])
    # TODO: Change to a power of 2 instead
    hidden_dim = vec_rep_dim
    model = LSTM_variable_input(vec_rep_dim, hidden_dim, goal_dim)
    return train_model(model, x_train, x_test, y_train, y_test,
                       output_directory, domain, train_probs, test_probs,
                       train_goal_idx_pairs, test_goal_idx_pairs,
                       test_optimality)


def test_lstm(model, test_dl, sorted_goal_idx_pairs_test):
    all_y_preds = []
    for (x, y, length) in test_dl:
        x = x.float()
        y_pred, all_y_pred, lengths = model(x, length)
        for i, length in enumerate(lengths):
            prob_idx, true_goal, obs_idx = sorted_goal_idx_pairs_test[i]
            for t in range(lengths[i]):
                probs = all_y_pred[i][t]
                all_y_preds.append((prob_idx, obs_idx, true_goal, t, probs.tolist()))
    return all_y_preds


def train_model(model, x_train, x_test, y_train, y_test, directory, domain,
                train_probs, test_probs, train_goal_idx_pairs,
                test_goal_idx_pairs, test_optimality,
                epochs=200, lr=0.001):
    rep_len = len(x_train[0][0])
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
    x_train_padded = pad_sequence(sorted_x_train, x_train_lens, rep_len)
    x_train_tensor = torch.ShortTensor(x_train_padded)

    x_test_lens = [len(x) for x in sorted_x_test]
    x_test_padded = pad_sequence(sorted_x_test, x_test_lens, rep_len)
    x_test_tensor = torch.ShortTensor(x_test_padded)

    train_batch_size = len(y_train)
    train_ds = GoalsDataset((x_train_tensor, x_train_lens), sorted_y_train)
    train_dl = data.DataLoader(train_ds, batch_size=train_batch_size)

    test_batch_size = len(y_test)
    test_ds = GoalsDataset((x_test_tensor, x_test_lens), sorted_y_test)
    test_dl = data.DataLoader(test_ds, batch_size=test_batch_size)

    parameters = filter(lambda p: p.requires_grad, model.parameters())
    optimizer = torch.optim.Adam(parameters, lr=lr)

    all_y_preds_train = []
    all_y_preds_test = []
    train_top1 = None
    train_posterior = None
    test_top1 = None
    test_posterior = None
    for i in range(epochs):
        model.train()
        sum_loss = 0.0
        total = 0
        for x, y, length in train_dl:
            x = x.float()
            y_pred, all_y_pred, lengths = model(x, length)
            optimizer.zero_grad()
            loss = F.cross_entropy(y_pred, y)
            loss.backward()
            optimizer.step()
            sum_loss += loss.item()*y.shape[0]
            total += y.shape[0]
        if i % 50 == 0:
            for x, y, length in train_dl:
                x = x.float()
                y_pred, all_y_pred, lengths = model(x, length)
                for j, length in enumerate(lengths):
                    prob_idx, true_goal, obs_idx = sorted_goal_idx_pairs_train[j]
                    for t in range(lengths[j]):
                        probs = all_y_pred[j][t]
                        all_y_preds_train.append((prob_idx, i, obs_idx, true_goal, t, probs.tolist()))
            for x, y, length in test_dl:
                x = x.float()
                y_pred, all_y_pred, lengths = model(x, length)
                for j, length in enumerate(lengths):
                    prob_idx, true_goal, obs_idx = sorted_goal_idx_pairs_test[j]
                    for t in range(lengths[j]):
                        probs = all_y_pred[j][t]
                        all_y_preds_test.append((prob_idx, i, obs_idx, true_goal, t, probs.tolist()))
        # top1_correct_train, posterior_correct_train = prop_correct(model, train_dl)
        # top1_correct_test, posterior_correct_test = prop_correct(model, test_dl)
        if i == epochs - 1:
            train_top1, train_posterior = prop_correct(model, train_dl)
            test_top1, test_posterior = prop_correct(model, test_dl)
        # if i % 10 == 0:
        #     print("train loss %.3f, train Top-1 accuracy %.3f, train posterior\
        #        accuracy %.3f, test Top-1 accuracy %.3f, test posterior\
        #        accuracy %.3f" % (sum_loss/total, top1_correct_train,
        #                          posterior_correct_train, top1_correct_test,
        #                         posterior_correct_test))
    #plot_predictions(model, test_dl, directory, domain, train_probs,
    #                 test_probs, sorted_goal_idx_pairs_test, test_optimality)
    return model, test_dl, sorted_goal_idx_pairs_test, all_y_preds_train, all_y_preds_test, train_top1, train_posterior, test_top1, test_posterior


def pad_sequence(sorted_x, x_lens, rep_len):
    x_padded = []
    const_len = x_lens[0]
    pad_val = [0 for i in range(rep_len)]
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
    for (x, y, length) in dl:
        x = x.float()
        y_pred, all_y_pred, lengths = model(x, length)
        pred_prob, pred_idx = torch.max(y_pred, 1)
        top1_correct += (pred_idx == y).float().sum()
        posterior_correct += (pred_prob > 0.99).float().sum()
        total += y.shape[0]
    return top1_correct/total, posterior_correct/total


def plot_predictions(model, test_dl, directory, domain,
                     train_probs, test_probs, sorted_goal_idx_pairs_test,
                     test_optimality):
    plot_dir_path = generate_plot_path(directory, domain,
                                       train_probs, test_probs,
                                       test_optimality)
    for (x, y, length) in test_dl:
        x = x.float()
        y_pred, all_y_pred, lengths = model(x, length)
        num_goals = len(all_y_pred[0][0])
        for i, length in enumerate(lengths):
            true_goal, idx = sorted_goal_idx_pairs_test[i]
            y_pred_i = all_y_pred[i]

            for j in range(num_goals):
                plt.plot([y_pred_i[k][j] for k in range(length)],
                         label="Goal " + str(j))

            plt.title('True Goal=' + str(true_goal) + ', Test Sample Index=' + str(idx))
            plt.xlabel('Timestep')
            plt.ylabel('Probability of Goal')
            plt.legend()
            plt.axis([0, length-1, 0, 1])
            plt.savefig(os.path.join(plot_dir_path, str(i) + ".jpg"))
            plt.cla()


def generate_plot_path(directory, domain, train_probs, test_probs,
                       test_optimality):
    train_prob_str = ""
    test_prob_str = ""
    for i in train_probs:
        train_prob_str += str(i)
    for i in test_probs:
        test_prob_str += str(i)
    return os.path.join(directory, domain, test_optimality,
                        "train_problem" + train_prob_str,
                        "test_problem" + test_prob_str)


class GoalsDataset(data.Dataset):
    def __init__(self, X, Y):
        self.X = X
        self.y = Y

    def __len__(self):
        length = len(self.y)
        return length

    def __getitem__(self, idx):
        item = self.X[0][idx], self.y[idx], self.X[1][idx]
        return item


class LSTM_variable_input(nn.Module):
    def __init__(self, vec_rep_dim, hidden_dim, goal_count):
        super().__init__()
        self.hidden_dim = hidden_dim
        self.lstm = nn.LSTM(vec_rep_dim, hidden_dim, batch_first=True)
        self.linear = nn.Linear(hidden_dim, goal_count)

    def forward(self, x, s):
        packed = rnn.pack_padded_sequence(x, s, batch_first=True)
        out, (ht, ct) = self.lstm(packed)

        # Get final timestep output for all samples
        out_final_unnorm = self.linear(ht[0])
        out_final = F.softmax(out_final_unnorm)

        # Get output from all timesteps for all samples
        all_out, lengths = rnn.pad_packed_sequence(out, batch_first=True)
        all_out_unnorm = self.linear(all_out)
        all_out = F.softmax(all_out_unnorm, dim=2)

        return out_final, all_out, lengths
