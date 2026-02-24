module sequence_detector_TB();
    reg clk, rst, serial_input;
    wire mealy_output;

    sequence_detector UUT (
        .clk(clk),
        .rst(rst),
        .serial_input(serial_input),
        .mealy_output(mealy_output)
    );

    // Clock Generation
    always begin
        #20 clk = ~clk;
    end

    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        serial_input = 0;
        
        // VCD Dump
        $dumpfile("sequence_detector.vcd");
        $dumpvars(0, sequence_detector_TB);
        
        // Reset sequence
        #37 rst = 0;
        #59 rst = 1;
        #59 rst = 0;

        // Input waveform including pattern 11010
        #25 serial_input = 1;
        #40 serial_input = 1;
        #40 serial_input = 0;
        #40 serial_input = 1;
        #40 serial_input = 0; // Detecting 11010 sequence
        #40 serial_input = 1;
        #40 serial_input = 1;
        #40 serial_input = 0;
        #40 serial_input = 1;
        #40 serial_input = 0; // Another 11010 sequence
        #40 serial_input = 1;
        #40 serial_input = 1;
        #40 serial_input = 1;
        #40 serial_input = 0;
        #40 serial_input = 1;
        #40 serial_input = 0; // Testing additional cases
        #40 serial_input = 0; // Testing additional cases
        #40 serial_input = 1; // Testing additional cases
        #40 serial_input = 1; // Testing additional cases
        #40 serial_input = 0; // Testing additional cases
        #40 serial_input = 1; // Testing additional cases
        #40 serial_input = 1; // Testing additional cases

        // Run simulation for some time
        #4000 $stop;
    end
endmodule
