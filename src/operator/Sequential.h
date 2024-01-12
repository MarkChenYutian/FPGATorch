#pragma once
#include "Module.h"
#include <utility>
#include <iostream>
#include <vector>

namespace Neural {

    class Sequential : public ModuleInterface {
    public:
        std::vector<ModuleInterface*> subModules;
    public:
        explicit Sequential(std::vector<ModuleInterface*> submodules) {
            subModules = std::move(submodules);
        }

        SmartTensor Forward(SmartTensor x) override {
            for (const auto module : subModules) {
                x = module->Forward(x);
            }
            return x;
        }

        SmartTensor Backward(SmartTensor gradient) override {
            for (auto it = subModules.rbegin(); it != subModules.rend(); ++it) {
                gradient = (*it)->Backward(gradient);
            }
            return gradient;
        }

        void Update(float lr) override {
            for (const auto module : subModules) {
                module->Update(lr);
            }
        }

        void saveModule(const std::string &prefix) override {

        };

        void loadModule(const std::string &prefix) override {

        };
    };

} // Neural
