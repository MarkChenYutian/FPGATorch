#include "MatrixInterface.h"
#include <stdlib.h>
#include <assert.h>
#include "Operator.h"

LinearLayer_t *newLinear(int size, int in_channel, int out_channel) {
    LinearLayer_t *result = calloc(1, sizeof(LinearLayer_t));
    result->weight = MatNew(1, in_channel, out_channel);
    result->bias   = MatNew(1, 1, out_channel);
    result->ones   = MatNew(1, size, 1);
    result->x = NULL;
    result->grad_bias = NULL;
    result->grad_weight = NULL;
    return result;
}

void LinearFree(LinearLayer_t *layer) {
    if (layer == NULL) return;
    MatFree(layer->weight);
    MatFree(layer->bias);
    MatFree(layer->grad_weight);
    MatFree(layer->grad_bias);
    MatFree(layer->ones);
    free(layer);
}

/**
 * A fully-connected layer implemented using Matrix Interface
 * Shape:
 *  B - batch size
 *  c_in  - channel count / feature map count of input'
 *  c_out - channel count / feature map count of output
 *  n - width / size of input data
 *
 * @param x      - Shape (B, n, c_in)
 * @param weight - Shape (1, c_in, c_out)
 * @param bias   - shape (1, 1, c_out)
 * @param ones   - shape (1, n, 1)
 * @return - shape (B, n, c_out)
 */
Tensor_t *LinearForward(LinearLayer_t *layer, Tensor_t *input) {
    assert(layer->x == NULL);   // Calling forward() for multiple passes before calling backward()
    assert(input->size[1] == layer->ones->size[1]); // Shape must match!

    layer->x = input;
    Tensor_t *result_1 = MatMul(input, layer->weight);        // (B, n, c_out)
    Tensor_t *result_2 = MatMul(layer->ones, layer->bias);    // (B, n, c_out)
    Tensor_t *result_3 = MatAdd(result_1, result_2);          // (B, n, c_out)
    MatFree(result_1);
    MatFree(result_2);
    return result_3;
}

Tensor_t *LinearBackward(LinearLayer_t *layer, Tensor_t *gradient) {
    assert (layer->x != NULL);  // Calling backward() before forward()!

    Tensor_t *dLdZ = gradient;                                   // Shape: (1, n, c_out)
    Tensor_t *dZdx = MatTrans(layer->weight);                 // Shape: (1, c_out, c_in)
    Tensor_t *dZdW = layer->x;                                   // Shape: (B, n, c_in)
    Tensor_t *dZdb = layer->ones;                                // Shape: (1, n, 1)

    Tensor_t *dLdZ_T = MatTrans(dLdZ);                // Shape: (1, c_out, n)

    Tensor_t *dLdx = MatMul(dLdZ, dZdx);       // Shape: (1, n, c_out) @ (1, c_out, c_in) -> (1, n, c_in)
    Tensor_t *dLdW_tmp = MatMul(dLdZ_T, dZdW); // Shape: (1, c_out, n) @ (B, n, c_in) -> (B, c_out, c_in)
    Tensor_t *dLdW = MatTrans(dLdW_tmp);          // Shape: (B, c_in, c_out)
    MatFree(dLdW_tmp);

    Tensor_t *dLdb_tmp = MatMul(dLdZ_T, dZdb);  // (1, c_out, n) @ (1, n, 1) -> (1, c_out, 1)
    Tensor_t *dLdb = MatTrans(dLdb_tmp);
    MatFree(dLdb_tmp);

    layer->grad_weight = dLdW;
    layer->grad_bias   = dLdb;

    MatFree(layer->x);
    layer->x = NULL;
    return dLdx;
}

void LinearUpdate(LinearLayer_t *layer, float lr) {
    assert(layer->grad_bias != NULL);   // Calling update() before calling backward()!
    assert(layer->grad_weight != NULL); // Calling update() before calling backward()!

    Tensor_t *delta_weight = ScalarMatMul(layer->grad_weight, lr);
    Tensor_t *updated_weight = MatAdd(layer->weight, delta_weight);
    MatFree(layer->weight);
    MatFree(delta_weight);
    MatFree(layer->grad_weight);
    layer->grad_weight = NULL;
    layer->weight = updated_weight;

    Tensor_t *delta_bias = ScalarMatMul(layer->grad_bias, lr);
    Tensor_t *updated_bias = MatAdd(layer->bias, delta_bias);
    MatFree(layer->bias);
    MatFree(delta_bias);
    MatFree(layer->grad_bias);
    layer->grad_bias = NULL;
    layer->bias = updated_bias;
}
