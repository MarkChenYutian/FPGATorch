#pragma once
#include "MatrixInterface.h"
/* Linear Layer operations */

struct LinearLayer {
    Tensor_t *x;
    Tensor_t *weight;
    Tensor_t *bias;
    Tensor_t *grad_weight;
    Tensor_t *grad_bias;
    Tensor_t *ones;
};

typedef struct LinearLayer LinearLayer_t;

LinearLayer_t *newLinear(int size, int in_channel, int out_channel);
void LinearFree(LinearLayer_t *layer);
Tensor_t *LinearForward(LinearLayer_t *layer, Tensor_t *input);
Tensor_t *LinearBackward(LinearLayer_t *layer, Tensor_t *gradient);
void LinearUpdate(LinearLayer_t *layer, float lr);

