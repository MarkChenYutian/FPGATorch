import numpy as np
from resampling import Downsample2d


def sliding_window_view(x, w_shape, axises):
    x_shape = [dim for dim in x.shape]
    for axis, dim in zip(axises, w_shape):
        x_shape[axis] = x_shape[axis] - dim + 1

    out_shape = x_shape + list(w_shape)
    out_strides = x.strides + tuple(x.strides[axis] for axis in axises)
    return np.lib.stride_tricks.as_strided(x, strides=out_strides, shape=out_shape, writeable=False)


class Conv2d_stride1:
    def __init__(self, in_channels, out_channels,
                 kernel_size, weight_init_fn=None, bias_init_fn=None):

        # Do not modify this method
        self.A = None
        self.in_channels = in_channels
        self.out_channels = out_channels
        self.kernel_size = kernel_size

        if weight_init_fn is None:
            self.W = np.random.normal(
                0, 1.0, (out_channels, in_channels, kernel_size, kernel_size))
        else:
            self.W = weight_init_fn(
                out_channels,
                in_channels,
                kernel_size,
                kernel_size)

        if bias_init_fn is None:
            self.b = np.zeros(out_channels)
        else:
            self.b = bias_init_fn(out_channels)

        self.dLdW = np.zeros(self.W.shape)
        self.dLdb = np.zeros(self.b.shape)

    def forward(self, A):
        """
        Argument:
            A (np.array): (batch_size, in_channels, input_height, input_width)
        Return:
            Z (np.array): (batch_size, out_channels, output_height, output_width)
        """
        self.A = A
        # A_stride (np.array): (batch_size, in_channels, window_height, window_width, kernel_size, kernel_size)
        # W (np.array): (out_channel, in_channel, kernel_size, kernel_size)
        A_stride = sliding_window_view(
            A,
            (self.kernel_size, self.kernel_size),
            (2, 3)
        )
        # b: batch, i: in_channel, h: height(window cnt), w: width(window cnt)
        # k: kernel_size(width), l: kernel_size(height) o: out_channel
        Z = np.einsum("bihwlk,oilk->bohw", A_stride, self.W)
        Z = Z + self.b[np.newaxis, :, np.newaxis, np.newaxis]
        return Z

    def backward(self, dLdZ):
        """
        Argument:
            dLdZ (np.array): (batch_size, out_channels, output_height, output_width)
        Return:
            dLdA (np.array): (batch_size, in_channels, input_height, input_width)
        """
        dLdZ_stride = np.pad(
            dLdZ,
            [(0,), (0,), (self.kernel_size - 1,), (self.kernel_size - 1,)],
            "constant", constant_values=0
        )
        dLdZ_stride = sliding_window_view(
            dLdZ_stride,
            (self.kernel_size, self.kernel_size),
            (2, 3),
        )
        kernel = np.flip(self.W, axis=(2, 3))

        # dLdZ_stride: (batch_size, out_channels, window_height, window_width, kernel_height, kernel_width)
        # kernel: (out_channel, in_channel, kernel_height, kernel_width)
        dLdA = np.einsum("bohwlk,oilk->bihw", dLdZ_stride, kernel)

        # Calculate dLdW
        A_stride = sliding_window_view(
            self.A,
            (dLdZ.shape[2], dLdZ.shape[3]),
            (2, 3)
        )
        self.dLdW = np.einsum("bilkhw,bohw->oilk", A_stride, dLdZ)

        # Calculate dLdb
        self.dLdb = np.einsum("bohw->o", dLdZ)

        return dLdA


class Conv2d:
    def __init__(self, in_channels, out_channels, kernel_size, stride,
                 weight_init_fn=None, bias_init_fn=None):
        # Do not modify the variable names
        self.stride = stride

        # Initialize Conv2d() and Downsample2d() isntance
        self.conv2d_stride1 = Conv2d_stride1(
            in_channels, out_channels, kernel_size,
            weight_init_fn=weight_init_fn, bias_init_fn=bias_init_fn
        )
        self.downsample2d = Downsample2d(stride)

    def forward(self, A):
        """
        Argument:
            A (np.array): (batch_size, in_channels, input_height, input_width)
        Return:
            Z (np.array): (batch_size, out_channels, output_height, output_width)
        """
        # Call Conv2d_stride1
        C = self.conv2d_stride1.forward(A)

        # downsample
        Z = self.downsample2d.forward(C)

        return Z

    def backward(self, dLdZ):
        """
        Argument:
            dLdZ (np.array): (batch_size, out_channels, output_height, output_width)
        Return:
            dLdA (np.array): (batch_size, in_channels, input_height, input_width)
        """

        # Call downsample1d backward
        dLdC = self.downsample2d.backward(dLdZ)

        # Call Conv1d_stride1 backward
        dLdA = self.conv2d_stride1.backward(dLdC)

        return dLdA
