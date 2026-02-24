module i2c_controller(
    input wire clk,
    input wire rst,
    input wire enable,
    input wire [7:0] addr,
    input wire rw,
    input wire [7:0] data_in,
    output reg ready,
    inout wire i2c_sda,
    output reg i2c_scl
);

    reg [7:0] saved_addr;
    reg [7:0] saved_data;
    reg [7:0] data_from_slave;
    reg [3:0] state;
    reg [2:0] counter;
    reg i2c_clk;
    reg i2c_scl_enable;
    reg write_enable;
    reg counter2;
    
    parameter IDLE = 4'd0,
              START = 4'd1,
              ADDRESS = 4'd2,
              READ_ACK = 4'd3,
              WRITE_DATA = 4'd4,
              READ_ACK2 = 4'd5,
              READ_DATA = 4'd6,
              WRITE_ACK = 4'd7,
              STOP = 4'd8;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i2c_clk <= 1;
            counter2 <= 0;
        end else begin
            if (counter2 == 1) begin
                i2c_clk <= ~i2c_clk;
                counter2 <= 0;
            end else begin
                counter2 <= counter2 + 1;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i2c_scl_enable <= 0;
        end else begin
            if (state == IDLE || state == START || state == STOP)
                i2c_scl_enable <= 0;
            else
                i2c_scl_enable <= 1;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (enable) begin
                        state <= START;
                        saved_addr <= {addr, rw};
                        saved_data <= data_in;
                    end
                end
                START: begin
                    counter <= 7;
                    state <= ADDRESS;
                end
                ADDRESS: begin
                    if (counter == 0)
                        state <= READ_ACK;
                    else
                        counter <= counter - 1;
                end
                READ_ACK: begin
                    if (i2c_sda == 0) begin
                        counter <= 7;
                        state <= (saved_addr[0] == 0) ? WRITE_DATA : READ_DATA;
                    end else begin
                        state <= STOP;
                    end
                end
                WRITE_DATA: begin
                    if (counter == 0)
                        state <= READ_ACK2;
                    else
                        counter <= counter - 1;
                end
                READ_ACK2: begin
                    if (i2c_sda == 0 && enable)
                        state <= IDLE;
                    else
                        state <= STOP;
                end
                READ_DATA: begin
                    data_from_slave[counter] <= i2c_sda;
                    if (counter == 0)
                        state <= WRITE_ACK;
                    else
                        counter <= counter - 1;
                end
                WRITE_ACK: state <= STOP;
                STOP: state <= IDLE;
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_enable <= 1;
        end else begin
            case (state)
                START: begin
                    write_enable <= 1;
                end
                ADDRESS: begin
                    write_enable <= 1;
                end
                READ_ACK: begin
                    write_enable <= 0;
                end
                WRITE_DATA: begin
                    write_enable <= 1;
                end
                WRITE_ACK: begin
                    write_enable <= 1;
                end
                READ_DATA: begin
                    write_enable <= 0;
                end
                STOP: begin
                    write_enable <= 1;
                end
            endcase
        end
    end

    assign i2c_sda = (write_enable) ? (state == ADDRESS ? saved_addr[counter] : state == WRITE_DATA ? saved_data[counter] : state == WRITE_ACK ? 1'b0 : 1'bz) : 1'bz;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ready <= 0;
        end else begin
            ready <= (state == IDLE) ? 1 : 0;
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i2c_scl <= 1;
        end else begin
            i2c_scl <= (i2c_scl_enable == 0) ? 1 : i2c_clk;
        end
    end

endmodule
