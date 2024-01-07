#include <stdio.h>
#include "MatrixInterface.h"
#include "CPUMatrix.c"

int main() {
    Tensor_t *A = MatNew(2, 2, 3);
    Set(A, 0, 0, 0, 1.f);
    Set(A, 0, 0, 1, 2.f);
    Set(A, 0, 0, 2, 3.f);
    Set(A, 0, 1, 0, 4.f);
    Set(A, 0, 1, 1, 5.f);
    Set(A, 0, 1, 2, 6.f);
    MatPrint(A);
    Tensor_t *B = MatTrans(A);
    MatPrint(B);
    Tensor_t *C = MatMul(A, B);
    MatPrint(C);
    return 0;
}
