`timescale 1ns / 1ps

module matrix_multiplication #(parameter N = 5)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [7:0] A [0:N-1][0:N-1],
    input wire [7:0] B [0:N-1][0:N-1],
    output reg [15:0] C [0:N-1][0:N-1],
    output reg done
);

    reg [3:0] i, j, k;
    reg [1:0] state;
    integer x, y;

    localparam IDLE = 2'b00, COMPUTE = 2'b01, DONE = 2'b10;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i <= 0;
            j <= 0;
            k <= 0;
            state <= IDLE;
            done <= 0;
            for (x = 0; x < N; x = x + 1)
                for (y = 0; y < N; y = y + 1)
                    C[x][y] <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        i <= 0;
                        j <= 0;
                        k <= 0;
                        state <= COMPUTE;
                        done <= 0;
                        for (x = 0; x < N; x = x + 1)
                            for (y = 0; y < N; y = y + 1)
                                C[x][y] <= 0;
                    end
                end
                
                COMPUTE: begin
                    if (i < N) begin
                        if (j < N) begin
                            if (k < N) begin
                                C[i][j] <= C[i][j] + A[i][k] * B[k][j];
                                k <= k + 1;
                            end else begin
                                k <= 0;
                                j <= j + 1;
                            end
                        end else begin
                            j <= 0;
                            i <= i + 1;
                        end
                    end else begin
                        state <= DONE;
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
