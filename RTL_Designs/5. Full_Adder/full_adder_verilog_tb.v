// Testbench for Full Adder
module testbench;
    reg A, B, C_In;
    wire Sum, C_Out;
    
    // Instantiate the Full Adder module
    Full_Adder uut (
        .A(A), 
        .B(B), 
        .C_In(C_In), 
        .Sum(Sum), 
        .C_Out(C_Out)
    );
    
    initial begin
        // Dump waveform to VCD file
        $dumpfile("full_adder.vcd");
        $dumpvars(0, testbench);
        
        // Monitor output
        $monitor("A = %b, B = %b, C_In = %b | Sum = %b, C_Out = %b", A, B, C_In, Sum, C_Out);
        
        // Apply test cases
        A = 0; B = 0; C_In = 0; #10;
        A = 0; B = 0; C_In = 1; #10;
        A = 0; B = 1; C_In = 0; #10;
        A = 0; B = 1; C_In = 1; #10;
        A = 1; B = 0; C_In = 0; #10;
        A = 1; B = 0; C_In = 1; #10;
        A = 1; B = 1; C_In = 0; #10;
        A = 1; B = 1; C_In = 1; #10;
        
        // End simulation
        $finish;
    end
endmodule
