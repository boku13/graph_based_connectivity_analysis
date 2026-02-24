`timescale 1ns / 1ps

module sequence_detector_1001_tb;
    
    reg clk;
    reg reset;
    reg seq_in_signal;
    wire seq_detect_signal;
    
    // Instantiate the sequence detector module
    sequence_detector_1001 uut (
        .clk(clk),
        .reset(reset),
        .seq_in(seq_in_signal),
        .seq_detect(seq_detect_signal)
    );
    
    // Clock generation
    always #5 clk = ~clk; // 10ns period
    
    // Define input sequence as a bit array
    reg [50:0] seq_in_stream_1 = 51'b010010000100100101001000010011001100100000010010;
    
    integer i;

    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        seq_in_signal = 0;
        
        // Apply reset
        #10 reset = 0;
        
        // Apply test sequence
        for (i = 50; i >= 0; i = i - 1) begin
            seq_in_signal = seq_in_stream_1[i];
            #10;
        end
        
        // End simulation
        #50 $finish;
    end
    
    // Monitor seq_detects
    initial begin
        $monitor("Time = %0t | Input = %b | Output = %b | State = %s", 
                 $time, seq_in_signal, seq_detect_signal, uut.current_state);
    end
    
    // VCD Dump
    initial begin
        $dumpfile("sequence_detector.vcd");
        $dumpvars(0, sequence_detector_1001_tb);
    end
    
endmodule
