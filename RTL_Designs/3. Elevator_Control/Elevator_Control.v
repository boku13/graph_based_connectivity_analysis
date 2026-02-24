module Elevator_Controller (
    input clk,                 // System clock
    input reset,               // Reset signal
    input [7:0] req_floor,     // Requested floor input
    input req_valid,           // Request valid signal
    input open_door,           // Signal to open doors at a floor
    output reg [7:0] curr_floor, // Current floor
    output reg moving,         // Moving status
    output reg [1:0] direction // 00 = Idle, 01 = UP, 10 = DOWN
);

    parameter IDLE = 2'b00, UP = 2'b01, DOWN = 2'b10;

    reg [7:0] request [0:15]; // Store up to 16 floor requests
    reg [3:0] request_count;  // Number of requests stored
    integer i;

    initial begin
        curr_floor = 0;
        direction = IDLE;
        request_count = 0;
        moving = 0;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            curr_floor <= 0;
            direction <= IDLE;
            request_count <= 0;
            moving <= 0;
        end 
        else begin
            // Store new request if valid and space available
            if (req_valid && request_count < 16) begin
                request[request_count] <= req_floor;
                request_count <= request_count + 1;
            end
            
            // Determine direction
            if (request_count > 0) begin
                if (request[0] > curr_floor)
                    direction <= UP;
                else if (request[0] < curr_floor)
                    direction <= DOWN;
                else
                    direction <= IDLE;
            end else begin
                direction <= IDLE;
            end

            // Move Elevator
            if (direction == UP) begin
                curr_floor <= curr_floor + 1;
                moving <= 1;
            end 
            else if (direction == DOWN) begin
                curr_floor <= curr_floor - 1;
                moving <= 1;
            end 
            else begin
                moving <= 0;
            end

            // Stop at requested floor
            for (i = 0; i < request_count; i = i + 1) begin
                if (request[i] == curr_floor) begin
                    // Shift requests
                    for (integer j = i; j < request_count - 1; j = j + 1) begin
                        request[j] <= request[j + 1];
                    end
                    request_count <= request_count - 1;
                    moving <= 0;
                    direction <= IDLE;
                end
            end
        end
    end

endmodule
