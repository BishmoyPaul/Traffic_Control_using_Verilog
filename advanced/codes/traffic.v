module traffic (
    input wire clk,              
    input wire reset,            
    input wire [1:0] mode_select,// Mode selection: 00-normal, 01-increased traffic, 10-emergency
    input wire traffic_sensor,   // Traffic sensor input (1 if increased traffic on horizontal road)
    input wire emergency,        // Emergency signal (1 if emergency vehicle detected)
    output reg [1:0] horizontal_light, 
    output reg [1:0] vertical_light    
);

    // Light color definitions
    parameter RED = 2'b00;
    parameter YELLOW = 2'b01;
    parameter GREEN = 2'b10;
    parameter GREEN_BLINK = 2'b11;
    parameter RED_YELLOW = 2'b01;  // We'll use the same value as YELLOW for RED+YELLOW
    
    // State definitions
    parameter [3:0] S_H_RED_V_GREEN = 4'b0000;        // Horizontal RED, Vertical GREEN
    parameter [3:0] S_H_RED_V_GREEN_BLINK = 4'b0001;  // Horizontal RED, Vertical GREEN BLINKING
    parameter [3:0] S_H_RED_V_YELLOW = 4'b0010;       // Horizontal RED, Vertical YELLOW
    parameter [3:0] S_H_RED_V_RED = 4'b0011;          // Horizontal RED, Vertical RED
    parameter [3:0] S_H_RED_YELLOW_V_RED = 4'b0100;   // Horizontal RED+YELLOW, Vertical RED
    parameter [3:0] S_H_GREEN_V_RED = 4'b0101;        // Horizontal GREEN, Vertical RED
    parameter [3:0] S_H_GREEN_BLINK_V_RED = 4'b0110;  // Horizontal GREEN BLINKING, Vertical RED
    parameter [3:0] S_H_YELLOW_V_RED = 4'b0111;       // Horizontal YELLOW, Vertical RED
    parameter [3:0] S_H_RED_V_RED_2 = 4'b1000;        // Horizontal RED, Vertical RED (second instance)
    parameter [3:0] S_H_RED_V_RED_YELLOW = 4'b1001;   // Horizontal RED, Vertical RED+YELLOW
    parameter [3:0] S_EMERGENCY = 4'b1111;            // Emergency mode - flashing yellow
    
    // Timer constants 
    parameter [7:0] T1 = 8'd40;  // Time for GREEN signals
    parameter [7:0] T2 = 8'd15;  // Time for GREEN BLINK signals
    parameter [7:0] T3 = 8'd10;  // Time for YELLOW signals
    parameter [7:0] T4 = 8'd5;   // Time for RED-RED transition
    parameter [7:0] T5 = 8'd3;   // Time for RED+YELLOW signals
    
    // Mode parameters
    parameter [1:0] MODE_NORMAL = 2'b00;
    parameter [1:0] MODE_TRAFFIC = 2'b01;
    parameter [1:0] MODE_EMERGENCY = 2'b10;
    
    // Registers
    reg [3:0] current_state;
    reg [7:0] timer;
    reg blink_toggle;
    reg [3:0] blink_counter;
    reg [1:0] active_mode;
    reg [7:0] time_multiplier;
    
    // Blink timer constant
    parameter [3:0] BLINK_TIME = 4'd5;
    
    // Traffic modifiers
    parameter [7:0] NORMAL_MULT = 8'd1;    // Normal multiplier
    parameter [7:0] TRAFFIC_MULT_HIGH = 8'd2; // High traffic multiplier
    
    // Update active mode based on inputs
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            active_mode <= MODE_NORMAL;
        end
        else begin
            if (emergency)
                active_mode <= MODE_EMERGENCY;
            else
                active_mode <= mode_select;
        end
    end
    
    // Blink toggle generator (for flashing lights)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            blink_counter <= 4'd0;
            blink_toggle <= 1'b0;
        end
        else if (blink_counter >= BLINK_TIME) begin
            blink_counter <= 4'd0;
            blink_toggle <= ~blink_toggle;
        end
        else begin
            blink_counter <= blink_counter + 1'b1;
        end
    end
    
    // Calculate time multiplier based on state and traffic conditions
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            time_multiplier <= NORMAL_MULT;
        end
        else begin
            case (current_state)
                S_H_RED_V_GREEN: begin
                    if (active_mode == MODE_TRAFFIC && !traffic_sensor)
                        time_multiplier <= TRAFFIC_MULT_HIGH;
                    else
                        time_multiplier <= NORMAL_MULT;
                end
                
                S_H_GREEN_V_RED: begin
                    if (active_mode == MODE_TRAFFIC && traffic_sensor)
                        time_multiplier <= TRAFFIC_MULT_HIGH;
                    else
                        time_multiplier <= NORMAL_MULT;
                end
                
                default: begin
                    time_multiplier <= NORMAL_MULT;
                end
            endcase
        end
    end
    
    // State transition and timer logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= S_H_RED_V_GREEN;
            timer <= 8'd0;
        end
        else begin
            // Handle emergency mode separately
            if (active_mode == MODE_EMERGENCY) begin
                current_state <= S_EMERGENCY;
                timer <= 8'd0;
            end
            else begin
                // Timer increments
                timer <= timer + 1'b1;
                

                case (current_state)
                    S_H_RED_V_GREEN: begin
                        if (timer >= (T1 * time_multiplier)) begin
                            timer <= 8'd0;
                            current_state <= S_H_RED_V_GREEN_BLINK;
                        end
                    end
                    
                    S_H_RED_V_GREEN_BLINK: begin
                        if (timer >= T2) begin
                            timer <= 8'd0;
                            current_state <= S_H_RED_V_YELLOW;
                        end
                    end
                    
                    S_H_RED_V_YELLOW: begin
                        if (timer >= T3) begin
                            timer <= 8'd0;
                            current_state <= S_H_RED_V_RED;
                        end
                    end
                    
                    S_H_RED_V_RED: begin
                        if (timer >= T4) begin
                            timer <= 8'd0;
                            current_state <= S_H_RED_YELLOW_V_RED;
                        end
                    end
                    
                    S_H_RED_YELLOW_V_RED: begin
                        if (timer >= T5) begin
                            timer <= 8'd0;
                            current_state <= S_H_GREEN_V_RED;
                        end
                    end
                    
                    S_H_GREEN_V_RED: begin
                        if (timer >= (T1 * time_multiplier)) begin
                            timer <= 8'd0;
                            current_state <= S_H_GREEN_BLINK_V_RED;
                        end
                    end
                    
                    S_H_GREEN_BLINK_V_RED: begin
                        if (timer >= T2) begin
                            timer <= 8'd0;
                            current_state <= S_H_YELLOW_V_RED;
                        end
                    end
                    
                    S_H_YELLOW_V_RED: begin
                        if (timer >= T3) begin
                            timer <= 8'd0;
                            current_state <= S_H_RED_V_RED_2;
                        end
                    end
                    
                    S_H_RED_V_RED_2: begin
                        if (timer >= T4) begin
                            timer <= 8'd0;
                            current_state <= S_H_RED_V_RED_YELLOW;
                        end
                    end
                    
                    S_H_RED_V_RED_YELLOW: begin
                        if (timer >= T5) begin
                            timer <= 8'd0;
                            current_state <= S_H_RED_V_GREEN;
                        end
                    end
                    
                    S_EMERGENCY: begin
                        // Stay in emergency mode until emergency signal is cleared
                        if (active_mode != MODE_EMERGENCY) begin
                            timer <= 8'd0;
                            current_state <= S_H_RED_V_GREEN;
                        end
                    end
                    
                    default: begin
                        timer <= 8'd0;
                        current_state <= S_H_RED_V_GREEN;
                    end
                endcase
            end
        end
    end
    
    // Output logic
    always @(*) begin
        case (current_state)
            S_H_RED_V_GREEN: begin
                horizontal_light = RED;
                vertical_light = GREEN;
            end
            
            S_H_RED_V_GREEN_BLINK: begin
                horizontal_light = RED;
                vertical_light = blink_toggle ? GREEN : GREEN_BLINK;
            end
            
            S_H_RED_V_YELLOW: begin
                horizontal_light = RED;
                vertical_light = YELLOW;
            end
            
            S_H_RED_V_RED, S_H_RED_V_RED_2: begin
                horizontal_light = RED;
                vertical_light = RED;
            end
            
            S_H_RED_YELLOW_V_RED: begin
                horizontal_light = RED_YELLOW;
                vertical_light = RED;
            end
            
            S_H_GREEN_V_RED: begin
                horizontal_light = GREEN;
                vertical_light = RED;
            end
            
            S_H_GREEN_BLINK_V_RED: begin
                horizontal_light = blink_toggle ? GREEN : GREEN_BLINK;
                vertical_light = RED;
            end
            
            S_H_YELLOW_V_RED: begin
                horizontal_light = YELLOW;
                vertical_light = RED;
            end
            
            S_H_RED_V_RED_YELLOW: begin
                horizontal_light = RED;
                vertical_light = RED_YELLOW;
            end
            
            S_EMERGENCY: begin
                horizontal_light = blink_toggle ? YELLOW : RED;
                vertical_light = blink_toggle ? YELLOW : RED;
            end
            
            default: begin
                horizontal_light = RED;
                vertical_light = RED;
            end
        endcase
    end

endmodule