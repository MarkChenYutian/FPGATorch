import numpy as np

def generate_matrix(size):
    """Generates a square matrix of given size with random elements."""
    return np.random.randint(1, 10, (size, size))

def main():
    # Size of the matrices
    size = 8

    # Generate two 8x8 matrices
    matrix1 = generate_matrix(size)
    matrix2 = generate_matrix(size)

    # Compute the product of the two matrices
    product = np.dot(matrix1, matrix2)

    # Print the matrices and their product
    print("Matrix 1:\n", matrix1)
    print("\nMatrix 2:\n", matrix2)
    print("\nProduct of Matrix 1 and Matrix 2:\n", product)

    # Print the flattened matrices
    print("\nFlattened Matrix 1 (Reversed):", ', '.join(map(str, matrix1.flatten()[::-1])))
    print("Flattened Matrix 2 (Reversed):", ', '.join(map(str, matrix2.flatten()[::-1])))


if __name__ == "__main__":
    main()
