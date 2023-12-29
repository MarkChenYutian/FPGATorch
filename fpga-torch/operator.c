#include "MatrixInterface.h"

// Sigmoid((b, m, n)) -> (b, m, n)
float *SigmoidFwd(float *A, int b, int m, int n) {
    float *A1 = ScalarMatMul(A, -1.f, b, m, n);
    float *A2 = MatExp(A, b, m, n);
    float *A3 = ScalarMatAdd(A, 1.f, b, m, n);
    float *A4 = MatInv(A, b, m, n);
    free(A1);
    free(A2);
    free(A3);
    return A4;
}


/**
 * Forward(A, w, b) -> A'
 * @param
 * A      - shape (batch, size, in_feat)
 * weight - shape (1, in_feat, out_feat)
 * bias   - shape (1, size, out_feat)
 * @returns
 * Z - shape (batch, size, out_feat)
*/
float *LinearFwd(float *A, float *weight, float *bias, int batch, int in_feat, int out_feat, int size) {
    float *prod = MatMul(A, weight, batch, size, in_feat, out_feat);
    float *Z = MatAdd(prod, bias, batch, size, out_feat);
    free(prod);
    return Z;
}

