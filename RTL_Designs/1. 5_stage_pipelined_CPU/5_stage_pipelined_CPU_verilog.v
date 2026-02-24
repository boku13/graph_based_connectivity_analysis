//*****************************************************************************
//  Synthesizable 5-Stage Pipeline (IF, ID, EX, MEM, WB)
//  This design implements a pipelined processor that corresponds to the 
//  provided C++ code. It uses a synchronous design with clock and reset,
//  and halts instruction fetch when a 0xFFFFFFFF instruction is encountered.
//  
//  Note: Memory initialization via $readmemb is assumed to be supported 
//        (e.g. for FPGA targets).
//*****************************************************************************

module pipeline (
    input  wire        clk,
    input  wire        reset
);

  //-------------------------------------------------------------------------
  // Parameters
  //-------------------------------------------------------------------------
  parameter MEM_SIZE = 1000;  // memory size in bytes

  //-------------------------------------------------------------------------
  // Memory Declarations (Byte-Addressable)
  //-------------------------------------------------------------------------
  // Instruction Memory and Data Memory.
  // (These are initialized using $readmemb; adjust file names/format as needed.)
  reg [7:0] imem [0:MEM_SIZE-1];
  reg [7:0] dmem [0:MEM_SIZE-1];

  // Memory initialization (synthesizable on many FPGA targets)
  initial begin
    $readmemb("imem.txt", imem);
    $readmemb("dmem.txt", dmem);
  end

  //-------------------------------------------------------------------------
  // Register File (32 registers x 32 bits)
  //-------------------------------------------------------------------------
  reg [31:0] RF [0:31];
  integer i;
  initial begin
    for (i = 0; i < 32; i = i + 1)
      RF[i] = 32'b0;
  end

  //-------------------------------------------------------------------------
  // Pipeline Registers
  //-------------------------------------------------------------------------

  // IF Stage
  reg [31:0] IF_PC;
  reg        IF_nop;

  // ID Stage
  reg [31:0] ID_Instr;
  reg        ID_nop;

  // EX Stage
  reg [31:0] EX_Read_data1, EX_Read_data2;
  reg [15:0] EX_Imm;
  reg [4:0]  EX_Rs, EX_Rt, EX_Wrt_reg_addr;
  reg        EX_is_I_type, EX_rd_mem, EX_wrt_mem, EX_alu_op, EX_wrt_enable;
  reg        EX_nop;

  // MEM Stage
  reg [31:0] MEM_ALUresult, MEM_Store_data;
  reg [4:0]  MEM_Rs, MEM_Rt, MEM_Wrt_reg_addr;
  reg        MEM_rd_mem, MEM_wrt_mem, MEM_wrt_enable;
  reg        MEM_nop;

  // WB Stage
  reg [31:0] WB_Wrt_data;
  reg [4:0]  WB_Rs, WB_Rt, WB_Wrt_reg_addr;
  reg        WB_wrt_enable;
  reg        WB_nop;

  //-------------------------------------------------------------------------
  // Pipeline Stage Updates (Synchronous, all on posedge clk)
  //-------------------------------------------------------------------------

  //----- WB Stage: Writeback and update WB pipeline registers -----
  always @(posedge clk) begin
    if (reset) begin
      WB_nop          <= 1'b1;
      WB_Wrt_data     <= 32'b0;
      WB_Rs           <= 5'b0;
      WB_Rt           <= 5'b0;
      WB_Wrt_reg_addr <= 5'b0;
      WB_wrt_enable   <= 1'b0;
    end
    else begin
      // Write back to register file (note: register 0 remains 0)
      if (!WB_nop && WB_wrt_enable && (WB_Wrt_reg_addr != 0))
         RF[WB_Wrt_reg_addr] <= WB_Wrt_data;
      // Update WB pipeline registers from MEM stage
      WB_nop <= MEM_nop;
      if (!MEM_nop)
        WB_Wrt_data <= MEM_rd_mem ?
            { dmem[MEM_ALUresult],
              dmem[MEM_ALUresult+1],
              dmem[MEM_ALUresult+2],
              dmem[MEM_ALUresult+3] }
            : MEM_ALUresult;
      else begin
         WB_Wrt_data     <= 32'b0;
         WB_Rs          <= 5'b0;
         WB_Rt          <= 5'b0;
         WB_Wrt_reg_addr<= 5'b0;
         WB_wrt_enable  <= 1'b0;
      end
      WB_Rs           <= MEM_Rs;
      WB_Rt           <= MEM_Rt;
      WB_Wrt_reg_addr <= MEM_Wrt_reg_addr;
      WB_wrt_enable   <= MEM_wrt_enable;
    end
  end

  //----- MEM Stage: Compute ALU result, perform dmem read/write, update MEM regs -----
  always @(posedge clk) begin
    if (reset) begin
      MEM_nop           <= 1'b1;
      MEM_ALUresult     <= 32'b0;
      MEM_Store_data    <= 32'b0;
      MEM_rd_mem        <= 1'b0;
      MEM_wrt_mem       <= 1'b0;
      MEM_Rs            <= 5'b0;
      MEM_Rt            <= 5'b0;
      MEM_Wrt_reg_addr  <= 5'b0;
      MEM_wrt_enable    <= 1'b0;
    end
    else begin
      MEM_nop <= EX_nop;
      if (!EX_nop) begin
         MEM_Store_data <= EX_Read_data2;
         // For I-type instructions, use sign-extended immediate.
         if (EX_is_I_type)
            MEM_ALUresult <= EX_Read_data1 + { {16{EX_Imm[15]}}, EX_Imm };
         else begin
            if (EX_alu_op)
               MEM_ALUresult <= EX_Read_data1 + EX_Read_data2;
            else
               MEM_ALUresult <= EX_Read_data1 - EX_Read_data2;
         end
         MEM_rd_mem       <= EX_rd_mem;
         MEM_wrt_mem      <= EX_wrt_mem;
         MEM_Rs           <= EX_Rs;
         MEM_Rt           <= EX_Rt;
         MEM_Wrt_reg_addr <= EX_Wrt_reg_addr;
         MEM_wrt_enable   <= EX_wrt_enable;
         // If a store word is indicated, write to Data Memory.
         if (EX_wrt_mem) begin
            dmem[MEM_ALUresult]   <= MEM_Store_data[31:24];
            dmem[MEM_ALUresult+1] <= MEM_Store_data[23:16];
            dmem[MEM_ALUresult+2] <= MEM_Store_data[15:8];
            dmem[MEM_ALUresult+3] <= MEM_Store_data[7:0];
         end
      end
      else begin
         MEM_ALUresult     <= 32'b0;
         MEM_Store_data    <= 32'b0;
         MEM_rd_mem        <= 1'b0;
         MEM_wrt_mem       <= 1'b0;
         MEM_Rs            <= 5'b0;
         MEM_Rt            <= 5'b0;
         MEM_Wrt_reg_addr  <= 5'b0;
         MEM_wrt_enable    <= 1'b0;
      end
    end
  end

  //----- EX Stage: Decode instruction and read register file, update EX regs -----
  always @(posedge clk) begin
    if (reset) begin
      EX_nop           <= 1'b1;
      EX_Read_data1    <= 32'b0;
      EX_Read_data2    <= 32'b0;
      EX_Rs            <= 5'b0;
      EX_Rt            <= 5'b0;
      EX_Wrt_reg_addr  <= 5'b0;
      EX_Imm           <= 16'b0;
      EX_rd_mem        <= 1'b0;
      EX_wrt_mem       <= 1'b0;
      EX_wrt_enable    <= 1'b0;
      EX_is_I_type     <= 1'b0;
      EX_alu_op        <= 1'b1;
    end
    else begin
      EX_nop <= ID_nop;
      if (!ID_nop) begin
         // Decode fields from the instruction in the ID stage.
         //   opcode = Instr[31:26]
         //   Rs     = Instr[25:21]
         //   Rt     = Instr[20:16]
         //   Rd     = Instr[15:11]
         //   Imm    = Instr[15:0]
         //   funct  = Instr[5:0]
         reg [5:0] opcode;
         reg [5:0] funct;
         reg       IsBranch;
         opcode = ID_Instr[31:26];
         IsBranch = (opcode == 6'b000100);
         EX_rd_mem     <= (opcode == 6'b100011) ? 1'b1 : 1'b0; // lw (opcode 35)
         EX_wrt_mem    <= (opcode == 6'b101011) ? 1'b1 : 1'b0; // sw (opcode 43)
         EX_wrt_enable <= ((opcode == 6'b101011) || IsBranch) ? 1'b0 : 1'b1;
         EX_is_I_type  <= (((opcode != 6'b000000) && (opcode != 6'b000010)) && !IsBranch) ? 1'b1 : 1'b0;
         funct = ID_Instr[5:0];
         // In this design, alu_op is 0 for a subu function (funct == 35) and 1 otherwise.
         EX_alu_op <= (funct == 6'b100011) ? 1'b0 : 1'b1;
         EX_Rs  <= ID_Instr[25:21];
         EX_Rt  <= ID_Instr[20:16];
         EX_Read_data1 <= RF[ID_Instr[25:21]];
         EX_Read_data2 <= RF[ID_Instr[20:16]];
         // For I-type instructions, the destination register is Rt; for R-type it is Rd.
         EX_Wrt_reg_addr <= (EX_is_I_type ? ID_Instr[20:16] : ID_Instr[15:11]);
         EX_Imm <= ID_Instr[15:0];
      end
      else begin
         EX_Read_data1    <= 32'b0;
         EX_Read_data2    <= 32'b0;
         EX_Rs            <= 5'b0;
         EX_Rt            <= 5'b0;
         EX_Wrt_reg_addr  <= 5'b0;
         EX_Imm           <= 16'b0;
         EX_rd_mem        <= 1'b0;
         EX_wrt_mem       <= 1'b0;
         EX_wrt_enable    <= 1'b0;
         EX_is_I_type     <= 1'b0;
         EX_alu_op        <= 1'b1;
      end
    end
  end

  //----- IF Stage: Instruction Fetch and update IF regs -----
  always @(posedge clk) begin
    if (reset) begin
      IF_PC   <= 32'b0;
      IF_nop  <= 1'b0;  // Start with IF active.
      ID_nop  <= 1'b1;
      ID_Instr<= 32'b0;
    end
    else begin
      ID_nop <= IF_nop;
      if (!IF_nop) begin
         // Fetch 4 consecutive bytes from imem to form the instruction.
         ID_Instr <= { imem[IF_PC],
                       imem[IF_PC+1],
                       imem[IF_PC+2],
                       imem[IF_PC+3] };
         // If the fetched instruction is 0xFFFFFFFF, freeze IF and ID stages.
         if ({ imem[IF_PC],
                imem[IF_PC+1],
                imem[IF_PC+2],
                imem[IF_PC+3] } == 32'hFFFFFFFF) begin
            IF_nop <= 1'b1;
            ID_nop <= 1'b1;
            // PC remains unchanged.
         end
         else begin
            IF_PC <= IF_PC + 4;
         end
      end
    end
  end

endmodule
