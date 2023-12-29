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
