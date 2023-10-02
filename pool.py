import numpy as np
from resampling import *


def sliding_window_view(x, w_shape, axises, writable):
    x_shape = [dim for dim in x.shape]
    for axis, dim in zip(axises, w_shape):
        x_shape[axis] = x_shape[axis] - dim + 1

    out_shape = x_shape + list(w_shape)
    out_strides = x.strides + tuple(x.strides[axis] for axis in axises)
    return np.lib.stride_tricks.as_strided(x, strides=out_strides, shape=out_shape, writeable=writable)


class MaxPool2d_stride1:
    def __init__(self, kernel):
        self.forward_shape = None
        self.fmask = None   # (batch, in_channel, output_width, output_height, 2)
        self.kernel = kernel

    def forward(self, A):
        """
        Argument:
            A (np.array): (batch_size, in_channels, input_width, input_height)
        Return:
            Z (np.array): (batch_size, out_channels, output_width, output_height)
        """
        self.forward_shape = A.shape
        batch_size, in_channels, in_width, in_height = self.forward_shape

        out_width = in_width - self.kernel + 1
        out_height = in_height - self.kernel + 1

        self.fmask = np.zeros((batch_size, in_channels, out_width, out_height, 2), dtype=int)
        output = np.zeros((batch_size, in_channels, out_width, out_height))

        for batch in range(batch_size):
            for in_channel in range(in_channels):
                for w in range(in_width - self.kernel + 1):
                    for h in range(in_height - self.kernel + 1):
                        patch = A[batch, in_channel, w:w + self.kernel, h:h + self.kernel]
                        max_idx = np.argmax(patch)
                        # print(max_idx, patch.shape, "==[max]==>")
                        self.fmask[batch, in_channel, w, h] = [w + max_idx // self.kernel, h + max_idx % self.kernel]
                        output[batch, in_channel, w, h] = np.max(patch)

        # print("==> Forward")
        return output

    def backward(self, dLdZ):
        """
        Argument:
            dLdZ (np.array): (batch_size, out_channels, output_width, output_height)
        Return:
            dLdA (np.array): (batch_size, in_channels, input_width, input_height)
        """
        batch_size, out_channels, out_width, out_height = dLdZ.shape
        dLdA = np.zeros(self.forward_shape)

        for batch in range(batch_size):
            for out_channel in range(out_channels):
                for w in range(out_width):
                    for h in range(out_height):
                        dw, dh = self.fmask[batch, out_channel, w, h]
                        dLdA[batch, out_channel, dw, dh] += dLdZ[batch, out_channel, w, h]

        return dLdA



class MeanPool2d_stride1:

    def __init__(self, kernel):
        self.kernel = kernel

    def forward(self, A):
        """
        Argument:
            A (np.array): (batch_size, in_channels, input_width, input_height)
        Return:
            Z (np.array): (batch_size, out_channels, output_width, output_height)
        """
        self.forward_shape = A.shape
        batch_size, in_channels, in_width, in_height = self.forward_shape

        out_width = in_width - self.kernel + 1
        out_height = in_height - self.kernel + 1

        self.fmask = np.zeros((batch_size, in_channels, out_width, out_height, 2), dtype=int)
        output = np.zeros((batch_size, in_channels, out_width, out_height))

        for batch in range(batch_size):
            for in_channel in range(in_channels):
                for w in range(in_width - self.kernel + 1):
                    for h in range(in_height - self.kernel + 1):
                        patch = A[batch, in_channel, w:w + self.kernel, h:h + self.kernel]
                        output[batch, in_channel, w, h] = np.mean(patch)

        return output

    def backward(self, dLdZ):
        """
        Argument:
            dLdZ (np.array): (batch_size, out_channels, output_width, output_height)
        Return:
            dLdA (np.array): (batch_size, in_channels, input_width, input_height)
        """

        batch_size, out_channels, out_width, out_height = dLdZ.shape
        dLdA = np.zeros(self.forward_shape)
        factor = 1 / (self.kernel * self.kernel)

        for batch in range(batch_size):
            for out_channel in range(out_channels):
                for w in range(out_width):
                    for h in range(out_height):
                        dLdA[batch, out_channel, w:w + self.kernel, h:h + self.kernel] \
                            += factor * dLdZ[batch, out_channel, w, h]

        return dLdA

class MaxPool2d():

    def __init__(self, kernel, stride):
        self.kernel = kernel
        self.stride = stride

        # Create an instance of MaxPool2d_stride1
        self.maxpool2d_stride1 = MaxPool2d_stride1(self.kernel)  # TODO
        self.downsample2d = Downsample2d(self.stride)  # TODO

    def forward(self, A):
        """
        Argument:
            A (np.array): (batch_size, in_channels, input_width, input_height)
        Return:
            Z (np.array): (batch_size, out_channels, output_width, output_height)
        """

        B = self.maxpool2d_stride1.forward(A)
        Z = self.downsample2d.forward(B)
        return Z

    def backward(self, dLdZ):
        """
        Argument:
            dLdZ (np.array): (batch_size, out_channels, output_width, output_height)
        Return:
            dLdA (np.array): (batch_size, in_channels, input_width, input_height)
        """
        dLdB = self.downsample2d.backward(dLdZ)
        dLdA = self.maxpool2d_stride1.backward(dLdB)
        return dLdA

class MeanPool2d():

    def __init__(self, kernel, stride):
        self.kernel = kernel
        self.stride = stride

        # Create an instance of MaxPool2d_stride1
        self.meanpool2d_stride1 = MeanPool2d_stride1(self.kernel)
        self.downsample2d = Downsample2d(self.stride)

    def forward(self, A):
        """
        Argument:
            A (np.array): (batch_size, in_channels, input_width, input_height)
        Return:
            Z (np.array): (batch_size, out_channels, output_width, output_height)
        """
        B = self.meanpool2d_stride1.forward(A)
        Z = self.downsample2d.forward(B)
        return Z

    def backward(self, dLdZ):
        """
        Argument:
            dLdZ (np.array): (batch_size, out_channels, output_width, output_height)
        Return:
            dLdA (np.array): (batch_size, in_channels, input_width, input_height)
        """
        dLdB = self.downsample2d.backward(dLdZ)
        dLdA = self.meanpool2d_stride1.backward(dLdB)
        return dLdA
