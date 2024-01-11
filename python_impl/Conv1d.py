# Do not import any additional 3rd party external libraries as they will not
# be available to AutoLab and are not needed (or allowed)

import numpy as np
from resampling import Downsample1d


def sliding_window_view(x, w_shape, axises):
    x_shape = [dim for dim in x.shape]
    for axis, dim in zip(axises, w_shape):
        x_shape[axis] = x_shape[axis] - dim + 1

    out_shape = x_shape + list(w_shape)
    out_strides = x.strides + tuple(x.strides[axis] for axis in axises)
    return np.lib.stride_tricks.as_strided(x, strides=out_strides, shape=out_shape, writeable=False)


class Conv1d_stride1:
    def __init__(self, in_channels, out_channels, kernel_size,
                 weight_init_fn=None, bias_init_fn=None):
        # Do not modify this method
        self.in_channels = in_channels
        self.out_channels = out_channels
        self.kernel_size = kernel_size

        if weight_init_fn is None:
            self.W = np.random.normal(
                0, 1.0, (out_channels, in_channels, kernel_size))
        else:
            self.W = weight_init_fn(out_channels, in_channels, kernel_size)

        if bias_init_fn is None:
            self.b = np.zeros(out_channels)
        else:
            self.b = bias_init_fn(out_channels)

        self.dLdW = np.zeros(self.W.shape)
        self.dLdb = np.zeros(self.b.shape)
        self.A = None

    def forward(self, A):
        """
        Argument:
            A (np.array): (batch_size, in_channels, input_size)
        Return:
            Z (np.array): (batch_size, out_channels, output_size)
        """
        self.A = A
        # A_stride (np.array): (batch_size, in_channels, window_count, kernel_size)
        # W (np.array): (out_channel, in_channel, kernel_size)
        A_stride = sliding_window_view(A, (self.kernel_size,), (2,))
        # b: batch, i: in_channel, w: window, k: kernel_size, o: out_channel
        Z = np.einsum("biwk,oik->bow", A_stride, self.W)
        Z = Z + self.b[np.newaxis, :, np.newaxis]

        # print("-->", A.shape, self.W.shape, "=>", Z.shape)

        return Z

    def backward(self, dLdZ):
        """
        Argument:
            dLdZ (np.array): (batch_size, out_channels, output_size)
        Return:
            dLdA (np.array): (batch_size, in_channels, input_size)
        """
        dLdZ_stride = np.pad(dLdZ, [(0,), (0,), (self.kernel_size - 1,)], "constant", constant_values=0)

        # Calculating dLdZ
        # dLdZ_stride (np.array): (batch_size, out_channels, window_count, kernel_size)
        # kernel (np.array): (out_channel, in_channel, kernel_size)
        dLdZ_stride = sliding_window_view(dLdZ_stride, (self.kernel_size,), (2,))
        kernel = np.flip(self.W, axis=2)
        dLdA = np.einsum("bowk,oik->biw", dLdZ_stride, kernel)

        # Calculating dLdW
        A_stride = sliding_window_view(self.A, (dLdZ.shape[2],), (2,))
        self.dLdW = np.einsum("biks,bos->oik", A_stride, dLdZ)

        # Calculating dLdb
        self.dLdb = np.einsum("bos->o", dLdZ)

        return dLdA


class Conv1d:
    def __init__(self, in_channels, out_channels, kernel_size, stride,
                 weight_init_fn=None, bias_init_fn=None):
        # Do not modify the variable names

        self.stride = stride

        # Initialize Conv1d() and Downsample1d() isntance
        self.conv1d_stride1 = Conv1d_stride1(
            in_channels, out_channels, kernel_size,
            weight_init_fn=weight_init_fn, bias_init_fn=bias_init_fn
        )
        self.downsample1d = Downsample1d(stride)

    def forward(self, A):
        """
        Argument:
            A (np.array): (batch_size, in_channels, input_size)
        Return:
            Z (np.array): (batch_size, out_channels, output_size)
        """

        # Call Conv1d_stride1
        C = self.conv1d_stride1.forward(A)

        # downsample
        Z = self.downsample1d.forward(C)

        return Z

    def backward(self, dLdZ):
        """
        Argument:
            dLdZ (np.array): (batch_size, out_channels, output_size)
        Return:
            dLdA (np.array): (batch_size, in_channels, input_size)
        """
        # Call downsample1d backward
        dLdC = self.downsample1d.backward(dLdZ)

        # Call Conv1d_stride1 backward
        dLdA = self.conv1d_stride1.backward(dLdC)

        return dLdA


if __name__ == "__main__":
    # Test your code here
    weight = np.array([
        [[1, 2], [2, 1]],
        [[0, 1], [1, 0]],
        [[3, 2], [1, 0]]
    ])
    A = np.array([
        [[1, 0, 1, 0, 1],
         [0, 1, 0, 1, 0]],
    ])
    T = Conv1d(2, 3, 2, 2, 
               weight_init_fn=lambda *args: weight,)
    T.forward(A)
    dLdZ = np.array([[[1, 1], [2, 1], [1, 2]]])
    dLdA = T.backward(dLdZ)
    print(T.conv1d_stride1.dLdW)
    print(dLdA[0, 0, 1])
    