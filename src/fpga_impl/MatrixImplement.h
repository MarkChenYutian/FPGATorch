#pragma once

#include <cstdio>
#include <cstring>
#include <cassert>
#include <cmath>
#include <iomanip>
#include <sstream>
#include <iostream>
#include <fstream>
#include <memory>
#include <random>

#include "../MatrixInterface.h"

#ifdef DEBUG
#define DBG_ASSERT(arg) assert(arg);
#else
#define DBG_ASSERT(arg) (void)0;
#endif


SmartTensor MatNew(int dim0, int dim1, int dim2) {
    SmartTensor matrix(new Tensor_t{}, MatFree);
    matrix->data = static_cast<float *>(calloc(sizeof(float), dim0 * dim1 * dim2));
    matrix->size[0] = dim0;
    matrix->size[1] = dim1;
    matrix->size[2] = dim2;
    return matrix;
}

SmartTensor MatRandN(int dim0, int dim1, int dim2, float mean, float std) {
    SmartTensor emptyMat = MatNew(dim0, dim1, dim2);
    std::random_device rd;
    std::mt19937 gen(rd());
    std::normal_distribution<float> dist(mean, std);

    for (int i = 0; i < dim0 * dim1 * dim2; i ++) {
        emptyMat->data[i] = dist(gen);
    }
    return emptyMat;
}

SmartTensor MatNLike(const SmartTensor& original, float scalar) {
    SmartTensor result = MatNew(original->size[0], original->size[1], original->size[2]);
    if (scalar != 0.f) MatFill_inplace(result, scalar);
    return result;
}

void MatFree(Tensor_t *mat) {
    if (mat == nullptr) return;
    free(mat->data);
    delete mat;
}

float Get(const SmartTensor& A, int dim0, int dim1, int dim2) {
    int offset0 = dim0 * A->size[1] * A->size[2];
    int offset1 = dim1 * A->size[2];
    int offset2 = dim2;
    return A->data[offset0 + offset1 + offset2];
}

void  Set(const SmartTensor& A, int dim0, int dim1, int dim2, float value) {
    int offset0 = dim0 * A->size[1] * A->size[2];
    int offset1 = dim1 * A->size[2];
    int offset2 = dim2;
    A->data[offset0 + offset1 + offset2] = value;
}

SmartTensor MatAdd(const SmartTensor& A, const SmartTensor& B) {
    SmartTensor result = MatNLike(A, 0.f);
    for (int i = 0; i < A->size[0] * A->size[1] * A->size[2]; i ++) {
        result->data[i] = (A->data[i]) + (B->data[i]);
    }
    return result;
}

SmartTensor ScalarMatMul(const SmartTensor& A, float scalar) {
    SmartTensor result = MatNLike(A, 0.f);
    for (int i = 0; i < A->size[0] * A->size[1] * A->size[2]; i ++) {
        result->data[i] = (A->data[i]) * scalar;
    }
    return result;
}

SmartTensor ScalarMatDiv(const SmartTensor& A, float scalar) {
    SmartTensor result = MatNLike(A, 0.f);
    for (int i = 0; i < A->size[0] * A->size[1] * A->size[2]; i ++) {
        result->data[i] = (A->data[i]) / scalar;
    }
    return result;
}

SmartTensor ScalarMatAdd(const SmartTensor& A, float scalar) {
    SmartTensor result = MatNLike(A, 0.f);
    for (int i = 0; i < A->size[0] * A->size[1] * A->size[2]; i ++) {
        result->data[i] = A->data[i] + scalar;
    }
    return result;
}

SmartTensor ScalarMatInv(const SmartTensor& A) {
    SmartTensor result = MatNLike(A, 0.f);
    for (int i = 0; i < A->size[0] * A->size[1] * A->size[2]; i ++) {
        result->data[i] = 1/(A->data[i]);
    }
    return result;
}

SmartTensor ScalarMatExp(const SmartTensor& A) {
    SmartTensor result = MatNLike(A, 0.f);
    for (int i = 0; i < A->size[0] * A->size[1] * A->size[2]; i ++) {
        result->data[i] = expf(A->data[i]);
    }
    return result;
}

SmartTensor ScalarMatLog(const SmartTensor& A) {
    SmartTensor result = MatNLike(A, 0.f);
    for (int i = 0; i < A->size[0] * A->size[1] * A->size[2]; i ++) {
        if (A->data[i] == 0) result->data[i] = logf(0.0001f);
        else result->data[i] = logf(A->data[i]);
    }
    return result;
}

SmartTensor MatMul(const SmartTensor& A, const SmartTensor& B) {
    // B, N, M @ B, M, K -> B, N, K
    DBG_ASSERT(A->size[0] == B->size[0]);
    DBG_ASSERT(A->size[2] == B->size[1]);
    SmartTensor C = MatNew(A->size[0], A->size[1], B->size[2]);

    for (int p = 0; p < A->size[0]; p ++) {
        for (int q = 0; q < A->size[1]; q ++) {
            for (int r = 0; r < B->size[2]; r ++) {
                float result = 0;
                for (int s = 0; s < A->size[2]; s++) {
                    float valueA = Get(A, p, q, s);
                    float valueB = Get(B, p, s, r);
                    result += valueA * valueB;
                }
                Set(C, p, q, r, result);
            }
        }
    }
    return C;
}

SmartTensor MatMul(const SmartTensor& A, const SmartTensor& B) {
    SmartTensor C = MatNew(A->size[0], A->size[1], B->size[2]);
    return C;
}

SmartTensor MatTrans(const SmartTensor& A) {
    SmartTensor B = MatNew(A->size[0], A->size[2], A->size[1]);
    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                Set(B, i, k, j, Get(A, i, j, k));
            }
        }
    }
    return B;
}

SmartTensor ReduceSum(const SmartTensor& A, int dim) {
    SmartTensor Result;
    if (dim == 0) {
        Result = MatNew(1, A->size[1], A->size[2]);
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                float value = 0;
                for (int i = 0; i < A->size[0]; i ++) {
                    value += Get(A, i, j, k);
                }
                Set(Result, 0, j, k, value);
            }
        }
    } else if (dim == 1) {
        Result = MatNew(A->size[0], 1, A->size[2]);
        for (int i = 0; i < A->size[0]; i ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                float value = 0;
                for (int j = 0; j < A->size[1]; j ++) {
                    value += Get(A, i, j, k);
                }
                Set(Result, i, 0, k, value);
            }
        }
    } else {
        assert(false);  // Not yet implemented!
    }
    return Result;
}

void MatPrint(const SmartTensor& A) {
    printf("Shape: %d %d %d\n", A->size[0], A->size[1], A->size[2]);
    for (int i = 0; i < A->size[0]; i ++) {
        printf("[");
        for (int j = 0; j < A->size[1]; j ++) {
            printf("[");
            for (int k = 0; k < A->size[2]; k ++) {
                printf("%.2f ", Get(A, i, j, k));
            }
            printf("\b]\n");
        }
        printf("]END\n");
    }
}

std::string serialize(const SmartTensor &A) {
    size_t size = A->size[0] * A->size[1] * A->size[2];
    std::ostringstream oss;

    oss << A->size[0] << " " << A->size[1] << " " << A->size[2] << " >DATA_BEGIN< ";
    for (int i = 0; i < size; i ++) {
        oss << std::fixed << std::setprecision(6) << A->data[i] << " ";
    }
    oss << "\n";
    return oss.str();
}

SmartTensor deserialize(const std::string &str) {
    std::istringstream iss(str);
    int size0, size1, size2;
    iss >> size0 >> size1 >> size2;

    std::string identifier;
    iss >> identifier;
    if (identifier != ">DATA_BEGIN<") {
        printf("Did not find identified >DATA_BEGIN< file maybe corrupted or in wrong format");
        return nullptr;
    }

    SmartTensor A = MatNew(size0, size1, size2);
    size_t numElem = size0 * size1 * size2;
    for (int i = 0; i < numElem; i ++) {
        iss >> A->data[i];
    }
    return A;
}

void save(const std::string& fileName, const SmartTensor& A) {
    std::ofstream dumpFile;
    dumpFile.open(fileName, std::ios::trunc);
    if (!dumpFile.is_open()) {
        std::cout << "Unable to dump tensor to the file " << fileName << std::endl;
        return;
    }
    dumpFile << serialize(A);
    dumpFile.close();
}

SmartTensor load(const std::string& fileName) {
    std::ifstream dumpFile;
    dumpFile.open(fileName, std::ios::in);
    if (!dumpFile.is_open()) {
        std::cout << "Unable to read tensor from the file" << fileName << std::endl;
        return nullptr;
    }
    std::string line;
    getline(dumpFile, line);
    return deserialize(line);
}

void MatFill_inplace(const SmartTensor& A, float scalar) {
    for (int i = 0; i < A->size[0] * A->size[1] * A->size[2]; i ++) {
        A->data[i] = scalar;
    }
}

SmartTensor ScalarGetGTMask(const SmartTensor& A, float scalar) {
    SmartTensor Mask = MatNLike(A, 0.f);
    for (int i = 0; i < A->size[0] * A->size[1] * A->size[2]; i ++) {
        Mask->data[i] = (A->data[i] > scalar) ? 1.f : 0.f;
    }
    return Mask;
}

SmartTensor MatElementwiseMul(const SmartTensor &A, const SmartTensor &B) {
    SmartTensor result = MatNLike(A, 0.f);
    for (int i = 0; i < A->size[0] * A->size[1] * A->size[2]; i ++) {
        result->data[i] = A->data[i] * B->data[i];
    }
    return result;
}

