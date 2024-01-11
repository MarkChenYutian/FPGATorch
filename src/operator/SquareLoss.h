#pragma once
#include "../MatrixInterface.h"

namespace Neural {

    class SquareLoss {
    public:
        Tensor_t *input;
    public:
        ~SquareLoss() {
            MatFree(input);
        }

        Tensor_t *Forward(Tensor_t *x) {
            input = x;
            float result = 0;
            for (int i = 0; i < x->size[0]; i ++) {
                for (int j = 0; j < x->size[1]; j ++) {
                    for (int k = 0; k < x->size[2]; k ++) {
                        float value = Get(x, i, j, k);
                        result += value * value;
                    }
                }
            }
            Tensor_t *resultTensor = MatNew(1, 1 ,1);
            MatFill_inplace(resultTensor, result);
            return resultTensor;
        }

        Tensor_t *Backward(Tensor_t *gradient) {
            Tensor_t *gradient_back = ScalarMatMul(input, 2.f);
            MatFree(input);
            input = nullptr;
            return gradient_back;
        }

        void Update(float lr) {};

        void saveModule(const std::string &prefix) {};
        void loadModule(const std::string &prefix) {};
    };

}