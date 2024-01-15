cmake_minimum_required(VERSION 3.18 FATAL_ERROR)
project(example-app)

#set(CMAKE_PREFIX_PATH "/mnt/e/FPGATorch/libtorch" ${CMAKE_PREFIX_PATH})

#find_package(Torch REQUIRED)
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${TORCH_CXX_FLAGS}")

add_executable(example-app
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
)

#target_link_libraries(example-app "${TORCH_LIBRARIES}")
set_property(TARGET example-app PROPERTY CXX_STANDARD 17)
set_target_properties(example-app PROPERTIES
        COMPILE_FLAGS "-fsanitize=address,undefined -fno-omit-frame-pointer"
        LINK_FLAGS "-fsanitize=address,undefined"
)
