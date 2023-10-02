import numpy as np


class Upsample1d():

    def __init__(self, upsampling_factor):
        self.forward_shape = None
        self.upsampling_factor = upsampling_factor

    def forward(self, A: np.ndarray) -> np.ndarray:
        """
        Argument:
            A (np.array): (batch_size, in_channels, input_width)
        Return:
            Z (np.array): (batch_size, in_channels, output_width)
        """
        self.forward_shape = A.shape
        batch, in_channel, width = self.forward_shape
        upsample_width = self.upsampling_factor * (width - 1) + 1
        upsample_mask = np.equal(np.arange(0, upsample_width) % self.upsampling_factor, 0)

        Z = np.zeros((batch, in_channel, upsample_width))
        Z[:, :, upsample_mask] = A

        return Z

    def backward(self, dLdZ):
        """
        Argument:
            dLdZ (np.array): (batch_size, in_channels, output_width)
        Return:
            dLdA (np.array): (batch_size, in_channels, input_width)
        """

        # dLdA = np.zeros(self.forward_shape)
        _, _, width = self.forward_shape
        upsample_width = self.upsampling_factor * (width - 1) + 1
        upsample_mask = np.equal(np.arange(0, upsample_width) % self.upsampling_factor, 0)

        dLdA = dLdZ[:, :, upsample_mask]
        return dLdA


class Downsample1d():

    def __init__(self, downsampling_factor):
        self.forward_shape = None
        self.downsampling_factor = downsampling_factor

    def forward(self, A):
        """
        Argument:
            A (np.array): (batch_size, in_channels, input_width)
        Return:
            Z (np.array): (batch_size, in_channels, output_width)
        """

        self.forward_shape = A.shape
        batch_size, in_channels, input_width = self.forward_shape
        downsample_mask = np.equal(np.arange(0, input_width) % self.downsampling_factor, 0)

        Z = A[:, :, downsample_mask]

        return Z

    def backward(self, dLdZ):
        """
        Argument:
            dLdZ (np.array): (batch_size, in_channels, output_width)
        Return:
            dLdA (np.array): (batch_size, in_channels, input_width)
        """
        _, _, input_width = self.forward_shape
        dLdA = np.zeros(self.forward_shape)
        downsample_mask = np.equal(np.arange(0, input_width) % self.downsampling_factor, 0)

        dLdA[:, :, downsample_mask] = dLdZ

        return dLdA


class Upsample2d():

    def __init__(self, upsampling_factor):
        self.forward_shape = None
        self.upsampling_factor = upsampling_factor

    def forward(self, A: np.ndarray):
        """
        Argument:
            A (np.array): (batch_size, in_channels, input_height, input_width)
        Return:
            Z (np.array): (batch_size, in_channels, output_height, output_width)
        """
        self.forward_shape = A.shape
        batch_size, in_channels, input_height, input_width = self.forward_shape

        upsample_h = self.upsampling_factor * (input_height - 1) + 1
        upsample_w = self.upsampling_factor * (input_width - 1) + 1

        upsample_h_mask = np.equal(np.arange(0, upsample_h) % self.upsampling_factor, 0)
        upsample_w_mask = np.equal(np.arange(0, upsample_w) % self.upsampling_factor, 0)

        upsample_mask = np.logical_and(*np.meshgrid(upsample_h_mask, upsample_w_mask))

        Z = np.zeros((batch_size, in_channels, upsample_h, upsample_w))
        Z[:, :, upsample_mask] = A.reshape((batch_size, in_channels, -1))

        return Z

    def backward(self, dLdZ):
        """
        Argument:
            dLdZ (np.array): (batch_size, in_channels, output_height, output_width)
        Return:
            dLdA (np.array): (batch_size, in_channels, input_height, input_width)
        """
        batch_size, in_channels, input_height, input_width = self.forward_shape

        upsample_h = self.upsampling_factor * (input_height - 1) + 1
        upsample_w = self.upsampling_factor * (input_width - 1) + 1

        upsample_h_mask = np.equal(np.arange(0, upsample_h) % self.upsampling_factor, 0)
        upsample_w_mask = np.equal(np.arange(0, upsample_w) % self.upsampling_factor, 0)

        upsample_mask = np.logical_and(*np.meshgrid(upsample_h_mask, upsample_w_mask))

        dLdA = dLdZ[:, :, upsample_mask].reshape(self.forward_shape)

        return dLdA


class Downsample2d():

    def __init__(self, downsampling_factor):
        self.forward_shape = None
        self.downsampling_factor = downsampling_factor

    def forward(self, A: np.ndarray):
        """
        Argument:
            A (np.array): (batch_size, in_channels, input_height, input_width)
        Return:
            Z (np.array): (batch_size, in_channels, output_height, output_width)
        """
        self.forward_shape = A.shape

        batch_size, in_channels, input_height, input_width = self.forward_shape

        downsample_h_mask = np.equal(np.arange(0, input_height) % self.downsampling_factor, 0)
        downsample_w_mask = np.equal(np.arange(0, input_width) % self.downsampling_factor, 0)
        downsample_mask = np.logical_and(*np.meshgrid(downsample_h_mask, downsample_w_mask))

        Z = A[:, :, downsample_mask]
        extra_col = 1 if input_height % self.downsampling_factor > 0 else 0
        Z = Z.reshape(
            (batch_size, in_channels, input_height // self.downsampling_factor + extra_col, -1)
        )

        return Z

    def backward(self, dLdZ):
        """
        Argument:
            dLdZ (np.array): (batch_size, in_channels, output_height, output_width)
        Return:
            dLdA (np.array): (batch_size, in_channels, input_height, input_width)
        """

        batch_size, in_channels, input_height, input_width = self.forward_shape
        dLdA = np.zeros((batch_size, in_channels, input_height, input_width))

        downsample_h_mask = np.equal(np.arange(0, input_height) % self.downsampling_factor, 0)
        downsample_w_mask = np.equal(np.arange(0, input_width) % self.downsampling_factor, 0)
        downsample_mask = np.logical_and(*np.meshgrid(downsample_h_mask, downsample_w_mask))

        dLdA[:, :, downsample_mask] = dLdZ.reshape((batch_size, in_channels, -1))

        return dLdA
