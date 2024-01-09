//
// Created by Yutian on 1/6/2024.
//
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>
#include "../MatrixInterface.h"

#ifdef DEBUG
#define DBG_ASSERT(arg) assert(arg);
#else
#define DBG_ASSERT(arg) (void)0;
#endif

Tensor_t *MatNew(int dim0, int dim1, int dim2) {
    Tensor_t *matrix = malloc(sizeof(Tensor_t));
    matrix->data = calloc(sizeof(float), dim0 * dim1 * dim2);
    matrix->size[0] = dim0;
    matrix->size[1] = dim1;
    matrix->size[2] = dim2;
    return matrix;
}

void MatFree(Tensor_t *mat) {
    if (mat == NULL) return;
    free(mat->data);
    free(mat);
}

float Get(Tensor_t *A, int dim0, int dim1, int dim2) {
    int offset0 = dim0 * A->size[1] * A->size[2];
    int offset1 = dim1 * A->size[2];
    int offset2 = dim2;
    return A->data[offset0 + offset1 + offset2];
}

void Set(Tensor_t *A, int dim0, int dim1, int dim2, float value) {
    int offset0 = dim0 * A->size[1] * A->size[2];
    int offset1 = dim1 * A->size[2];
    int offset2 = dim2;
    A->data[offset0 + offset1 + offset2] = value;
}

Tensor_t *MatAdd(Tensor_t *A, Tensor_t *B) {
    DBG_ASSERT(A->size[0] == B->size[0]);
    DBG_ASSERT(A->size[1] == B->size[1]);
    DBG_ASSERT(A->size[2] == B->size[2]);
    Tensor_t *C = MatNew(A->size[0], A->size[1], A->size[2]);

    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                float value = Get(A, i, j, k) + Get(B, i, j, k);
                Set(C, i, j, k, value);
    }}}
    return C;
}

Tensor_t *ScalarMatMul(Tensor_t *A, float scalar) {
    Tensor_t *C = MatNew(A->size[0], A->size[1], A->size[2]);

    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                float value = Get(A, i, j, k) * scalar;
                Set(C, i, j, k, value);
            }}}
    return C;
}

Tensor_t *ScalarMatDiv(Tensor_t *A, float scalar) {
    DBG_ASSERT(scalar != 0);

    Tensor_t *C = MatNew(A->size[0], A->size[1], A->size[2]);

    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                float value = Get(A, i, j, k) / scalar;
                Set(C, i, j, k, value);
            }}}
    return C;
}

Tensor_t *ScalarMatAdd(Tensor_t *A, float scalar) {
    DBG_ASSERT(A->size[0] == B->size[0]);
    DBG_ASSERT(A->size[1] == B->size[1]);
    DBG_ASSERT(A->size[2] == B->size[2]);
    DBG_ASSERT(scalar != 0);

    Tensor_t *C = MatNew(A->size[0], A->size[1], A->size[2]);

    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                float value = Get(A, i, j, k) + scalar;
                Set(C, i, j, k, value);
            }}}
    return C;
}

Tensor_t *ScalarMatInv(Tensor_t *A) {
    Tensor_t *C = MatNew(A->size[0], A->size[1], A->size[2]);

    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                float value = 1.f / Get(A, i, j, k);
                Set(C, i, j, k, value);
            }}}
    return C;
}

Tensor_t *ScalarMatExp(Tensor_t *A) {
    Tensor_t *C = MatNew(A->size[0], A->size[1], A->size[2]);

    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                float value = expf(Get(A, i, j, k));
                Set(C, i, j, k, value);
            }}}
    return C;
}

Tensor_t *ScalarMatLog(Tensor_t *A) {
    Tensor_t *C = MatNew(A->size[0], A->size[1], A->size[2]);

    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                float value = logf(Get(A, i, j, k));
                Set(C, i, j, k, value);
            }}}
    return C;
}

Tensor_t *MatMul(Tensor_t *A, Tensor_t *B) {
    // B, N, M @ B, M, K -> B, N, K
    DBG_ASSERT(A->size[0] == B->size[0]);
    DBG_ASSERT(A->size[2] == B->size[1]);
    Tensor_t *C = MatNew(A->size[0], A->size[1], B->size[2]);

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

Tensor_t *MatTrans(Tensor_t *A) {
    Tensor_t *B = MatNew(A->size[0], A->size[2], A->size[1]);
    for (int i = 0; i < A->size[0]; i ++) {
        for (int j = 0; j < A->size[1]; j ++) {
            for (int k = 0; k < A->size[2]; k ++) {
                Set(B, i, k, j, Get(A, i, j, k));
            }
        }
    }
    return B;
}

Tensor_t *ReduceSum(Tensor_t *A, int dim) {
    Tensor_t *Result;
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

void MatPrint(Tensor_t *A) {
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
