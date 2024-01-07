/** 
 * An extremely naive implementation of the MatrixInterface for demonstration 
 * Yutian, Dec 29, 2023
 * To compile: 
 * $ gcc cpu_impl.c -lm -g -Wall
 * */

#include <stdlib.h>
#include <math.h>
#include <stdio.h>

int getIdx(int b, int m, int n, int i, int j, int k) {
    return i * (m * n) + j * n + k;
}

float *MatAdd(float *A, float *B, int b, int m, int n) {
    float *Result = malloc(sizeof(float) * b * m * n);
    for (int i = 0; i < b; i ++) {
        for (int j = 0; j < m; j ++) {
            for (int k = 0; k < n; k ++) {
                int idx = getIdx(b, m, n, i, j, k);
                Result[idx] = A[idx] + B[idx];
            }
        }
    }
    return Result;
}

float *ScalarMatMul(float *A, float c, int b, int m, int n) {
    float *Result = malloc(sizeof(float) * b * m * n);
    for (int i = 0; i < b; i ++) {
        for (int j = 0; j < m; j ++) {
            for (int k = 0; k < n; k ++) {
                int idx = getIdx(b, m, n, i, j, k);
                Result[idx] = A[idx] * c;
            }
        }
    }
    return Result;
}


float *ScalarMatDiv(float *A, float c, int b, int m, int n) {
    float *Result = malloc(sizeof(float) * b * m * n);
    for (int i = 0; i < b; i ++) {
        for (int j = 0; j < m; j ++) {
            for (int k = 0; k < n; k ++) {
                int idx = getIdx(b, m, n, i, j, k);
                Result[idx] = A[idx] / c;
            }
        }
    }
    return Result;
}


float *ScalarMatAdd(float *A, float c, int b, int m, int n) {
    float *Result = malloc(sizeof(float) * b * m * n);
    for (int i = 0; i < b; i ++) {
        for (int j = 0; j < m; j ++) {
            for (int k = 0; k < n; k ++) {
                int idx = getIdx(b, m, n, i, j, k);
                Result[idx] = A[idx] + c;
            }
        }
    }
    return Result;
}


float *MatExp(float *A, int b, int m, int n) {
    float *Result = malloc(sizeof(float) * b * m * n);
    for (int i = 0; i < b; i ++) {
        for (int j = 0; j < m; j ++) {
            for (int k = 0; k < n; k ++) {
                int idx = getIdx(b, m, n, i, j, k);
                Result[idx] = exp(A[idx]);
            }
        }
    }
    return Result;
}


float *MatInv(float *A, int b, int m, int n) {
    float *Result = malloc(sizeof(float) * b * m * n);
    for (int i = 0; i < b; i ++) {
        for (int j = 0; j < m; j ++) {
            for (int k = 0; k < n; k ++) {
                int idx = getIdx(b, m, n, i, j, k);
                Result[idx] = 1 / A[idx];
            }
        }
    }
    return Result;
}


float *MatLog(float *A, int b, int m, int n) {
    float *Result = malloc(sizeof(float) * b * m * n);
    for (int i = 0; i < b; i ++) {
        for (int j = 0; j < m; j ++) {
            for (int k = 0; k < n; k ++) {
                int idx = getIdx(b, m, n, i, j, k);
                Result[idx] = log(A[idx]);
            }
        }
    }
    return Result;
}



float *MatMul(float *A, float *B, int b, int m, int n, int k) {
    float *Result = malloc(sizeof(float) * b * m * k);
    for (int p = 0; p < b; p ++) {
        for (int q = 0; q < m; q ++) {
            for (int r = 0; r < k; r ++) {
                int Ridx = getIdx(b, m, k, p, q, r);
                Result[Ridx] = 0.f;
                for (int s = 0; s < n; s++) {
                    int Aidx = getIdx(b, m, n, p, q, s);
                    int Bidx = getIdx(b, n, k, p, s, r);
                    Result[Ridx] += A[Aidx] * B[Bidx];
                }
            }
        }
    }
    return Result;
}


float *MatTrans(float *A, int b, int m, int n) {
    float *Result = malloc(sizeof(float) * b * m * n);
    for (int i = 0; i < b; i ++) {
        for (int j = 0; j < m; j ++) {
            for (int k = 0; k < n; k ++) {
                int srcIdx = getIdx(b, m, n, i, j, k);
                int dstIdx = getIdx(b, n, m, i, k, j);
                Result[dstIdx] = A[srcIdx];
            }
        }
    }
    return Result;
}


float *MatReduceSum(float *A, int b, int m, int n) {
    float *Result = malloc(sizeof(float) * b * n);
    for (int i = 0; i < b; i ++) {
        for (int k = 0; k < n; k ++) {
            Result[i * n + k] = 0;
            for (int j = 0; j < m; j ++) {
                Result[i * n + k] += A[getIdx(b, m, n, i, j, k)];
            }        
        }
    }
    return Result;
}


void PrintMatDebug(float *A, int b, int m, int n) {
    for (int i = 0; i < b; i ++) {
        printf("Batch %d\n", i);
        for (int j = 0; j < m; j ++) {
            for (int k = 0; k < n; k ++) {
                int srcIdx = getIdx(b, m, n, i, j, k);
                printf("%4f ", A[srcIdx]);
            }
            printf("\n");
        }
    }
}

int main() {
    float *A = calloc(sizeof(float), 4);
    A[0] = 1.f; A[1] = 2.f; A[2] = 3.f; A[3] = 4.f;
    float *A_T = MatTrans(A, 1, 2, 2);
    float *B = MatAdd(A, A_T, 1, 2, 2);
    float *C = MatReduceSum(A, 1, 2, 2);
    float *D = MatMul(A, A, 1, 2, 2, 2);

    PrintMatDebug(A, 1, 2, 2);
    PrintMatDebug(A_T, 1, 2, 2);
    PrintMatDebug(B, 1, 2, 2);
    PrintMatDebug(C, 1, 1, 2);
    PrintMatDebug(D, 1, 2, 2);

    float *A_ = MatTrans(A, 2, 1, 2);       // 2, 1, 2 -> 2, 2, 1
    float *B_ = calloc(sizeof(float), 4);
    B_[0] = 5.f; B_[1] = 6.f; B_[2] = 7.f; B_[3] = 8.f;

    float *C_ = MatMul(A_, B_, 2, 2, 1, 2);   // (2,2,1) @ (2,1,2) -> (2,2,2)
    PrintMatDebug(A_, 2, 2, 1);
    PrintMatDebug(B_, 2, 1, 2);
    PrintMatDebug(C_, 2, 2, 2);

    free(A);
    free(A_T);
    free(B);
    free(C);
    free(D);
    free(A_);
    free(B_);
    free(C_);
    return 0;
}


