#pragma once

#include <string>
#include <memory>

struct Tensor {
    int size[3];
    float *data;
};

typedef struct Tensor Tensor_t;
typedef std::shared_ptr<Tensor_t> SmartTensor;

SmartTensor MatNew(int dim0, int dim1, int dim2);
SmartTensor MatNLike(const SmartTensor& original, float scalar);
SmartTensor MatRandN(int dim0, int dim1, int dim2);

void MatPrint(const SmartTensor& A);

float Get(const SmartTensor& A, int dim0, int dim1, int dim2);
void  Set(const SmartTensor& A, int dim0, int dim1, int dim2, float value);

SmartTensor MatAdd(const SmartTensor& A, const SmartTensor& B);
SmartTensor MatMul(const SmartTensor& A, const SmartTensor& B);
SmartTensor MatElementwiseMul(const SmartTensor& A, const SmartTensor& B);
SmartTensor MatTrans(const SmartTensor& A);

SmartTensor ScalarMatMul(const SmartTensor& A, float scalar);
SmartTensor ScalarMatDiv(const SmartTensor& A, float scalar);
SmartTensor ScalarMatAdd(const SmartTensor& A, float scalar);

SmartTensor ScalarMatInv(const SmartTensor& A);
SmartTensor ScalarMatExp(const SmartTensor& A);
SmartTensor ScalarMatLog(const SmartTensor& A);
SmartTensor ScalarGetGTMask(const SmartTensor& A, float scalar);

SmartTensor ReduceSum(const SmartTensor& A, int dim);


void save(const std::string &fileName, const SmartTensor& A);
SmartTensor load(const std::string &fileName);

void MatFill_inplace(const SmartTensor& A, float scalar);

/**
 * @WARNING: This is never intended to be called directly. This function is provided to the std::shared_pointer
 * as an auto de-allocator for Tensor_t object.
 */
void MatFree(Tensor_t* A);
