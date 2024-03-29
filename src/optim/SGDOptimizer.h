#pragma once
#include <vector>
#include "../operator/Linear.h"

namespace Optim {

    class SGDOptimizer {
    public:
        float learning_rate;
        std::vector<Neural::ModuleInterface*> modules;
    public:
        explicit SGDOptimizer(float learning_rate): learning_rate(learning_rate * -1) {}

        void RegisterModule(Neural::ModuleInterface *module) {
            modules.push_back(module);
        }
        void Update() {
            for (const auto module : modules) {
                module->Update(learning_rate);
            }
        }
    };

}
