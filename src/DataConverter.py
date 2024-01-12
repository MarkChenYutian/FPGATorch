import torch

def store_as_matrix(fileName: str, A: torch.Tensor):
    assert len(A.shape) == 3
    with open(fileName, "w") as f:
        f.write("Matrix_Interface\n")
        f.write("Size Information\n")
        f.write(f"{A.shape[0]}\n")
        f.write(f"{A.shape[1]}\n")
        f.write(f"{A.shape[2]}\n")
        f.write("Data\n")
        for i in range(A.shape[0]):
            for j in range(A.shape[1]):
                for k in range(A.shape[2]):
                    f.write(f"{A[i, j, k]}\n")
    return


# for i in range(10):
#     rand_mat = torch.randn((1, 2, 3))
#     store_as_matrix(f"input_{i}.matrix", rand_mat)

store_as_matrix("linear1_weight.matrix", torch.randn(1, 3, 3))
store_as_matrix("linear2_weight.matrix", torch.randn(1, 3, 3))
store_as_matrix("linear1_bias.matrix", torch.randn(1, 1, 3))
store_as_matrix("linear2_bias.matrix", torch.randn(1, 1, 3))

