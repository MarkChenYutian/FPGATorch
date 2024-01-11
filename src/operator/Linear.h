#pragma once
#include "../MatrixInterface.h"

namespace Neural {
    class Linear {
    public:
        Tensor_t *input;
        Tensor_t *weight;
        Tensor_t *bias;
        Tensor_t *grad_weight;
        Tensor_t *grad_bias;
        Tensor_t *ones;
    public:
        Linear(int size, int in_channel, int out_channel):
        input(nullptr), grad_bias(nullptr), grad_weight(nullptr)
        {
            weight = MatNew(1, in_channel, out_channel);
            bias   = MatNew(1, 1, out_channel);
            ones   = MatNew(1, size, 1);
            MatFill_inplace(ones, 1.f);
        }

        ~Linear() {
            MatFree(input);
            MatFree(bias);
            MatFree(weight);
            MatFree(grad_weight);
            MatFree(grad_bias);
            MatFree(ones);
        }

        Tensor_t *Forward(Tensor_t *x) {
            input = x;
            Tensor_t *result_1 = MatMul(input, weight);        // (B, n, c_out)
            Tensor_t *result_2 = MatMul(ones, bias);    // (B, n, c_out)
            Tensor_t *result_3 = MatAdd(result_1, result_2);          // (B, n, c_out)
            MatFree(result_1);
            MatFree(result_2);
            return result_3;
        }

        Tensor_t *Backward(Tensor_t *gradient) {
            Tensor_t *dLdZ = gradient;                                  // Shape: (1, n, c_out)
            Tensor_t *dZdx = MatTrans(weight);                // Shape: (1, c_out, c_in)
            Tensor_t *dZdW = input;                              // Shape: (B, n, c_in)
            Tensor_t *dZdb = ones;                               // Shape: (1, n, 1)

            Tensor_t *dLdZ_T = MatTrans(dLdZ);                          // Shape: (1, c_out, n)

            Tensor_t *dLdx = MatMul(dLdZ, dZdx);                        // Shape: (1, n, c_out) @ (1, c_out, c_in) -> (1, n, c_in)
            Tensor_t *dLdW_tmp = MatMul(dLdZ_T, dZdW);                  // Shape: (1, c_out, n) @ (B, n, c_in) -> (B, c_out, c_in)
            Tensor_t *dLdW = MatTrans(dLdW_tmp);                        // Shape: (B, c_in, c_out)
            MatFree(dLdW_tmp);

            Tensor_t *dLdb_tmp = MatMul(dLdZ_T, dZdb);                  // (1, c_out, n) @ (1, n, 1) -> (1, c_out, 1)
            Tensor_t *dLdb = MatTrans(dLdb_tmp);
            MatFree(dLdb_tmp);

            grad_weight = dLdW;
            grad_bias   = dLdb;

            MatFree(input);
            input=nullptr;
            return dLdx;
        }

        void Update(float lr) {
            Tensor_t *delta_weight = ScalarMatMul(grad_weight, lr);
            Tensor_t *updated_weight = MatAdd(weight, delta_weight);
            MatFree(weight);
            MatFree(delta_weight);
            MatFree(grad_weight);
            grad_weight = nullptr;
            weight = updated_weight;

            Tensor_t *delta_bias = ScalarMatMul(grad_bias, lr);
            Tensor_t *updated_bias = MatAdd(bias, delta_bias);
            MatFree(bias);
            MatFree(delta_bias);
            MatFree(grad_bias);
            grad_bias = nullptr;
            bias = updated_bias;
        }

        void saveModule(const std::string& prefix) {
            std::string weight_path = prefix + "weight.matrix";
            std::string bias_path   = prefix + "bias.matrix";
            save(weight_path, weight);
            save(bias_path, bias);
        }

        void loadModule(const std::string& prefix) {
            std::string weight_path = prefix + "weight.matrix";
            std::string bias_path   = prefix + "bias.matrix";
            MatFree(weight);
            MatFree(bias);
            weight = load(weight_path);
            bias   = load(bias_path);
        }
    };
}
