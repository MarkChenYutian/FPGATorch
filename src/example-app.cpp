#include "MatrixInterface.h"
#include "cpu_impl/MatrixImplement.h"
#include "operator/Linear.h"
#include "operator/SquareLoss.h"
#include "optim/SGDOptimizer.h"

int main() {
    auto layer = Neural::Linear(2, 3, 1);
    auto loss  = Neural::SquareLoss();
    auto optimizer = Optim::SGDOptimizer(0.1f);
    optimizer.RegisterModule(&layer);

    layer.loadModule("./Data/linear_");

    auto frozen_layer = Neural::Linear(2, 3, 1);
    auto frozen_loss = Neural::SquareLoss();
    frozen_layer.loadModule("./Data/linear_");

    for (int i = 0; i < 100; i ++) {
        Tensor_t *res0 = load("./Data/input_" + std::to_string(i % 10) + ".matrix");
        Tensor_t *res1 = layer.Forward(res0);
        Tensor_t *res2 = loss.Forward(res1);

        Tensor_t *frozen_res1 = frozen_layer.Forward(res0);
        Tensor_t *frozen_res2 = frozen_loss.Forward(frozen_res1);

        std::cout << "With optimization: " << Get(res2, 0, 0, 0) << " | Frozen: " << Get(frozen_res2, 0, 0, 0) << std::endl;

        Tensor_t *grad1 = loss.Backward(nullptr);
        Tensor_t *grad0 = layer.Backward(grad1);

        optimizer.Update();
    }
    return 0;
}
