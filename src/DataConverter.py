import torch
from tqdm import tqdm

def store_as_matrix(A: torch.Tensor):
    assert len(A.shape) == 3
    string = f"{A.shape[0]} {A.shape[1]} {A.shape[2]} >DATA_BEGIN< "
    for i in range(A.shape[0]):
        for j in range(A.shape[1]):
            for k in range(A.shape[2]):
                string += f"{A[i, j, k]} "
    return string


def convert_from_csv(csv_name: str):
    value_lines = []
    label_lines = []
    with open(csv_name, "r") as f:
        lines = f.read().strip().split("\n")
    for line in tqdm(lines):
        tokens = list(map(int, line.split(",")))
        label = tokens[0]
        value_tensor: torch.Tensor = (torch.tensor(tokens[1:], dtype=torch.float) / 255.) - 0.5
        value_tensor = value_tensor.unsqueeze(0).unsqueeze(0)
        label_tensor = torch.zeros((1, 1, 10))
        label_tensor[..., label] = 1.
        value_lines.append(store_as_matrix(value_tensor))
        label_lines.append(store_as_matrix(label_tensor))
    with open("label.csv", "w") as f:
        for line in label_lines: f.write(line + "\n")
    with open("value.csv", "w") as f:
        for line in value_lines: f.write(line + "\n")

# for i in range(10):
#     rand_mat = torch.randn((1, 2, 3))
#     store_as_matrix(f"input_{i}.matrix", rand_mat)

# store_as_matrix("linear1_weight.matrix", torch.randn(1, 3, 3))
# store_as_matrix("linear2_weight.matrix", torch.randn(1, 3, 3))
# store_as_matrix("linear1_bias.matrix", torch.randn(1, 1, 3))
# store_as_matrix("linear2_bias.matrix", torch.randn(1, 1, 3))

convert_from_csv("../data/mnist_train.csv")

