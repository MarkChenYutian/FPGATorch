#include "../MatrixInterface.h"

SmartTensor MatMul128x128(const SmartTensor &A, const SmartTensor &B);


void MatScalarMul128x128(float *A, float scalar, float *result, size_t count);
void MatScalarDiv128x128(float *A, float scalar, float *result, size_t count);
void MatScalarAdd128x128(float *A, float scalar, float *result, size_t count);
void MatScalarInv128x128(float *A, float *result, size_t count);

void MatElementwiseMul128x128(float *A, float *B, float *Result, size_t count);
void MatAdd128x128(float *A, float *B, float *Result, size_t count);

