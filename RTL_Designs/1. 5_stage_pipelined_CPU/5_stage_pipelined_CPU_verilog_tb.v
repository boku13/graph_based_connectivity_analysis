`timescale 1ns/1ps

module tb_pipeline;

  reg clk;
  reg reset;

  // Instantiate the pipelined processor.
  pipeline dut (
    .clk(clk),
    .reset(reset)
  );

  // Clock generation: 10 ns period.
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // VCD dump for waveform viewing.
  initial begin
    $dumpfile("pipeline.vcd");
    $dumpvars(0, tb_pipeline);
  end

  // Apply reset, then release.
  initial begin
    reset = 1;
    #20;           // Hold reset for 20 ns.
    reset = 0;
  end

  //-------------------------------------------------------------------------
  // Instruction Memory Initialization.
  // The instruction sequence is as follows:
  //  0. lw   $1, 4($0)       => 8C010004   (Load 12 from dmem[4..7] into reg1)
  //  1. lw   $2, 8($0)       => 8C020008   (Load 15 from dmem[8..11] into reg2)
  //  2. no-op                => 00000000   (Bubble 1)
  //  3. no-op                => 00000000   (Bubble 2)
  //  4. no-op                => 00000000   (Bubble 3)
  //  5. no-op                => 00000000   (Bubble 4)
  //  6. addu $3, $1, $2      => 00221821   (Add reg1 and reg2; result into reg3)
  //  7. Halt                 => FFFFFFFF   (Stop fetching)
  //-------------------------------------------------------------------------
  initial begin
    // Wait until reset is released.
    @(negedge reset);
    
    // Instruction 0: lw $1, 4($0) => 8C010004
    dut.imem[0] = 8'h8C;
    dut.imem[1] = 8'h01;
    dut.imem[2] = 8'h00;
    dut.imem[3] = 8'h04;
    
    // Instruction 1: lw $2, 8($0) => 8C020008
    dut.imem[4] = 8'h8C;
    dut.imem[5] = 8'h02;
    dut.imem[6] = 8'h00;
    dut.imem[7] = 8'h08;
    
    // Instruction 2: no-op => 00000000 (Bubble 1)
    dut.imem[8]  = 8'h00;
    dut.imem[9]  = 8'h00;
    dut.imem[10] = 8'h00;
    dut.imem[11] = 8'h00;
    
    // Instruction 3: no-op => 00000000 (Bubble 2)
    dut.imem[12] = 8'h00;
    dut.imem[13] = 8'h00;
    dut.imem[14] = 8'h00;
    dut.imem[15] = 8'h00;
    
    // Instruction 4: no-op => 00000000 (Bubble 3)
    dut.imem[16] = 8'h00;
    dut.imem[17] = 8'h00;
    dut.imem[18] = 8'h00;
    dut.imem[19] = 8'h00;
    
    // Instruction 5: no-op => 00000000 (Bubble 4)
    dut.imem[20] = 8'h00;
    dut.imem[21] = 8'h00;
    dut.imem[22] = 8'h00;
    dut.imem[23] = 8'h00;
    
    // Instruction 6: addu $3, $1, $2 => 00221821
    dut.imem[24] = 8'h00;
    dut.imem[25] = 8'h22;
    dut.imem[26] = 8'h18;
    dut.imem[27] = 8'h21;
    
    // Instruction 7: Halt => FFFFFFFF
    dut.imem[28] = 8'hFF;
    dut.imem[29] = 8'hFF;
    dut.imem[30] = 8'hFF;
    dut.imem[31] = 8'hFF;
    
    // Clear remaining instruction memory.
    for (integer idx = 32; idx < dut.MEM_SIZE; idx = idx + 1)
      dut.imem[idx] = 8'h00;
  end

  //-------------------------------------------------------------------------
  // Data Memory Initialization.
  // Set dmem[4..7] = 0x0000000C (12) for lw $1.
  // Set dmem[8..11] = 0x0000000F (15) for lw $2.
  //-------------------------------------------------------------------------
  initial begin
    @(negedge reset);
    // dmem[4..7] = 0x0000000C
    dut.dmem[4] = 8'h00;
    dut.dmem[5] = 8'h00;
    dut.dmem[6] = 8'h00;
    dut.dmem[7] = 8'h0C;
    
    // dmem[8..11] = 0x0000000F
    dut.dmem[8]  = 8'h00;
    dut.dmem[9]  = 8'h00;
    dut.dmem[10] = 8'h00;
    dut.dmem[11] = 8'h0F;
    
    // Clear remaining data memory.
    for (integer idx = 12; idx < dut.MEM_SIZE; idx = idx + 1)
      dut.dmem[idx] = 8'h00;
  end

  //-------------------------------------------------------------------------
  // Monitor key signals to observe behavior.
  // Displays the current PC, IF stage "nop" flag, the fetched instruction,
  // and register file contents for registers 1, 2, and 3.
  //-------------------------------------------------------------------------
  initial begin
    $monitor("Time=%0t | IF_PC=%h | IF_nop=%b | ID_Instr=%h | RF[1]=%h | RF[2]=%h | RF[3]=%h", 
             $time, dut.IF_PC, dut.IF_nop, dut.ID_Instr, dut.RF[1], dut.RF[2], dut.RF[3]);
  end

  //-------------------------------------------------------------------------
  // Display registers affected by operations.
  // A shadow copy (prev_RF) of the register file is maintained.
  // On every positive clock edge, any change is printed.
  //-------------------------------------------------------------------------
  reg [31:0] prev_RF [0:31];
  integer j;
  
  // Initialize the previous register file values.
  initial begin
    for (j = 0; j < 32; j = j + 1)
      prev_RF[j] = dut.RF[j];
  end

  // At each positive clock edge, check for register changes.
  always @(posedge clk) begin
    #1; // Small delay to allow RF update.
    for (j = 0; j < 32; j = j + 1) begin
      if (dut.RF[j] !== prev_RF[j]) begin
        $display("Time=%0t: Register RF[%0d] changed from %h to %h", $time, j, prev_RF[j], dut.RF[j]);
        prev_RF[j] = dut.RF[j];
      end
    end
  end

  //-------------------------------------------------------------------------
  // Terminate simulation after sufficient time.
  // Also print final register values.
  //-------------------------------------------------------------------------
  initial begin
    #600;
    $display("------ Simulation Finished ------");
    $display("Final RF[1] (should be 12): %h", dut.RF[1]);
    $display("Final RF[2] (should be 15): %h", dut.RF[2]);
    $display("Final RF[3] (should be 27): %h", dut.RF[3]);
    $finish;
  end

endmodule
