# Math Operator Spec in FPGATorch

> Last Update: 12/23/2023

## Element-wise Operations

### Element-wise Matrix-Matrix Addition

**Shape Spec**
  
Input
* $A$ - $b \times m \times n$
* $B$ - $b \times m \times n$

Output
* $C$ - $b \times m \times n$
  
**Math Operation**
  
Formula
$$
C_{ijk} = B_{ijk} + A_{ijk}
$$

Einsum
`ijk,ijk -> ijk`

### Element-wise Matrix-Scalar Multiplication

**Shape Spec**

Input
* $A$ - $b\times m \times n$
* $c$ - Scalar `float`

Output
* $B$ - $b \times m \times n$

**Math Operation**

Formula
$$
B_{ijk} = cA_{ijk}
$$

Einsum `N/A`

### Element-wise Matrix-Scalar Division

**Shape Spec**

Input
* $A$ - $b\times m \times n$
* $c$ - Scalar `float`

Output
* $B$ - $b \times m \times n$

**Math Operation**

Formula
$$
B_{ijk} = \frac{1}{c}A_{ijk}
$$

Einsum `N/A`

### Element-wise Matrix Exp

**Shape Spec**

Input
* $A$ - $b \times m \times n$

Output
* $B$ - $b \times m \times n$

**Math Operation**

Formula
$$
B_{ijk} = \exp(A_{ijk})
$$

Einsum - `N/A`

### Element-wise Matrix Log (base $e$)

**Shape Spec**

Input
* $A$ - $b \times m \times n$

Output
* $B$ - $b \times m \times n$

**Math Operation**

Formula
$$
B_{ijk} = \ln(A_{ijk})
$$

Einsum - `N/A`

## Matrix Operations

### Matrix-Matrix Multiplication

**Shape Spec**

Input
* $A$ - $b \times m \times n$
* $B$ - $b \times n \times k$

Output
* $C$ - $b \times m \times k$

**Math Operation**

Formula
$$
C_{ijk} = \sum_{p=1}^{n}{A_{ijp}B_{ipk}}
$$

Einsum - `ijp,ipk->ijk`

### Matrix Transpose

**Shape Spec**

Input
* $A$ - $b \times m \times n$

Output
* $B$ - $b \times n \times m$

**Math Operation**

Formula
$$
B_{ijk} = A_{ikj}
$$

Einsum - `ijk -> ikj`

## Reduce Operator

### Matrix Column-wise Summation

**Shape Spec**

Input
* $A$ - $b \times m \times n$

Output
* $B$ - $b \times m$

**Math Operation**

Formula
$$
B_{ij} = \sum_{k=1}^{n}{A_{ijk}}
$$

Einsum - `ijk -> ij`

