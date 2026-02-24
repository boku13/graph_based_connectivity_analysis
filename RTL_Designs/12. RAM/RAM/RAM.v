`timescale 1ns / 1ps

module Memory (
    input wire clk,
    input wire [1:0] func,
    input wire [8:0] addr,
    inout wire [31:0] data,
    output reg [1:0] doneSig
);

    parameter MEM_SIZE = 512;
    
    // Function Codes
    localparam FUNC_NONE  = 2'b00;
    localparam FUNC_READ  = 2'b01;
    localparam FUNC_WRITE = 2'b10;
    
    // Return Signals
    localparam RSIG_NONE       = 2'b00;
    localparam RSIG_READ_FIN   = 2'b01;
    localparam RSIG_WRITE_FIN  = 2'b10;
    localparam RSIG_ERROR      = 2'b11;
    
    reg [31:0] memory [0:MEM_SIZE-1];
    reg [8:0] curAddr;
    reg [31:0] curData;
    reg [1:0] curFunc;
    reg [6:0] clkCnt;
    reg [31:0] data_reg;
    reg data_en;
    
    assign data = (data_en) ? data_reg : 32'bz;
    
    always @(posedge clk) begin
        if (curFunc != FUNC_NONE) begin
            clkCnt <= clkCnt + 1;
            if (clkCnt == 100) begin
                case (curFunc)
                    FUNC_READ: begin
                        if (curAddr < MEM_SIZE) begin
                            data_reg <= memory[curAddr];
                            data_en <= 1'b1;
                            doneSig <= RSIG_READ_FIN;
                        end else begin
                            doneSig <= RSIG_ERROR;
                        end
                    end
                    FUNC_WRITE: begin
                        if (curAddr < MEM_SIZE) begin
                            memory[curAddr] <= curData;
                            doneSig <= RSIG_WRITE_FIN;
                        end else begin
                            doneSig <= RSIG_ERROR;
                        end
                    end
                    default: doneSig <= RSIG_ERROR;
                endcase
                
                clkCnt <= 0;
                curFunc <= FUNC_NONE;
            end
        end else if (func != FUNC_NONE) begin
            curFunc <= func;
            curAddr <= addr;
            curData <= data;
            doneSig <= RSIG_NONE;
            data_en <= 1'b0;
        end
    end
endmodule