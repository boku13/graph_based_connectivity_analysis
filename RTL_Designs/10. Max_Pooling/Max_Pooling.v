module max_pooling #(
    parameter IN_SIZE = 4,
    parameter OUT_SIZE = 2,
    parameter POOL_SIZE = 2,
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst,
    input start,
    input [DATA_WIDTH-1:0] input_matrix [0:IN_SIZE-1][0:IN_SIZE-1],
    output reg [DATA_WIDTH-1:0] output_matrix [0:OUT_SIZE-1][0:OUT_SIZE-1],
    output reg done
);

    integer i, j, m, n;
    reg [DATA_WIDTH-1:0] max_value;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            done <= 0;
        end else if (start) begin
            for (i = 0; i < IN_SIZE; i = i + POOL_SIZE) begin
                for (j = 0; j < IN_SIZE; j = j + POOL_SIZE) begin
                    max_value = input_matrix[i][j];
                    
                    for (m = 0; m < POOL_SIZE; m = m + 1) begin
                        for (n = 0; n < POOL_SIZE; n = n + 1) begin
                            if ((i + m) < IN_SIZE && (j + n) < IN_SIZE) begin
                                if (input_matrix[i + m][j + n] > max_value) begin
                                    max_value = input_matrix[i + m][j + n];
                                end
                            end
                        end
                    end
                    
                    output_matrix[i/POOL_SIZE][j/POOL_SIZE] = max_value;
                end
            end
            done <= 1;
        end
    end

endmodule
