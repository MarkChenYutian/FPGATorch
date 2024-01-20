cmake_minimum_required(VERSION 2.8 FATAL_ERROR)
project(FPGATorchDemo)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++11")

# Cross-compilation settings
set(CROSS_COMPILE /home/yutian/intelFPGA/19.1/embedded/ds-5/sw/gcc/bin/arm-linux-gnueabihf-)
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Compiler settings
if (FPGA) 
        set(CMAKE_CXX_COMPILER ${CROSS_COMPILE}c++)
endif()
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -Wall")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g -Wall")

# FPGA specific variables
set(ALT_DEVICE_FAMILY soc_cv_av)
set(SOCEDS_ROOT $ENV{SOCEDS_DEST_ROOT})
set(HWLIBS_ROOT ${SOCEDS_ROOT}/ip/altera/hps/altera_hps/hwlib)

add_executable(FPGATorch
        MatrixInterface.h

        cpu_impl/MatrixImplement.h

        operator/Linear.h
        operator/SquareLoss.h
        operator/Operator.h
        operator/Module.h
        operator/Sequential.h
        operator/ReLU.h
        operator/XEntropy.h

        optim/SGDOptimizer.h
        example-app.cpp
        CSVDataset.h
        Utility.h
        hps_0.h
)

# Include directories
target_include_directories(FPGATorch PUBLIC ${HWLIBS_ROOT}/include/${ALT_DEVICE_FAMILY})
target_include_directories(FPGATorch PUBLIC ${HWLIBS_ROOT}/include/)
set_property(TARGET FPGATorch PROPERTY CXX_STANDARD 11)

