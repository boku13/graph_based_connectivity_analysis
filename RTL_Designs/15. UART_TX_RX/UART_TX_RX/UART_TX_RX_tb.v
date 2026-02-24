module uart_tb;
    reg clk;
    reg rst_n;
    reg rx;
    reg t_ack;
    reg [7:0] t_data;
    wire tx;
    wire [7:0] r_data;
    wire r_ack;

    // Instantiate the UART module
    uart uut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .t_ack(t_ack),
        .t_data(t_data),
        .tx(tx),
        .r_data(r_data),
        .r_ack(r_ack)
    );

    // Clock generation
    always #5 clk = ~clk; // 100MHz clock

    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        rx = 1;
        t_ack = 0;
        t_data = 8'b0;
        
        // VCD dump setup
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb);
        
        // Reset sequence
        #20 rst_n = 1;
        
        // Test transmission
        #10 t_data = 8'b00111010;
        t_ack = 1;
        #10 t_ack = 0;
        
        // Wait for transmission to complete
        #100;
        
        // Test reception
        #10 rx = 0; // Start bit
        #10 rx = 1; // Data bits
        #10 rx = 0;
        #10 rx = 1;
        #10 rx = 0;
        #10 rx = 1;
        #10 rx = 0;
        #10 rx = 1;
        #10 rx = 1; // Stop bit
        
        #100;
        
        // Finish simulation
        $stop;
    end
endmodule
