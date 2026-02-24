`timescale 1ns / 1ps

module tb_quicksort;
    reg clk;
    reg rst;
    reg start;
    reg [7:0] indata [0:9];
    wire [7:0] odata [0:9];
    wire done;

    quicksort uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .indata(indata),
        .odata(odata),
        .done(done)
    );

    initial begin
        $dumpfile("quicksort.vcd");
        $dumpvars(0, tb_quicksort);
        
        clk = 0;
        rst = 0;
        start = 0;
        #10 rst = 1;
        #10 start = 1;
        
        indata[0] = 8'd45;
        indata[1] = 8'd12;
        indata[2] = 8'd78;
        indata[3] = 8'd34;
        indata[4] = 8'd23;
        indata[5] = 8'd56;
        indata[6] = 8'd89;
        indata[7] = 8'd67;
        indata[8] = 8'd90;
        indata[9] = 8'd11;
        
        #10 start = 0;
        
        $display("Input Data:");
        for (int i = 0; i < 10; i = i + 1) begin
            $write("%d ", indata[i]);
        end
        $display();

        #100; // Allow time for sorting

        $display("Sorted Output:");
        for (int i = 0; i < 10; i = i + 1) begin
            $write("%d ", odata[i]);
        end
        $display();
        
        #10 $finish;
    end
    
    always #5 clk = ~clk;
    
endmodule
