`timescale 1ns / 1ps

module tb_matrix_addition;

    // Parameters for matrix dimensions
    parameter ROWS = 5;
    parameter COLS = 5;

    // Testbench signals
    reg clk;
    reg rst;
    reg start;
    reg [7:0] a[ROWS-1:0][COLS-1:0];  
    reg [7:0] b[ROWS-1:0][COLS-1:0];  
    wire [7:0] sum[ROWS-1:0][COLS-1:0]; 
    wire done;

    // Instantiate the matrix addition module
    matrix_addition #(.ROWS(ROWS), .COLS(COLS)) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(a),
        .b(b),
        .sum(sum),
        .done(done)
    );

    // Clock generation (10ns period, 100MHz frequency)
    always #5 clk = ~clk;

    integer i, j;

    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        start = 0;

        // Enable VCD waveform dumping
        $dumpfile("matrix_addition.vcd");  // Dump file name
        $dumpvars(0, tb_matrix_addition);  // Dump all variables in this module
        
        // Apply reset
        #10 rst = 0;

        // Initialize matrices with test values
        for (i = 0; i < ROWS; i = i + 1) begin
            for (j = 0; j < COLS; j = j + 1) begin
                a[i][j] = i + j;  // Example: 0,1,2,... diagonal pattern
                b[i][j] = (i + j) * 2; // Example: 0,2,4,...
            end
        end

        // Start the addition operation
        #10 start = 1;
        #10 start = 0; // Deassert start after one clock cycle

        // Wait for the operation to complete
        wait(done);

        // Display the result
        $display("\nMatrix A:");
        for (i = 0; i < ROWS; i = i + 1) begin
            for (j = 0; j < COLS; j = j + 1) begin
                $write("%d ", a[i][j]);
            end
            $write("\n");
        end

        $display("\nMatrix B:");
        for (i = 0; i < ROWS; i = i + 1) begin
            for (j = 0; j < COLS; j = j + 1) begin
                $write("%d ", b[i][j]);
            end
            $write("\n");
        end

        $display("\nSum Matrix:");
        for (i = 0; i < ROWS; i = i + 1) begin
            for (j = 0; j < COLS; j = j + 1) begin
                $write("%d ", sum[i][j]);
            end
            $write("\n");
        end

        // End simulation
        #20;
        $finish;
    end

endmodule
