#pragma once
#include "../MatrixInterface.h"
#include "Module.h"

namespace Neural {

    class ReLU : public ModuleInterface{
    public:
        SmartTensor mask;
    public:
        SmartTensor Forward(SmartTensor x) override {
            mask = ScalarGetGTMask(x, 0.f);
            SmartTensor output = MatElementwiseMul(x, mask);
            return output;
        }

        SmartTensor Backward(SmartTensor gradient) override {
            return MatElementwiseMul(gradient, mask);
        }

        void Update(float lr) override {}
        void saveModule(const std::string &prefix) override {}
        void loadModule(const std::string &prefix) override {}
    };

} // Neural

