#include "MatrixInterface.h"
#include <string>
#include <iomanip>
#include <sstream>
#include <iostream>
#include <fstream>

int getLabel(const SmartTensor& softmax) {
    float max_value = -1.f;
    int pos = -1;
    for (int i = 0; i < softmax->size[1]; i ++) {
        if (Get(softmax, 0, i, 0) > max_value) {
            max_value = Get(softmax, 0, i, 0);
            pos = i;
        }
    }
    return pos;
}

std::string readFileAsString(const std::string& filename) {
    std::ifstream ifs(filename);
    if (!ifs) {
        throw std::runtime_error("Cannot open file: " + filename);
    }
    std::stringstream buffer;
    buffer << ifs.rdbuf();
    return buffer.str();
}

void FlushInterface(SmartTensor image, int pred, int label, float accuracy) {
    system("clear");
    for (int i = 0; i < 28; i ++) {
        std::cout << "|\t";
        for (int j = 0; j < 28; j ++) {
            std::cout << (Get(image, 0, 0, i*28 + j) > 0 ? "@" : " ");
        }
        std::cout << "|\t\n";
    }
    std::cout << "\n------------------------------------------\n";
    std::cout << "Predict\t" << pred << "\t| Actual\t" << label << std::endl;
    std::cout << "Acc\t" << accuracy * 100 << " %" << std::endl;
    return;
}
