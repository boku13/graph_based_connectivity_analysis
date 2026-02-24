// Verilog module for Full Adder
module Full_Adder(
    input A,
    input B,
    input C_In,
    output Sum,
    output C_Out
);
    
    // Sum calculation
    assign Sum = C_In ^ (A ^ B);
    
    // Carry-Out calculation
    assign C_Out = (A & B) | (B & C_In) | (A & C_In);
    
endmodule
