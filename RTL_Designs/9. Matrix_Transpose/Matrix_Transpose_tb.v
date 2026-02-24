module matrix_transpose_tb;
    reg clk, rst, start;
    reg [7:0] a[0:9][0:9];
    wire [7:0] transpose[0:9][0:9];
    wire done;
    integer i, j;

    matrix_transpose #(10, 10) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(a),
        .transpose(transpose),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // VCD Dump
        $dumpfile("matrix_transpose_tb.vcd");
        $dumpvars(0, matrix_transpose_tb);

        // Initialize signals
        clk = 0;
        rst = 1;
        start = 0;
        #10 rst = 0;

        // Initialize matrix with test values
        for (i = 0; i < 10; i = i + 1) begin
            for (j = 0; j < 10; j = j + 1) begin
                a[i][j] = i * 10 + j; // Example: Sequential numbers
            end
        end

        // Display original matrix
        $display("\nOriginal matrix:");
        for (i = 0; i < 10; i = i + 1) begin
            for (j = 0; j < 10; j = j + 1) begin
                $write("%d ", a[i][j]);
            end
            $write("\n");
        end

        // Start transposing
        #10 start = 1;
        #10 start = 0;

        // Display transposed matrix
        $display("\nTranspose of the matrix:");
        for (i = 0; i < 10; i = i + 1) begin
            for (j = 0; j < 10; j = j + 1) begin
                $write("%d ", transpose[i][j]);
            end
            $write("\n");
        end

        #20 $finish;
    end
endmodule
