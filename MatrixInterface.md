# Matrix Interface (Draft)

## Summary

The matrix interface will behave as a unified interface for math operators used in the project. Specifically, the Matrix Interface will support math operators implemented in C (which will execute on CPU) and executed on hardware.

This layer of interface and abstraction allow the software side to build up an implementation-robust neural network module and can perform unit test on FPGA-executed operators.

## Data Representation

The data used in this project will be mostly the 3-dimension matrices with generic shape of $b \times m \times n$. 

The data will be stored in a fixed-point (`16.16` - 32 bit, 16 bits integer, 16 bits fractional) format in a contiguous memory block.

For software (CPU, C language) side, the algorithmic operations will be performed using the `libfixmath` - https://github.com/PetteriAimonen/libfixmath

For the hardware side (FPGA), ...


## Interface

```c


// Add A (b*m*n) and B (b*m*n) element-wise
float *MatAdd(float *A, float *B, int b, int m, int n);

// Multiply A (b*m*n) and scalar c element-wise
float *ScalarMatMul(float *A, float c, int b, int m, int n);

// Divide A (b*m*n) and scalar c element-wise
float *ScalarMatDiv(float *A, float c, int b, int m, int n);

// Add A (b*m*n) and scalar c element-wise
float *ScalarMatAdd(float *A, float c, int b, int m, int n);

// For every A_ij, turn into (1/A_ij) (not linear algebra inverse, A^{-1})
float *MatInv(float *A, int b, int m, int n);

// Perform exponentiation (base e) on A (b*m*n) element-wise
float *MatExp(float *A, int b, int m, int n);

// Perform logarithm (base e) on A (b*m*n) element-wise
float *MatLog(float *A, int b, int m, int n);

// Perform matrix multiplication on A (b*m*n) and B (b*n*k)
float *MatMul(float *A, float *B, int b, int m, int n, int k);

// Perform matrix transpose on A (b*m*n)
float *MatTrans(float *A, int b, int m, int n);

// Reduction - sum on second axis of A (b*m*n) -> (b*n)
float *MatReduceSum(float *A, int b, int m, int n);

```