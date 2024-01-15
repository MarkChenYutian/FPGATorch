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

        std::string saveModule() override {
            std::string result;
            for (const auto module : subModules) {
                result += module->saveModule();
                result += "---\n";
            }
            return result;
        };

        void loadModule(const std::string &serialized) override {
            std::string_view temp = serialized;
            size_t start = 0, end = temp.find("---");
            for (const auto module : subModules) {
                 module->loadModule(std::string(temp));
                 temp = temp.substr(end + 4);
                 end = temp.find("---");
            }
        };
    };

} // Neural
