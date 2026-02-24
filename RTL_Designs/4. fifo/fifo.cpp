#include <systemc.h>

SC_MODULE(FIFO) {
    sc_in<bool> write_clk;
    sc_in<bool> read_clk;
    sc_in<bool> rst;
    sc_in<bool> write_en;
    sc_in<sc_uint<8>> data_in;
    sc_out<sc_uint<8>> data_out;

    // Internal FIFO memory and pointers
    sc_uint<8> fifo_memory[360];
    sc_uint<9> write_ptr;
    sc_uint<9> read_ptr;

    SC_CTOR(FIFO) {
        SC_CTHREAD(write_process, write_clk.pos());
        async_reset_signal_is(rst, true);

        SC_CTHREAD(read_process, read_clk.pos());
        async_reset_signal_is(rst, true);

        // Initialize pointers and other variables here
        write_ptr = 0;
        read_ptr = 0;
    }

    void write_process() {
        while (true) {
            wait(); // Wait for rising edge of clock

            if (rst) {
                // Reset logic
                write_ptr = 0;
            } else if (write_en) {
                // Write data to FIFO memory
                fifo_memory[write_ptr] = data_in;
                write_ptr++;
                if (write_ptr == 360) {
                    write_ptr = 0; // Wrap around
                }
            }
        }
    }

    void read_process() {
        while (true) {
            wait(); // Wait for rising edge of clock

            if (rst) {
                // Reset logic
                read_ptr = 0;
            } else {
                // Read data from FIFO memory
                data_out = fifo_memory[read_ptr];
                read_ptr++;
                if (read_ptr == 360) {
                    read_ptr = 0; // Wrap around
                }
            }
        }
    }
};
