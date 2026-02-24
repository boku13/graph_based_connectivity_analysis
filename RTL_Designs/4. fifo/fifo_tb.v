// Testbench for FIFO
module FIFO_tb;
    reg write_clk;
    reg read_clk;
    reg rst;
    reg write_en;
    reg [7:0] data_in;
    wire [7:0] data_out;

    // Instantiate FIFO module
    FIFO uut (
        .write_clk(write_clk),
        .read_clk(read_clk),
        .rst(rst),
        .write_en(write_en),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation
    initial begin
        write_clk = 0;
        forever #5 write_clk = ~write_clk; // 100 MHz clock
    end

    initial begin
        read_clk = 0;
        forever #50 read_clk = ~read_clk; // 10 MHz clock
    end

    // Test sequence
    initial begin
        $dumpfile("fifo_tb.vcd");
        $dumpvars(0, FIFO_tb);
        
        rst = 1;
        write_en = 0;
        data_in = 0;
        #20 rst = 0;

        // Test writing to FIFO till full
        write_en = 1;
        for (int i = 0; i < 360; i = i + 1) begin
            data_in = i[7:0];
            #10;
        end
        write_en = 0;
        
        // Test additional write when FIFO is full
        data_in = 8'hFF;
        #10;
        
        // Test reading from FIFO till empty
        #500;
        for (int i = 0; i < 360; i = i + 1) begin
            #100;
        end
        
        // Test additional read when FIFO is empty
        #100;
        
        // Test reset during operation
        rst = 1;
        #20 rst = 0;
        
        // Test simultaneous write and read
        write_en = 1;
        for (int i = 0; i < 100; i = i + 1) begin
            data_in = i[7:0];
            #10;
        end
        write_en = 0;
        
        #500;
        $finish;
    end
endmodule
