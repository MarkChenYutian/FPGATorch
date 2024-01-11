import numpy as np

class Flatten():
    def __init__(self):
        self.forward_shape = None

    def forward(self, A):
        """
        Argument:
            A (np.array): (batch_size, in_channels, in_width)
        Return:
            Z (np.array): (batch_size, in_channels * in width)
        """
        self.forward_shape = A.shape
        batch_size, _, _ = self.forward_shape

        Z = A.reshape((batch_size, -1))

        return Z

    def backward(self, dLdZ):
        """
        Argument:
            dLdZ (np.array): (batch size, in channels * in width)
        Return:
            dLdA (np.array): (batch size, in channels, in width)
        """

        dLdA = dLdZ.reshape(self.forward_shape)

        return dLdA
