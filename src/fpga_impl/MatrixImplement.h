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
#include "FPGAInterface.h"

#ifdef DEBUG
#define DBG_ASSERT(arg) assert(arg);
#else
#define DBG_ASSERT(arg) (void)0;
#endif

// This is the maximum amount we can handle
constexpr int FPGA_MAX_SIZE_SQRT = 128;
constexpr size_t FPGA_MAX_SIZE = FPGA_MAX_SIZE_SQRT * FPGA_MAX_SIZE_SQRT;

// This is the minimum amount we should use FPGA since the communication overhead is too high
// TODO: This value need further tuning
constexpr size_t FPGA_MIN_SIZE = 128; 


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

inline int GetIndex(const SmartTensor& A, int dim0, int dim1, int dim2) {
    return (dim0 * A->size[1] * A->size[2]) + (dim1 * A->size[2]) + dim2;
}

inline float Get(const SmartTensor& A, int dim0, int dim1, int dim2) {
    return A->data[GetIndex(A, dim0, dim1, dim2)];
}

inline void  Set(const SmartTensor& A, int dim0, int dim1, int dim2, float value) {
    A->data[GetIndex(A, dim0, dim1, dim2)] = value;
}

SmartTensor MatAdd(const SmartTensor& A, const SmartTensor& B) {
    SmartTensor result = MatNLike(A, 0.f);
    size_t size = A->size[0] * A->size[1] * A->size[2];

    float *A_data_ptr = &(A->data[0]);
    float *B_data_ptr = &(B->data[0]);
    float *R_data_ptr = &(result->data[0]);

    size_t offset = 0;
    for (; (offset + FPGA_MAX_SIZE) < size; offset += FPGA_MAX_SIZE) {
        MatAdd128x128(A_data_ptr+offset, B_data_ptr+offset, R_data_ptr+offset, FPGA_MAX_SIZE);
    }

    size_t remain = size - offset;
    if (remain >= FPGA_MIN_SIZE) {
        MatAdd128x128(A_data_ptr+offset, B_data_ptr+offset, R_data_ptr+offset, remain);
    } else {
        for (; offset < size; offset ++) {
            R_data_ptr[offset] = A_data_ptr[offset] + B_data_ptr[offset];
        }
    }
    return result;
}

SmartTensor ScalarMatMul(const SmartTensor& A, float scalar) {
    SmartTensor result = MatNLike(A, 0.f);
    size_t size = A->size[0] * A->size[1] * A->size[2];

    float *A_data_ptr = &(A->data[0]);
    float *R_data_ptr = &(result->data[0]);

    size_t offset = 0;
    for (; (offset + FPGA_MAX_SIZE) < size; offset += FPGA_MAX_SIZE) {
        MatScalarMul128x128(A_data_ptr+offset, scalar, R_data_ptr+offset, FPGA_MAX_SIZE);
    }

    size_t remain = size - offset;
    if (remain >= FPGA_MIN_SIZE) {
        MatScalarMul128x128(A_data_ptr+offset, scalar, R_data_ptr+offset, remain);
    } else {
        for (; offset < size; offset ++) {
            R_data_ptr[offset] = A_data_ptr[offset] * scalar;
        }
    }
    return result;
}

SmartTensor ScalarMatDiv(const SmartTensor& A, float scalar) {
    SmartTensor result = MatNLike(A, 0.f);
    size_t size = A->size[0] * A->size[1] * A->size[2];

    float *A_data_ptr = &(A->data[0]);
    float *R_data_ptr = &(result->data[0]);

    size_t offset = 0;
    for (; (offset + FPGA_MAX_SIZE) < size; offset += FPGA_MAX_SIZE) {
        MatScalarDiv128x128(A_data_ptr+offset, scalar, R_data_ptr+offset, FPGA_MAX_SIZE);
    }
    
    size_t remain = size - offset;
    if (remain >= FPGA_MIN_SIZE) {
        MatScalarDiv128x128(A_data_ptr+offset, scalar, R_data_ptr+offset, remain);
    } else {
        for (; offset < size; offset ++) {
            R_data_ptr[offset] = A_data_ptr[offset] / scalar;
        }
    }
    return result;
}

SmartTensor ScalarMatAdd(const SmartTensor& A, float scalar) {
    SmartTensor result = MatNLike(A, 0.f);
    size_t size = A->size[0] * A->size[1] * A->size[2];

    float *A_data_ptr = &(A->data[0]);
    float *R_data_ptr = &(result->data[0]);

    size_t offset = 0;
    for (; (offset + FPGA_MAX_SIZE) < size; offset += FPGA_MAX_SIZE) {
        MatScalarAdd128x128(A_data_ptr+offset, scalar, R_data_ptr+offset, FPGA_MAX_SIZE);
    }

    size_t remain = size - offset;
    if (remain >= FPGA_MIN_SIZE) {
        MatScalarAdd128x128(A_data_ptr+offset, scalar, R_data_ptr+offset, remain);
    } else {
        for (; offset < size; offset ++) {
            R_data_ptr[offset] = A_data_ptr[offset] + scalar;
        }
    }
    return result;
}

SmartTensor ScalarMatInv(const SmartTensor& A) {
    SmartTensor result = MatNLike(A, 0.f);
    size_t size = A->size[0] * A->size[1] * A->size[2];

    float *A_data_ptr = &(A->data[0]);
    float *R_data_ptr = &(result->data[0]);

    size_t offset = 0;
    for (; (offset + FPGA_MAX_SIZE) < size; offset += FPGA_MAX_SIZE) {
        MatScalarInv128x128(A_data_ptr+offset, R_data_ptr+offset, FPGA_MAX_SIZE);
    }

    size_t remain = size - offset;
    if (remain >= FPGA_MIN_SIZE) {
        MatScalarInv128x128(A_data_ptr+offset, R_data_ptr+offset, remain);
    } else {
        for (; offset < size; offset ++) {
            R_data_ptr[offset] = 1 / A_data_ptr[offset];
        }
    }
    return result;
}

// Sorry, no efficient FPGA implementation here
SmartTensor ScalarMatExp(const SmartTensor& A) {
    SmartTensor result = MatNLike(A, 0.f);
    for (int i = 0; i < A->size[0] * A->size[1] * A->size[2]; i ++) {
        result->data[i] = expf(A->data[i]);
    }
    return result;
}

// Sorry, no efficient FPGA implementation here
SmartTensor ScalarMatLog(const SmartTensor& A) {
    SmartTensor result = MatNLike(A, 0.f);
    for (int i = 0; i < A->size[0] * A->size[1] * A->size[2]; i ++) {
        if (A->data[i] == 0) result->data[i] = logf(0.0001f);
        else result->data[i] = logf(A->data[i]);
    }
    return result;
}

// Efficiently blockify a matrix (extract a submatrix)
// Only support on dim1 and dim2
// [dim1_min, dim1_max) [dim2_min, dim2_max)
SmartTensor Mat_BlockIndexing(const SmartTensor &A, int dim1_min, int dim1_max, int dim2_min, int dim2_max) {
    assert(dim1_min >= 0 && dim1_max <= A->size[1] && dim1_min < dim1_max);
    assert(dim2_min >= 0 && dim2_max <= A->size[2] && dim2_min < dim2_max);
    SmartTensor result = MatNew(A->size[0], dim1_max - dim1_min, dim2_max - dim2_min);

    int dim1_range = dim1_max - dim1_min;
    int dim2_range = dim2_max - dim2_min;

    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < dim1_range; j ++) {
            float *dstBegin = &(result->data[GetIndex(result, i, j, 0)]);
            float *srcBegin = &(A->data[GetIndex(A, i, j + dim1_min, dim2_min)]);
            std::memcpy(dstBegin, srcBegin, sizeof(float) * dim2_range);
        }
    }

    return result;
}

void Mat_BlockWriteback(const SmartTensor &dst, const SmartTensor &blk, int dim1_min, int dim1_max, int dim2_min, int dim2_max) {
    assert(dim1_min >= 0 && dim1_max <= dst->size[1] && dim1_min < dim1_max);
    assert(dim2_min >= 0 && dim2_max <= dst->size[2] && dim2_min < dim2_max);
    assert(dim1_max - dim1_min == blk->size[1]);
    assert(dim2_max - dim2_min == blk->size[2]);

    int dim1_range = dim1_max - dim1_min;
    int dim2_range = dim2_max - dim2_min;

    for (int i = 0; i < dst->size[0]; i ++) {
        for (int j = 0; j < dim1_range; j ++) {
            float *dstBegin = &(dst->data[GetIndex(dst, i, j + dim1_min, dim2_min)]);
            float *srcBegin = &(blk->data[GetIndex(blk, i, j, 0)]);
            std::memcpy(dstBegin, srcBegin, sizeof(float) * dim2_range);
        }
    }
}

SmartTensor MatMul(const SmartTensor& A, const SmartTensor& B) {
    // B, N, M @ B, M, K -> B, N, K
    assert(A->size[0] == B->size[0]);
    assert(A->size[2] == B->size[1]);

    SmartTensor C = MatNew(A->size[0], A->size[1], B->size[2]);
    // std::vector<size_t> A_blk_size1, A_blk_size2, B_blk_size1, B_blk_size2, C_blk_size1, C_blk_size2;
    size_t A_blk_dim1 = (A->size[1] + FPGA_MAX_SIZE_SQRT - 1) / FPGA_MAX_SIZE_SQRT,
           A_blk_dim2 = (A->size[2] + FPGA_MAX_SIZE_SQRT - 1) / FPGA_MAX_SIZE_SQRT,
           B_blk_dim1 = (B->size[1] + FPGA_MAX_SIZE_SQRT - 1) / FPGA_MAX_SIZE_SQRT,
           B_blk_dim2 = (B->size[2] + FPGA_MAX_SIZE_SQRT - 1) / FPGA_MAX_SIZE_SQRT,
           C_blk_dim1 = (C->size[1] + FPGA_MAX_SIZE_SQRT - 1) / FPGA_MAX_SIZE_SQRT,
           C_blk_dim2 = (C->size[2] + FPGA_MAX_SIZE_SQRT - 1) / FPGA_MAX_SIZE_SQRT;
    
    std::vector<SmartTensor> A_blk, B_blk, C_blk;

    // Blockify A
    for (int i = 0; i < A->size[1]; i += FPGA_MAX_SIZE_SQRT) {
        int blk_size1 = std::min(FPGA_MAX_SIZE_SQRT, A->size[1] - i);
        for (int j = 0; j < A->size[2]; j += FPGA_MAX_SIZE_SQRT) {
            int blk_size2 = std::min(FPGA_MAX_SIZE_SQRT, A->size[2] - j);
            A_blk.push_back(Mat_BlockIndexing(A, i, i + blk_size1, j, j + blk_size2));
        }
    }

    // Blockify B
    for (int i = 0; i < B->size[1]; i += FPGA_MAX_SIZE_SQRT) {
        int blk_size1 = std::min(FPGA_MAX_SIZE_SQRT, B->size[1] - i);
        for (int j = 0; j < B->size[2]; j += FPGA_MAX_SIZE_SQRT) {
            int blk_size2 = std::min(FPGA_MAX_SIZE_SQRT, B->size[2] - j);
            B_blk.push_back(Mat_BlockIndexing(B, i, i + blk_size1, j, j + blk_size2));
        }
    }

    // Blocked matrix multiplication
    for (int A_blk_idx1 = 0; A_blk_idx1 < A_blk_dim1; A_blk_idx1 ++) {
        for (int B_blk_idx2 = 0; B_blk_idx2 < B_blk_dim2; B_blk_idx2 ++) {
            int c_dim0 = A->size[0], 
                c_dim1 = A_blk[A_blk_idx1 * A_blk_dim2]->size[1], 
                c_dim2 = B_blk[B_blk_idx2]->size[2];
            
            SmartTensor C_submat     = MatNew(c_dim0, c_dim1, c_dim2);

            for (int A_blk_idx2 = 0; A_blk_idx2 < A_blk_dim2; A_blk_idx2 ++) {
                SmartTensor A_submat = A_blk[A_blk_idx1 * A_blk_dim2 + A_blk_idx2];
                SmartTensor B_submat = B_blk[A_blk_idx2 * B_blk_dim2 + B_blk_idx2];

                SmartTensor C_submat_tmp = MatMul128x128(A_submat, B_submat);
                MatAdd128x128(&(C_submat->data[0]), &(C_submat_tmp->data[0]), &(C_submat->data[0]), c_dim0*c_dim1*c_dim2);
            }

            // Writeback
            Mat_BlockWriteback(
                C, C_submat, 
                A_blk_idx1 * FPGA_MAX_SIZE_SQRT, std::min((A_blk_idx1 + 1) * FPGA_MAX_SIZE_SQRT, C->size[1]),
                B_blk_idx2 * FPGA_MAX_SIZE_SQRT, std::min((B_blk_idx2 + 1) * FPGA_MAX_SIZE_SQRT, C->size[2])
            );
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
    size_t size = A->size[0] * A->size[1] * A->size[2];

    float *A_data_ptr = &(A->data[0]);
    float *B_data_ptr = &(B->data[0]);
    float *R_data_ptr = &(result->data[0]);

    size_t offset = 0;
    for (; (offset + FPGA_MAX_SIZE) < size; offset += FPGA_MAX_SIZE) {
        MatElementwiseMul128x128(A_data_ptr+offset, B_data_ptr+offset, R_data_ptr+offset, FPGA_MAX_SIZE);
    }

    size_t remain = size - offset;
    if (remain >= FPGA_MIN_SIZE) {
        MatElementwiseMul128x128(A_data_ptr+offset, B_data_ptr+offset, R_data_ptr+offset, remain);
    } else {
        for (; offset < size; offset ++) {
            R_data_ptr[offset] = A_data_ptr[offset] * B_data_ptr[offset];
        }
    }

    return result;
}

