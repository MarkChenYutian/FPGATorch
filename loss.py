import numpy as np


class MSELoss:

    def forward(self, A, Y):
        """
        Calculate the Mean Squared error
        :param A: Output of the model of shape (N, C)
        :param Y: Ground-truth values of shape (N, C)
        :Return: MSE Loss(scalar)

        """

        self.A = A
        self.Y = Y
        self.N = A.shape[0]
        self.C = A.shape[1]
        se  = (A - Y) * (A - Y)
        sse = np.ones((self.N, 1)).T @ se @ np.ones((self.C, 1))
        mse = sse / (2 * self.N * self.C)

        return mse

    def backward(self):

        dLdA = (self.A - self.Y) / (self.N * self.C)

        return dLdA


class CrossEntropyLoss:
    
    def forward(self, A, Y):
        """
        Calculate the Cross Entropy Loss
        :param A: Output of the model of shape (N, C)
        :param Y: Ground-truth values of shape (N, C)
        :Return: CrossEntropyLoss(scalar)

        Refer the the writeup to determine the shapes of all the variables.
        Use dtype ='f' whenever initializing with np.zeros()
        """
        self.A = A
        self.Y = Y
        N = self.A.shape[0]
        C = self.A.shape[1]

        Ones_N = np.ones((N, 1))
        Ones_C = np.ones((C, 1))

        self.softmax = np.exp(A) / (np.sum(np.exp(A), axis=1)[..., np.newaxis])
        crossentropy = -1 * Y * np.log(self.softmax) @ Ones_C
        sum_crossentropy = (Ones_N.T) @ crossentropy
        L = sum_crossentropy / N

        return L

    def backward(self):

        dLdA = self.softmax - self.Y

        return dLdA
