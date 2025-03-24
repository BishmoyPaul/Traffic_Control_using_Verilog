module traffic (
    input wire clk,         
    input wire reset,      
    input wire x1,          
    output reg [1:0] horizontal_light, 
    output reg [1:0] vertical_light    
);

    // Light color definitions
    parameter RED = 2'b00;
    parameter YELLOW = 2'b10;
    parameter GREEN = 2'b11;
    
    parameter [1:0] STATE_H_RED_V_GREEN = 2'b00;
    parameter [1:0] STATE_H_YELLOW_V_YELLOW = 2'b01;
    parameter [1:0] STATE_H_GREEN_V_RED = 2'b10;   
    parameter [1:0] STATE_H_YELLOW_V_YELLOW_2 = 2'b11; // Duplicate state for the pattern
    
    // Current state register
    reg [1:0] current_state;
    
    // State transition logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= STATE_H_RED_V_GREEN;
        end
        else begin
            case (current_state)
                STATE_H_RED_V_GREEN: begin
                    if (~x1) current_state <= STATE_H_YELLOW_V_YELLOW;
                end
                
                STATE_H_YELLOW_V_YELLOW: begin
                    if (~x1) current_state <= STATE_H_GREEN_V_RED;
                end
                
                STATE_H_GREEN_V_RED: begin
                    if (~x1) current_state <= STATE_H_YELLOW_V_YELLOW_2;
                end
                
                STATE_H_YELLOW_V_YELLOW_2: begin
                    if (~x1) current_state <= STATE_H_RED_V_GREEN;
                end
                
                default: current_state <= STATE_H_RED_V_GREEN;
            endcase
        end
    end
    
    // Output logic
    always @(*) begin
        case (current_state)
            STATE_H_RED_V_GREEN: begin
                horizontal_light = RED;
                vertical_light = GREEN;
            end
            
            STATE_H_YELLOW_V_YELLOW, STATE_H_YELLOW_V_YELLOW_2: begin
                horizontal_light = YELLOW;
                vertical_light = YELLOW;
            end

            STATE_H_GREEN_V_RED: begin
                horizontal_light = GREEN;
                vertical_light = RED;
            end
            
            default: begin
                horizontal_light = RED;
                vertical_light = RED;
            end
        endcase
    end

endmodule