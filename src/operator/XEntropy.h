#pragma once
#include "Module.h"
#include <limits>

namespace Neural {
    class XEntropy {
    public:
        SmartTensor mLabel;
        SmartTensor softmax;

    public:
        /**
         * @param pred - shape = (N, 1, C), channel=1
         * @param label - shape = (N, C, 1), channel=1
         * @return
         */
        float Forward(const SmartTensor &pred, const SmartTensor& label) {
            mLabel = label;
            int N = pred->size[0];
            int C  = pred->size[2];

            float max_val = -std::numeric_limits<float>::infinity();
            for (int i = 0; i < pred->size[0] * pred->size[1] * pred->size[2]; i ++) {
                max_val = fmaxf(max_val, pred->data[i]);
            }

            SmartTensor scaled_pred = ScalarMatAdd(MatTrans(pred), -1 * max_val);

            SmartTensor Ones_N = MatNew(N, 1, 1);
            SmartTensor Ones_C = MatNew(C, 1, 1);

            SmartTensor exp_pred = ScalarMatExp(scaled_pred);
            float exp_sum  = ReduceSum(exp_pred, 1) -> data[0];

            // ScalarMatAdd is for numerical stability of ScalarMatLog(...)
            softmax = ScalarMatDiv(exp_pred, exp_sum);

            SmartTensor XEntropy = MatMul(
                    MatElementwiseMul(ScalarMatMul(label, -1.f), ScalarMatLog(softmax)),
                    Ones_C
            );

            float sumXEntropy = ReduceSum(XEntropy, 1)->data[0];

            return sumXEntropy / static_cast<float>(N);
        }

        SmartTensor Backward(SmartTensor gradient) {
            return MatTrans(MatAdd(softmax, ScalarMatMul(mLabel, -1.f)));
        }
    };
}



