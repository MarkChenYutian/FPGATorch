#include "../MatrixInterface.h"

SmartTensor MatMul128x128(const SmartTensor &A, const SmartTensor &B);


SmartTensor MatScalarMul128x128(float *A, float scalar, float *result, size_t count);
SmartTensor MatScalarDiv128x128(float *A, float scalar, float *result, size_t count);
SmartTensor MatScalarAdd128x128(float *A, float scalar, float *result, size_t count);
SmartTensor MatScalarInv128x128(float *A, float *result, size_t count);

SmartTensor MatElementwiseMul128x128(float *A, float *B, float *Result, size_t count);
SmartTensor MatAdd128x128(float *A, float *B, float *Result, size_t count);

