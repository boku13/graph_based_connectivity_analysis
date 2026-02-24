module max_pooling_tb;
    reg clk;
    reg rst;
    reg start;
    reg [7:0] input_matrix [0:3][0:3];
    wire [7:0] output_matrix [0:1][0:1];
    wire done;

    max_pooling #(
        .IN_SIZE(4),
        .OUT_SIZE(2),
        .POOL_SIZE(2),
        .DATA_WIDTH(8)
    ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .input_matrix(input_matrix),
        .output_matrix(output_matrix),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        #10 rst = 0;

        // Initialize input matrix
        input_matrix[0][0] = 1; input_matrix[0][1] = 2; input_matrix[0][2] = 3; input_matrix[0][3] = 4;
        input_matrix[1][0] = 5; input_matrix[1][1] = 6; input_matrix[1][2] = 7; input_matrix[1][3] = 8;
        input_matrix[2][0] = 9; input_matrix[2][1] = 10; input_matrix[2][2] = 11; input_matrix[2][3] = 12;
        input_matrix[3][0] = 13; input_matrix[3][1] = 14; input_matrix[3][2] = 15; input_matrix[3][3] = 16;
        
        #10 start = 1;
        #20 start = 0;
        
        #50;
        $display("Max Pooling Output:");
        $display("%d %d", output_matrix[0][0], output_matrix[0][1]);
        $display("%d %d", output_matrix[1][0], output_matrix[1][1]);
        
        $stop;
    end
endmodule
