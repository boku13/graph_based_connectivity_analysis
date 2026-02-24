module ALU (
    input [15:0] operandA,
    input [15:0] operandB,
    input [2:0] opcode,
    output reg [15:0] resultR,
    output reg [3:0] PSR
);

    // Opcodes
    localparam ADD = 3'b000;
    localparam SUB = 3'b001;
    localparam NEG = 3'b010;
    localparam NOT = 3'b011;
    localparam AND_OP = 3'b100;
    localparam OR_OP = 3'b101;

    always @(*) begin
        case (opcode)
            ADD: {PSR[3], resultR} = operandA + operandB; // Carry out captured in PSR[3]
            SUB: {PSR[3], resultR} = operandA - operandB;
            NEG: resultR = -operandA;
            NOT: resultR = ~operandA;
            AND_OP: resultR = operandA & operandB;
            OR_OP: resultR = operandA | operandB;
            default: resultR = 16'h0000;
        endcase
        
        // Set flags
        PSR[2] = (resultR == 16'b0) ? 1'b1 : 1'b0; // Zero flag
        PSR[1] = resultR[15]; // Negative flag
        PSR[0] = (^resultR) ? 1'b1 : 1'b0; // Overflow (parity check as an example)
    end

endmodule
