#include "MatrixInterface.h"
#ifdef ONFPGA
  #include "fpga_impl/MatrixImplement.h"
  #include "fpga_impl/FPGAInterface.h"
#else
  #include "cpu_impl/MatrixImplement.h"
#endif

#include "operator/Operator.h"
#include "optim/SGDOptimizer.h"
#include "CSVDataset.h"
#include "Utility.h"

void loadModel(Neural::Sequential network) {
    std::string weight_serial = readFileAsString("../Network.matrix");
    network.loadModule(weight_serial);
}

int main() {
#ifdef ONFPGA
      MMap_Init();
#endif

    auto dataset = CSVDataset("../value.csv", "../label.csv");

    auto layer1 = Neural::Linear(1, 784, 128);
    auto active1 = Neural::ReLU();
    auto layer2 = Neural::Linear(1, 128, 128);
    auto active2 = Neural::ReLU();
    auto layer3 = Neural::Linear(1, 128, 10);
    auto loss_fn = Neural::XEntropy();

    auto network = Neural::Sequential({
        &layer1, &active1, &layer2, &active2, &layer3
    });

    auto optimizer = Optim::SGDOptimizer(0.001f);
    float correct_count = 0;

    optimizer.RegisterModule(&network);

   for (int i = 0; i < dataset.mvData.size(); i ++) {
        SmartTensor input = dataset.mvData[i];
        SmartTensor label = dataset.mvLabel[i];

        SmartTensor output = network.Forward(input);
        float loss = loss_fn.Forward(output, label);

        int label_val = getLabel(MatTrans(label));
        int pred_val = getLabel(loss_fn.softmax);
        correct_count += label_val == pred_val ? 1 : 0;

        SmartTensor gradient_in = loss_fn.Backward(nullptr);
        network.Backward(gradient_in);
        optimizer.Update();

        FlushInterface(input, pred_val, label_val, (correct_count / static_cast<float>(i + 1)));
    }


    std::ofstream dumpFile;
    dumpFile.open("../Network.matrix", std::ios::trunc);
    if (!dumpFile.is_open()) {
        std::cerr << "Unable to dump tensor to the file " << "../Network.matrix" << std::endl;
    }
    dumpFile << network.saveModule() << "\n";
    dumpFile.close();
    return 0;
}
