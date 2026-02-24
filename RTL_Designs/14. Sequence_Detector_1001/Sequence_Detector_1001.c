#include <systemc.h>

SC_MODULE(sequence_detector_1001) {
    sc_in<bool> clk;
    sc_in<bool> reset;
    sc_in<bool> input;
    sc_out<bool> output;

    enum State { IDLE, S1, S2, S3, DETECT };

    State current_state;

    void fsm() {
        if (reset.read()) {
            current_state = IDLE;
            output.write(false);
        } else {
            switch (current_state) {
                case IDLE:
                    if (input.read()) {
                        current_state = S1;
                    }
                    break;
                case S1:
                    if (!input.read()) {
                        current_state = S2;
                    } else {
                        current_state = S1;
                    }
                    break;
                case S2:
                    if (!input.read()) {
                        current_state = S3;
                    } else {
                        current_state = S1;
                    }
                    break;
                case S3:
                    if (input.read()) {
                        current_state = DETECT;
                    } else {
                        current_state = IDLE;
                    }
                    break;
                case DETECT:
                    if (input.read()) {
                        current_state = S1;
                    } else {
                        current_state = IDLE;
                    }
                    break;
            }

            if (current_state == DETECT) {
                output.write(true);
            } else {
                output.write(false);
            }
        }
    }

    SC_CTOR(sequence_detector_1001) {
        SC_METHOD(fsm);
        sensitive << clk.pos();
    }
};