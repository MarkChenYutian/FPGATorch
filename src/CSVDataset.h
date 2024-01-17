#pragma once
#include <vector>
#include "MatrixInterface.h"
#include <iostream>
#include <fstream>

class CSVDataset {
public:
    std::vector<SmartTensor> mvData;
    std::vector<SmartTensor> mvLabel;

public:
    explicit CSVDataset(const std::string &dataName, const std::string &labelName) {
        std::cout << "Loading ..." << std::flush;

        std::ifstream dataFile;
        dataFile.open(dataName, std::ios::in);
        if (!dataFile.is_open()) {
            std::cout << "Unable to read tensor from the file" << dataName << std::endl;
        }
        std::string line;
        while (getline(dataFile, line)) {
            mvData.push_back(deserialize(line));
        }

        std::ifstream labelFile;
        labelFile.open(labelName, std::ios::in);
        if (!labelFile.is_open()) {
            std::cout << "Unable to read tensor from the file" << labelName << std::endl;
        }
        while (getline(labelFile, line)) {
            mvLabel.push_back(deserialize(line));
        }

        std::cout << "\rLoad Finish" << std::endl;
    }
};

