module quicksort (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [7:0] indata [0:9],
    output reg [7:0] odata [0:9],
    output reg done
);

    reg [7:0] data [0:9];
    reg [3:0] beg [0:9], end_q [0:9];
    reg [3:0] i;
    reg [7:0] piv;
    reg [3:0] L, R;
    reg [1:0] state;
    
    localparam IDLE = 2'b00,
               LOAD = 2'b01,
               SORT = 2'b10,
               DONE = 2'b11;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            i <= 0;
            done <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= LOAD;
                        done <= 0;
                    end
                end
                
                LOAD: begin
                    for (int j = 0; j < 10; j = j + 1) begin
                        data[j] <= indata[j];
                    end
                    beg[0] <= 0;
                    end_q[0] <= 10;
                    i <= 0;
                    state <= SORT;
                end
                
                SORT: begin
                    if (i >= 0) begin
                        L = beg[i];
                        R = end_q[i] - 1;

                        if (L < R) begin
                            piv = data[L];

                            // Partitioning logic
                            while (L < R) begin
                                while (data[R] >= piv && L < R) 
                                    R = R - 1;
                                
                                if (L < R) 
                                    data[L] = data[R];

                                while (data[L] <= piv && L < R) 
                                    L = L + 1;

                                if (L < R) 
                                    data[R] = data[L];
                            end
                            data[L] = piv;

                            // Push new partition onto the stack
                            beg[i+1] = L + 1;
                            end_q[i+1] = end_q[i];
                            end_q[i] = L;
                            i = i + 1;
                        end else begin
                            if (i > 0) 
                                i = i - 1;
                            else 
                                state <= DONE;
                        end
                    end
                end
                
                DONE: begin
                    for (int j = 0; j < 10; j = j + 1) begin
                        odata[j] <= data[j];
                    end
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
