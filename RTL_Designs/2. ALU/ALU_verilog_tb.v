`timescale 1ns / 1ps

module ALU_tb;
    // Declare testbench signals
    reg [15:0] operandA;
    reg [15:0] operandB;
    reg [2:0] opcode;
    wire [15:0] resultR;
    wire [3:0] PSR;

    // Instantiate ALU
    ALU uut (
        .operandA(operandA),
        .operandB(operandB),
        .opcode(opcode),
        .resultR(resultR),
        .PSR(PSR)
    );

    // Task to display results for debugging
    task display_results;
        begin
            $display("Time = %0t | Opcode = %b | A = %h | B = %h | Result = %h | PSR = %b",
                     $time, opcode, operandA, operandB, resultR, PSR);
        end
    endtask

    initial begin
        // Enable VCD dumping for waveform analysis
        $dumpfile("alu_waveform.vcd");  // Output file for VCD dump
        $dumpvars(0, ALU_tb);  // Dump all variables in testbench

        // Test Cases

        // Test Case 1: ADD (No Carry)
        operandA = 16'h0003;
        operandB = 16'h0004;
        opcode = 3'b000;  // ADD
        #10;
        display_results();

        // Test Case 2: ADD (With Carry)
        operandA = 16'hFFFF;
        operandB = 16'h0001;
        opcode = 3'b000;  // ADD
        #10;
        display_results();

        // Test Case 3: SUB (Positive Result)
        operandA = 16'h0008;
        operandB = 16'h0003;
        opcode = 3'b001;  // SUB
        #10;
        display_results();

        // Test Case 4: SUB (Negative Result)
        operandA = 16'h0003;
        operandB = 16'h0008;
        opcode = 3'b001;  // SUB
        #10;
        display_results();

        // Test Case 5: NEG
        operandA = 16'h0007;
        operandB = 16'h0000;  // Not used
        opcode = 3'b010;  // NEG
        #10;
        display_results();

        // Test Case 6: NOT
        operandA = 16'h00FF;
        operandB = 16'h0000;  // Not used
        opcode = 3'b011;  // NOT
        #10;
        display_results();

        // Test Case 7: AND
        operandA = 16'h00F0;
        operandB = 16'h0F0F;
        opcode = 3'b100;  // AND
        #10;
        display_results();

        // Test Case 8: OR
        operandA = 16'h00F0;
        operandB = 16'h0F0F;
        opcode = 3'b101;  // OR
        #10;
        display_results();

        // Test Case 9: ADD (Zero Result)
        operandA = 16'h0000;
        operandB = 16'h0000;
        opcode = 3'b000;  // ADD
        #10;
        display_results();

        // Test Case 10: SUB (Zero Result)
        operandA = 16'h1234;
        operandB = 16'h1234;
        opcode = 3'b001;  // SUB
        #10;
        display_results();

        // Test Case 11: NEG (Boundary Condition)
        operandA = 16'h8000;
        operandB = 16'h0000;  // Not used
        opcode = 3'b010;  // NEG
        #10;
        display_results();

        // Test Case 12: NOT (Boundary Condition)
        operandA = 16'hFFFF;
        operandB = 16'h0000;  // Not used
        opcode = 3'b011;  // NOT
        #10;
        display_results();

        // Test Case 13: AND (All 1s)
        operandA = 16'hFFFF;
        operandB = 16'hFFFF;
        opcode = 3'b100;  // AND
        #10;
        display_results();

        // Test Case 14: OR (All 0s)
        operandA = 16'h0000;
        operandB = 16'h0000;
        opcode = 3'b101;  // OR
        #10;
        display_results();

        // End simulation
        $finish;
    end
endmodule
