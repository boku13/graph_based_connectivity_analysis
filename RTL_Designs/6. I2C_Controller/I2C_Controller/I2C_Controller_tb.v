`timescale 1ns / 1ps

module i2c_controller_tb;
    
    // Signals
    reg clk;
    reg rst;
    reg [6:0] addr;
    reg [7:0] data_in;
    reg rw;
    reg enable;
    wire ready;
    wire i2c_sda;
    wire i2c_scl;
    
    // Instantiate the I2C Controller
    i2c_controller uut (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .data_in(data_in),
        .rw(rw),
        .enable(enable),
        .ready(ready),
        .i2c_sda(i2c_sda),
        .i2c_scl(i2c_scl)
    );
    
    // Clock Generation
    always #5 clk = ~clk; // 10 ns period (100 MHz clock)
    
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        addr = 7'b0;
        data_in = 8'b0;
        rw = 0;
        enable = 0;
        
        // VCD Dump
        $dumpfile("i2c_controller_tb.vcd");
        $dumpvars(0, i2c_controller_tb);
        
        // Apply reset
        #100;
        rst = 0;
        addr = 7'b101010; // Example address (42 in decimal)
        data_in = 8'b10101010; // Example data (170 in decimal)
        rw = 0; // Write operation
        enable = 1;
        
        #10;
        enable = 0;
        
        // Wait for some time to observe behavior
        #500;
        
        $finish;
    end
    
endmodule
