module uart (
    input wire clk,
    input wire rst_n,
    input wire rx,
    input wire t_ack,
    input wire [7:0] t_data,
    output reg tx,
    output reg [7:0] r_data,
    output reg r_ack
);

    localparam STARTBIT = 1'b0;
    localparam STOPBIT  = 1'b1;
    localparam WORDLEN  = 8;
    localparam BAUD_CNT = 10416; // Adjust based on clock frequency

    reg [7:0] r_data_buff, t_data_buff;
    reg recv_flag, trans_flag;
    reg rx_flag, tx_flag, active;
    reg [13:0] cnt;
    reg [3:0] i, j;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_data_buff  <= 8'b0;
            t_data_buff  <= 8'b11111111;
            active       <= 1'b0;
            tx_flag      <= 1'b0;
            rx_flag      <= 1'b0;
            recv_flag    <= 1'b0;
            trans_flag   <= 1'b0;
            cnt          <= 0;
            r_ack        <= 1'b0;
            tx           <= 1'b1;
        end else begin
            if (!active) begin
                if (cnt == BAUD_CNT) begin
                    active <= 1'b1;
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 1;
                end
            end
            
            // Receiving Operation
            if (rx == STARTBIT && !recv_flag) begin
                recv_flag <= 1;
                i <= 0;
            end else if (recv_flag && i < WORDLEN) begin
                r_data_buff[i] <= rx;
                i <= i + 1;
            end else if (recv_flag && i == WORDLEN) begin
                if (rx == STOPBIT) begin
                    r_data <= r_data_buff;
                    rx_flag <= 1;
                    r_ack <= 1;
                end
                recv_flag <= 0;
            end
            
            if (rx_flag) begin
                rx_flag <= 0;
                r_ack <= 0;
            end
            
            // Transmitting Operation
            if (!tx_flag && t_ack) begin
                tx_flag <= 1;
                t_data_buff <= t_data;
            end
            
            if (tx_flag && !trans_flag) begin
                j <= 0;
                trans_flag <= 1;
                tx <= STARTBIT;
            end else if (trans_flag && j < WORDLEN) begin
                tx <= t_data_buff[j];
                j <= j + 1;
            end else if (trans_flag && j == WORDLEN) begin
                trans_flag <= 0;
                tx_flag <= 0;
                tx <= STOPBIT;
            end
        end
    end
endmodule
