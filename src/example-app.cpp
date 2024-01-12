#include "MatrixInterface.h"
#include "cpu_impl/MatrixImplement.h"
#include "operator/Operator.h"
#include "optim/SGDOptimizer.h"

int main() {
    auto layer1 = Neural::Linear(2, 3, 3);
    auto layer2 = Neural::Linear(2, 3, 3);
    auto loss_fn = Neural::SquareLoss();

    auto network = Neural::Sequential({
        &layer1, &layer2, &loss_fn
    });
    auto optimizer = Optim::SGDOptimizer(0.001f);

    optimizer.RegisterModule(&network);

    layer1.loadModule("./Data/linear1_");
    layer2.loadModule("./Data/linear2_");

    for (int i = 0; i < 1000; i ++) {
        SmartTensor input = load("./Data/input_" + std::to_string(i % 10) + ".matrix");
        SmartTensor loss = network.Forward(input);
        network.Backward(nullptr);
        optimizer.Update();

        std::cout << "Iter " << i << " : " << Get(loss, 0, 0, 0) << std::endl;
    }
    return 0;
}
