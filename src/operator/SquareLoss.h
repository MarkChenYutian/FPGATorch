#pragma once
#include "../MatrixInterface.h"
#include "Module.h"

namespace Neural {

    class SquareLoss: public ModuleInterface {
    public:
        SmartTensor input;
    public:
        SquareLoss(): input(nullptr) {}

        SmartTensor Forward(SmartTensor x) override {
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
            SmartTensor resultTensor = MatNew(1, 1 ,1);
            MatFill_inplace(resultTensor, result);
            return resultTensor;
        }

        SmartTensor Backward(SmartTensor gradient) override {
            SmartTensor gradient_back = ScalarMatMul(input, 2.f);
            input = nullptr;
            return gradient_back;
        }

        void Update(float lr) override {};

        void saveModule(const std::string &prefix) override {};
        void loadModule(const std::string &prefix) override {};
    };

}
