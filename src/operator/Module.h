#pragma once
#include "../MatrixInterface.h"

namespace Neural {
    class ModuleInterface {
    public:
        virtual std::shared_ptr<Tensor_t> Forward(std::shared_ptr<Tensor_t> x)         = 0;
        virtual std::shared_ptr<Tensor_t> Backward(std::shared_ptr<Tensor_t> gradient) = 0;
        virtual void Update(float lr) = 0;
        virtual std::string saveModule() = 0;
        virtual void loadModule(const std::string &serialized) = 0;
    };
}
