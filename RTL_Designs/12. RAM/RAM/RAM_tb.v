`timescale 1ns / 1ps

module Memory_tb;
    reg clk;
    reg [1:0] func;
    reg [8:0] addr;
    wire [31:0] data;
    reg [31:0] data_reg;
    reg data_en;
    wire [1:0] doneSig;
    
    assign data = data_en ? data_reg : 32'bz;
    
    Memory uut (
        .clk(clk),
        .func(func),
        .addr(addr),
        .data(data),
        .doneSig(doneSig)
    );
    
    always #5 clk = ~clk;
    
    initial begin
        $dumpfile("memory_tb.vcd");
        $dumpvars(0, Memory_tb);
        
        clk = 0;
        func = 2'b00;
        addr = 9'b0;
        data_reg = 32'b0;
        data_en = 0;
        
        #10;
        
        // Write operation at address 5
        addr = 9'd5;
        data_reg = 32'hA5A5A5A5;
        data_en = 1;
        func = 2'b10;
        #10;
        func = 2'b00;
        data_en = 0;
        
        #200;
        
        // Read operation from address 5
        addr = 9'd5;
        func = 2'b01;
        #10;
        func = 2'b00;
        
        #200;
        
        // Write operation at address 10
        addr = 9'd10;
        data_reg = 32'h5A5A5A5A;
        data_en = 1;
        func = 2'b10;
        #10;
        func = 2'b00;
        data_en = 0;
        
        #200;
        
        // Read operation from address 10
        addr = 9'd10;
        func = 2'b01;
        #10;
        func = 2'b00;
        
        #200;
        
        // Invalid read operation from out-of-bounds address
        addr = 9'd600;
        func = 2'b01;
        #10;
        func = 2'b00;
        
        #200;
        
        // Invalid write operation to out-of-bounds address
        addr = 9'd600;
        data_reg = 32'hDEADBEEF;
        data_en = 1;
        func = 2'b10;
        #10;
        func = 2'b00;
        data_en = 0;
        
        #200;
        
        // Sequential write operations
        addr = 9'd15;
        data_reg = 32'h12345678;
        data_en = 1;
        func = 2'b10;
        #10;
        func = 2'b00;
        
        addr = 9'd16;
        data_reg = 32'h87654321;
        data_en = 1;
        func = 2'b10;
        #10;
        func = 2'b00;
        data_en = 0;
        
        #200;
        
        // Sequential read operations
        addr = 9'd15;
        func = 2'b01;
        #10;
        func = 2'b00;
        
        addr = 9'd16;
        func = 2'b01;
        #10;
        func = 2'b00;
        
        #200;
        
        $stop;
    end
endmodule
