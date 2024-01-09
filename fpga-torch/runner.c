#include "MatrixInterface.h"
#include "Operator.h"

int main() {
    LinearLayer_t *linear1 = newLinear(2, 3, 4);

    Tensor_t *A = MatNew(2, 2, 3);
    Set(A, 0, 0, 0, 1.f);
    Set(A, 0, 0, 1, 2.f);
    Set(A, 0, 0, 2, 3.f);
    Set(A, 0, 1, 0, 4.f);
    Set(A, 0, 1, 1, 5.f);
    Set(A, 0, 1, 2, 6.f);
    MatPrint(A);

    Tensor_t *result = LinearForward(linear1, A);
    MatPrint(result);


    MatFree(A);
    MatFree(result);
    LinearFree(linear1);
    return 0;
}

