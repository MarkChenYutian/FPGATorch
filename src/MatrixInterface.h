#pragma once

#include <string>

struct Tensor {
    int size[3];
    float *data;
};

typedef struct Tensor Tensor_t;

Tensor_t *MatNew(int dim0, int dim1, int dim2);
Tensor_t *MatNLike(Tensor_t *original, float scalar);
void MatFree(Tensor_t *A);
void MatPrint(Tensor_t *A);

float Get(Tensor_t *A, int dim0, int dim1, int dim2);
void Set(Tensor_t *A, int dim0, int dim1, int dim2, float value);

Tensor_t *MatAdd(Tensor_t *A, Tensor_t *B);
Tensor_t *MatMul(Tensor_t *A, Tensor_t *B);
Tensor_t *MatTrans(Tensor_t *A);

Tensor_t *ScalarMatMul(Tensor_t *A, float scalar);
Tensor_t *ScalarMatDiv(Tensor_t *A, float scalar);
Tensor_t *ScalarMatAdd(Tensor_t *A, float scalar);

Tensor_t *ScalarMatInv(Tensor_t *A);
Tensor_t *ScalarMatExp(Tensor_t *A);
Tensor_t *ScalarMatLog(Tensor_t *A);

Tensor_t *ReduceSum(Tensor_t *A, int dim);

void MatFill_inplace(Tensor_t *A, float scalar);

void save(const std::string &fileName, Tensor_t *A);
Tensor_t *load(const std::string &fileName);
