module FIFO (
    input wire write_clk,
    input wire read_clk,
    input wire rst,
    input wire write_en,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

    // Internal FIFO memory and pointers
    reg [7:0] fifo_memory [0:359];
    reg [8:0] write_ptr;
    reg [8:0] read_ptr;
    
    // Write process
    always @(posedge write_clk or posedge rst) begin
        if (rst) begin
            write_ptr <= 9'd0;
        end else if (write_en) begin
            fifo_memory[write_ptr] <= data_in;
            write_ptr <= (write_ptr == 9'd359) ? 9'd0 : write_ptr + 9'd1;
        end
    end

    // Read process
    always @(posedge read_clk or posedge rst) begin
        if (rst) begin
            read_ptr <= 9'd0;
        end else begin
            data_out <= fifo_memory[read_ptr];
            read_ptr <= (read_ptr == 9'd359) ? 9'd0 : read_ptr + 9'd1;
        end
    end

endmodule
