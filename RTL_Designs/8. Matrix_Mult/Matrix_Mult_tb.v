`timescale 1ns / 1ps

module matrix_multiplication_tb;
    parameter N = 5; // Matrix size 5x5

    reg clk, rst, start;
    reg [7:0] A [0:N-1][0:N-1];
    reg [7:0] B [0:N-1][0:N-1];
    wire [15:0] C [0:N-1][0:N-1];
    wire done;

    integer i, j; // Declare integer loop variables

    // Instantiate the matrix multiplication module
    matrix_multiplication #(.N(N)) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .A(A),
        .B(B),
        .C(C),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        clk = 0;
        rst = 1;
        start = 0;
        #10 rst = 0;

        // Initialize matrices A and B
        $display("Matrix A:");
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                A[i][j] = i + j + 1; // Example values
                B[i][j] = (i + 1) * (j + 1); // Non-identity matrix values
                $write("%d ", A[i][j]);
            end
            $write("\n");
        end

        $display("Matrix B:");
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                $write("%d ", B[i][j]);
            end
            $write("\n");
        end

        // Enable VCD dump
        $dumpfile("matrix_multiplication_tb.vcd");
        $dumpvars(0, matrix_multiplication_tb);

        // Start matrix multiplication
        #10 start = 1;
        #10 start = 0;

        // Wait for completion
        wait (done);
        
        // Display result
        $display("Matrix C:");
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                $write("%d ", C[i][j]);
            end
            $write("\n");
        end
        
        $stop;
    end
endmodule
