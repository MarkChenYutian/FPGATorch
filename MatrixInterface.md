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

The `16.16` fixed point number will be denoted as `fix16_t` type below.

```c

typedef int32_t fix16_t;

// Add A (b*m*n) and B (b*m*n) element-wise
fix16_t *MatAdd(fix16_t *A, fix16_t *B, int b, int m, int n);

// Multiply A (b*m*n) and scalar c element-wise
fix16_t *ScalarMatMul(fix16_t *A, fix16_t c, int b, int m, int n);

// Divide A (b*m*n) and scalar c element-wise
fix16_t *ScalarMatDiv(fix16_t *A, fix16_t c, int b, int m, int n);

// Perform exponentiation (base e) on A (b*m*n) element-wise
fix16_t *MatExp(fix16_t *A, int b, int m, int n);

// Perform logarithm (base e) on A (b*m*n) element-wise
fix16_t *MatLog(fix16_t *A, int b, int m, int n);

// Perform matrix multiplication on A (b*m*n) and B (B*n*k)
fix16_t *MatMul(fix16_t *A, fix16_t *B, int b, int m, int n, int k);

// Perform matrix transpose on A (b*m*n)
fix16_t *MatTrans(fix16_t *A, int b, int m, int n);

// Reduction - sum on second axis of A (b*m*n) -> (b*n)
fix16_t *MatReduceSum(fix16_t *A, int b, int m, int n);

```