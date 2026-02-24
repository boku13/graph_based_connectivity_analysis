module sequence_detector_1001 (
    input wire clk,
    input wire reset,
    input wire seq_in,
    output reg seq_detect
);

    typedef enum logic [2:0] {IDLE, S1, S2, S3, DETECT} state_t;
    state_t current_state, next_state;

    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    always @(*) begin
        case (current_state)
            IDLE:    next_state = (seq_in) ? S1 : IDLE;
            S1:      next_state = (seq_in) ? S1 : S2;
            S2:      next_state = (seq_in) ? S1 : S3;
            S3:      next_state = (seq_in) ? DETECT : IDLE;
            DETECT:  next_state = (seq_in) ? S1 : IDLE;
            default: next_state = IDLE;
        endcase
    end

    always @(*) begin
        seq_detect = (current_state == DETECT) ? 1'b1 : 1'b0;
    end

endmodule
