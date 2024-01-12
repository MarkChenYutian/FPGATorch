#pragma once

#include <cstdio>
#include <cassert>
#include <cmath>
#include "../MatrixInterface.h"
#include <iomanip>
#include <iostream>
#include <fstream>
#include <memory>

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

SmartTensor MatNLike(const SmartTensor& original, float scalar) {
    SmartTensor result = MatNew(original->size[0], original->size[1], original->size[2]);
    MatFill_inplace(result, scalar);
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
    DBG_ASSERT(A->size[0] == B->size[0]);
    DBG_ASSERT(A->size[1] == B->size[1]);
    DBG_ASSERT(A->size[2] == B->size[2]);
    SmartTensor C = MatNew(A->size[0], A->size[1], A->size[2]);

    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                float value = Get(A, i, j, k) + Get(B, i, j, k);
                Set(C, i, j, k, value);
            }}}
    return C;
}

SmartTensor ScalarMatMul(const SmartTensor& A, float scalar) {
    SmartTensor C = MatNew(A->size[0], A->size[1], A->size[2]);

    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                float value = Get(A, i, j, k) * scalar;
                Set(C, i, j, k, value);
            }}}
    return C;
}

SmartTensor ScalarMatDiv(const SmartTensor& A, float scalar) {
    DBG_ASSERT(scalar != 0);

    SmartTensor C = MatNew(A->size[0], A->size[1], A->size[2]);

    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                float value = Get(A, i, j, k) / scalar;
                Set(C, i, j, k, value);
            }}}
    return C;
}

SmartTensor ScalarMatAdd(const SmartTensor& A, float scalar) {
    DBG_ASSERT(A->size[0] == B->size[0]);
    DBG_ASSERT(A->size[1] == B->size[1]);
    DBG_ASSERT(A->size[2] == B->size[2]);
    DBG_ASSERT(scalar != 0);

    SmartTensor C = MatNew(A->size[0], A->size[1], A->size[2]);

    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                float value = Get(A, i, j, k) + scalar;
                Set(C, i, j, k, value);
            }}}
    return C;
}

SmartTensor ScalarMatInv(const SmartTensor& A) {
    SmartTensor C = MatNew(A->size[0], A->size[1], A->size[2]);

    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                float value = 1.f / Get(A, i, j, k);
                Set(C, i, j, k, value);
            }}}
    return C;
}

SmartTensor ScalarMatExp(const SmartTensor& A) {
    SmartTensor C = MatNew(A->size[0], A->size[1], A->size[2]);

    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                float value = expf(Get(A, i, j, k));
                Set(C, i, j, k, value);
            }}}
    return C;
}

SmartTensor ScalarMatLog(const SmartTensor& A) {
    SmartTensor C = MatNew(A->size[0], A->size[1], A->size[2]);

    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                float value = logf(Get(A, i, j, k));
                Set(C, i, j, k, value);
            }}}
    return C;
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
        printf("[\n");
        for (int j = 0; j < A->size[1]; j ++) {
            printf("[");
            for (int k = 0; k < A->size[2]; k ++) {
                printf("%.2f ", Get(A, i, j, k));
            }
            printf("\b]\n");
        }
        printf("]\n");
    }
}

void save(const std::string& fileName, const SmartTensor& A) {
    std::ofstream dumpFile;
    dumpFile.open(fileName, std::ios::trunc);
    if (!dumpFile.is_open()) {
        std::cout << "Unable to dump tensor to the file " << fileName << std::endl;
        return;
    }
    dumpFile << "Matrix_Interface\n";
    dumpFile << "Size Information\n";
    dumpFile << A->size[0] << "\n";
    dumpFile << A->size[1] << "\n";
    dumpFile << A->size[2] << "\n";
    dumpFile << "Data\n";
    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                dumpFile <<  std::fixed << std::setprecision(8) << Get(A, i, j, k) << "\n";
            }}}
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
    if (line != "Matrix_Interface" && line != "Matrix_Interface\r") {
        std::cout << "(Wrong format 1) Unable to read tensor from the file" << fileName << std::endl;
        return nullptr;
    }

    getline(dumpFile, line);
    int size0, size1, size2;
    getline(dumpFile, line);
    size0 = std::stoi(line);
    getline(dumpFile, line);
    size1 = std::stoi(line);
    getline(dumpFile, line);
    size2 = std::stoi(line);

    SmartTensor A = MatNew(size0, size1, size2);

    getline(dumpFile, line);
    if (line != "Data" && line != "Data\r") {
        std::cout << "(Wrong format 2) Unable to read tensor from the file" << fileName << std::endl;
        return nullptr;
    }
    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                getline(dumpFile, line);
                Set(A, i, j, k, std::stof(line));
            }}}
    return A;
}

void MatFill_inplace(const SmartTensor& A, float scalar) {
    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                Set(A, i, j, k, scalar);
            }}}
}
