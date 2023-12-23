# Math Operators in FPGATorch

## Activation

1. `Sigmoid`
   
   * Element-wise Matrix-Scalar Addition
   * Element-wise Matrix-Scalar Multiplication
   * Element-wise Matrix-Matrix Multiplication
   * Element-wise Matrix-Scalar Division
   * Element-wise Matrix Exp ($e^x$)

2. `Tanh`

   * **Element-wise Matrix `tanh`**
   * **Element-wise Matrix Square (power of 2)**
   * Element-wise Matrix-Scalar Addition
   * Element-wise Matrix-Scalar Multiplication

3. `ReLU`
   
   * Element-wise Clamp (`x < 0 ? 0 : x`)
   * Element-wise Masking (`x[i, j] = y[i, j] < 0 ? 0 : 1`)

## Linear (Fully Connected) Layer

* Matrix-Matrix Multiplication
* Matrix Transpose
* Element-wise Matrix-Matrix Addition
* Element-wise Matrix-Scalar Division

## Loss Functions

1. `CrossEntropyLoss`

   * Matrix Element-wise Exp ($e^x$)
   * Matrix Element-wise Log ($\ln$)
   * Matrix Column-wise Summation
   * Matrix-Matrix Multiplication
   * Matrix-Scalar Multiplication
   * Matrix Transpose
   * Matrix-Matrix Addition

