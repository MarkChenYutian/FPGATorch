#pragma once
#include <memory>
#include <iostream>
#include "../MatrixInterface.h"
#include "Module.h"


namespace Neural {
    class Linear : public ModuleInterface {
    public:
        SmartTensor input;
        SmartTensor weight;
        SmartTensor bias;
        SmartTensor grad_weight;
        SmartTensor grad_bias;
        SmartTensor ones;
    public:
        Linear(int size, int in_channel, int out_channel, float init_std=0.1f, float init_mean=0.f):
        input(nullptr), grad_bias(nullptr), grad_weight(nullptr)
        {
            weight = MatRandN(1, in_channel, out_channel, init_mean, init_std);
            bias = MatNew(1, 1, out_channel);
            ones = MatNew(1, size, 1);
            MatFill_inplace(ones, 1.f);
        }

        SmartTensor Forward(std::shared_ptr<Tensor_t> x) override {
            input = x;
            SmartTensor result_1 = MatMul(input, weight);        // (B, n, c_out)
            SmartTensor result_2 = MatMul(ones, bias);    // (B, n, c_out)
            SmartTensor result_3 = MatAdd(result_1, result_2);          // (B, n, c_out)
            return result_3;
        }

        SmartTensor Backward(SmartTensor gradient) override {
            SmartTensor dLdZ = gradient;                           // Shape: (1, n, c_out)
            SmartTensor dZdx = MatTrans(weight);                // Shape: (1, c_out, c_in)
            SmartTensor dZdW = input;                              // Shape: (B, n, c_in)
            SmartTensor dZdb = ones;                               // Shape: (1, n, 1)

            SmartTensor dLdZ_T = MatTrans(dLdZ);                // Shape: (1, c_out, n)

            SmartTensor dLdx = MatMul(dLdZ, dZdx);           // Shape: (1, n, c_out) @ (1, c_out, c_in) -> (1, n, c_in)
            SmartTensor dLdW_tmp = MatMul(dLdZ_T, dZdW);     // Shape: (1, c_out, n) @ (B, n, c_in) -> (B, c_out, c_in)
            SmartTensor dLdW = MatTrans(dLdW_tmp);              // Shape: (B, c_in, c_out)

            SmartTensor dLdb_tmp = MatMul(dLdZ_T, dZdb);     // (1, c_out, n) @ (1, n, 1) -> (1, c_out, 1)
            SmartTensor dLdb = MatTrans(dLdb_tmp);

            grad_weight = dLdW;
            grad_bias   = dLdb;

            input=nullptr;
            return dLdx;
        }

        void Update(float lr) override {
            SmartTensor delta_weight = ScalarMatMul(grad_weight, lr);
            SmartTensor updated_weight = MatAdd(weight, delta_weight);
            grad_weight = nullptr;
            weight = updated_weight;

            SmartTensor delta_bias = ScalarMatMul(grad_bias, lr);
            SmartTensor updated_bias = MatAdd(bias, delta_bias);
            grad_bias = nullptr;
            bias = updated_bias;
        }

//        void saveModule(const std::string& prefix) override {
//            std::string weight_path = prefix + "weight.matrix";
//            std::string bias_path   = prefix + "bias.matrix";
//            save(weight_path, weight);
//            save(bias_path, bias);
//        }
//
//        void loadModule(const std::string& prefix) override {
//            std::string weight_path = prefix + "weight.matrix";
//            std::string bias_path   = prefix + "bias.matrix";
//            weight = load(weight_path);
//            bias   = load(bias_path);
//        }

        std::string saveModule() override {
            return "MODULE_LIENAR.weight " + serialize(weight)
                 + "MODULE_LINEAR.bias "   + serialize(bias);
        };

        void loadModule(const std::string &serialized) override {
            std::istringstream iss(serialized);
            std::string line;
            std::getline(iss, line);
            weight = deserialize(line.substr(21));

            std::getline(iss, line);
            bias = deserialize(line.substr(19));
        };
    };
}
