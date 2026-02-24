// Elevator Controller Testbench
`timescale 1ns / 1ps

module Elevator_Controller_TB();
    
    reg clk;
    reg reset;
    reg [7:0] req_floor;
    reg req_valid;
    reg open_door;
    
    wire [7:0] curr_floor;
    wire moving;
    wire [1:0] direction;
    
    // Instantiate the Elevator Controller
    Elevator_Controller uut (
        .clk(clk),
        .reset(reset),
        .req_floor(req_floor),
        .req_valid(req_valid),
        .open_door(open_door),
        .curr_floor(curr_floor),
        .moving(moving),
        .direction(direction)
    );
    
    // Clock Generation
    always #5 clk = ~clk; // 10ns clock period
    
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        req_floor = 0;
        req_valid = 0;
        open_door = 0;
        
        // VCD Dump Setup
        $dumpfile("elevator_tb.vcd");
        $dumpvars(0, Elevator_Controller_TB);
        
        // Reset sequence
        #10 reset = 0;
        
        // Request floors
        #10 req_floor = 3; req_valid = 1;
        #10 req_valid = 0; // Latch request
        
        #20 req_floor = 6; req_valid = 1;
        #10 req_valid = 0; // Latch request
        
        #20 req_floor = 4; req_valid = 1;
        #10 req_valid = 0; // Latch request
        
        // Let simulation run
        #200;
        
        // End simulation
        $finish;
    end
    
endmodule
