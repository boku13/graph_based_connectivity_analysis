module sequence_detector (
    input wire clk,
    input wire rst,
    input wire serial_input,
    output reg mealy_output
);

    typedef enum reg [2:0] {
        S0 = 3'b000,
        S1 = 3'b001,
        S2 = 3'b010,
        S3 = 3'b011,
        S4 = 3'b100
    } state_t;

    state_t present_state, next_state;

    // Sequential Logic
    always @(posedge clk or posedge rst) begin
        if (rst)
            present_state <= S0;
        else
            present_state <= next_state;
    end

    // Combinational Logic
    always @(*) begin
        mealy_output = 1'b0;
        next_state = S0;
        
        case (present_state)
            S0: next_state = (serial_input) ? S1 : S0;
            S1: next_state = (serial_input) ? S2 : S0;
            S2: next_state = (serial_input) ? S2 : S3;
            S3: next_state = (serial_input) ? S4 : S0;
            S4: begin
                next_state = (serial_input) ? S2 : S0;
                mealy_output = ~serial_input; // output is 1 when input is 0 in S4
            end
        endcase
    end
endmodule