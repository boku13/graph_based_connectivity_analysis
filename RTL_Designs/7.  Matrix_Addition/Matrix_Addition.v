module matrix_addition #(
    parameter ROWS = 4,  // Number of rows
    parameter COLS = 4   // Number of columns
)(
    input clk,
    input rst,          // Reset signal
    input start,        // Start signal
    input [7:0] a[ROWS-1:0][COLS-1:0],  // First matrix
    input [7:0] b[ROWS-1:0][COLS-1:0],  // Second matrix
    output reg [7:0] sum[ROWS-1:0][COLS-1:0], // Output sum matrix
    output reg done   // Done flag when addition completes
);

    reg [1:0] state;
    reg [$clog2(ROWS)-1:0] i;  // Row index
    reg [$clog2(COLS)-1:0] j;  // Column index

    localparam IDLE  = 2'b00,
               ADD   = 2'b01,
               DONE  = 2'b10;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            i <= 0;
            j <= 0;
            done <= 0;
        end 
        else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        i <= 0;
                        j <= 0;
                        state <= ADD;
                        done <= 0;
                    end
                end

                ADD: begin
                    sum[i][j] <= a[i][j] + b[i][j];
                    if (j == COLS-1) begin
                        j <= 0;
                        if (i == ROWS-1)
                            state <= DONE;
                        else
                            i <= i + 1;
                    end else begin
                        j <= j + 1;
                    end
                end

                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
