module traffic_tb;

    parameter CLK_PERIOD = 10;   // Clock period in simulation time units
    

    reg clk;
    reg reset;
    reg [1:0] mode_select;
    reg traffic_sensor;
    reg emergency;
    wire [1:0] horizontal_light;
    wire [1:0] vertical_light;
    
    // For state tracking
    reg [3:0] prev_state;
    reg [7:0] state_timer = 0;
    
    // Light color definitions 
    localparam RED = 2'b00;
    localparam YELLOW = 2'b01;
    localparam GREEN = 2'b10;
    localparam GREEN_BLINK = 2'b11;
    
    // Mode parameters
    localparam MODE_NORMAL = 2'b00;
    localparam MODE_TRAFFIC = 2'b01;
    localparam MODE_EMERGENCY = 2'b10;
    
    // State names for easier debugging
    localparam S_H_RED_V_GREEN = 4'b0000;
    localparam S_H_RED_V_GREEN_BLINK = 4'b0001;
    localparam S_H_RED_V_YELLOW = 4'b0010;
    localparam S_H_RED_V_RED = 4'b0011;
    localparam S_H_RED_YELLOW_V_RED = 4'b0100;
    localparam S_H_GREEN_V_RED = 4'b0101;
    localparam S_H_GREEN_BLINK_V_RED = 4'b0110;
    localparam S_H_YELLOW_V_RED = 4'b0111;
    localparam S_H_RED_V_RED_2 = 4'b1000;
    localparam S_H_RED_V_RED_YELLOW = 4'b1001;
    localparam S_EMERGENCY = 4'b1111;
    

    traffic dut (
        .clk(clk),
        .reset(reset),
        .mode_select(mode_select),
        .traffic_sensor(traffic_sensor),
        .emergency(emergency),
        .horizontal_light(horizontal_light),
        .vertical_light(vertical_light)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Helper function to convert state to string
    function [25*8-1:0] state_to_string;
        input [3:0] state;
        begin
            case (state)
                S_H_RED_V_GREEN: state_to_string = "S_H_RED_V_GREEN";
                S_H_RED_V_GREEN_BLINK: state_to_string = "S_H_RED_V_GREEN_BLINK";
                S_H_RED_V_YELLOW: state_to_string = "S_H_RED_V_YELLOW";
                S_H_RED_V_RED: state_to_string = "S_H_RED_V_RED";
                S_H_RED_YELLOW_V_RED: state_to_string = "S_H_RED_YELLOW_V_RED";
                S_H_GREEN_V_RED: state_to_string = "S_H_GREEN_V_RED";
                S_H_GREEN_BLINK_V_RED: state_to_string = "S_H_GREEN_BLINK_V_RED";
                S_H_YELLOW_V_RED: state_to_string = "S_H_YELLOW_V_RED";
                S_H_RED_V_RED_2: state_to_string = "S_H_RED_V_RED_2";
                S_H_RED_V_RED_YELLOW: state_to_string = "S_H_RED_V_RED_YELLOW";
                S_EMERGENCY: state_to_string = "S_EMERGENCY";
                default: state_to_string = "UNKNOWN";
            endcase
        end
    endfunction
    
    // Helper function to convert light to string
    function [12*8-1:0] light_to_string;
        input [1:0] light;
        begin
            case (light)
                RED: light_to_string = "RED";
                YELLOW: light_to_string = "YELLOW";
                GREEN: light_to_string = "GREEN";
                GREEN_BLINK: light_to_string = "GREEN_BLINK";
                default: light_to_string = "UNKNOWN";
            endcase
        end
    endfunction
    
    // State transition detection
    always @(posedge clk) begin
        if (reset) begin
            prev_state <= dut.current_state;
            state_timer <= 0;
        end
        else begin
            // If state changed
            if (prev_state != dut.current_state) begin
                // Display state transition and timing
                $display("Time %0t: State transition from %s to %s after %0d cycles", 
                         $time, state_to_string(prev_state), 
                         state_to_string(dut.current_state), state_timer);
                
                // Also display the current light status
		if (emergency) begin
                $display("  Horizontal light: %s, Vertical light: %s", 
                         light_to_string(horizontal_light), 
                         light_to_string(vertical_light));
		end
                
                // Reset timer and update previous state
                state_timer <= 0;
                prev_state <= dut.current_state;
            end
            else begin
                // Increment timer while in the same state
                state_timer <= state_timer + 1;
            end
        end
    end
    
    // Test sequence
    initial begin
        // Initialize inputs
        clk = 0;
        reset = 1;
        mode_select = MODE_NORMAL;
        traffic_sensor = 0;
        emergency = 0;
        
        // Display header
        $display("======= TRAFFIC LIGHT CONTROLLER TEST =======");
        $display("Testing normal mode sequence and timing...");
        
        // Apply reset
        #(CLK_PERIOD*2);
        reset = 0;
        
        // Let it run for one complete cycle in normal mode
        #(CLK_PERIOD*200);
        
        // Test emergency mode
        $display("\nSwitching to emergency mode...");
        emergency = 1;
        #(CLK_PERIOD*50);
        
        // Return to normal mode
        $display("\nReturning to normal mode...");
        emergency = 0;
        #(CLK_PERIOD*50);
        
        // Test traffic mode with sensor active
        $display("\nSwitching to traffic mode with sensor active...");
        mode_select = MODE_TRAFFIC;
        traffic_sensor = 1;
        #(CLK_PERIOD*200);
        
        // Test traffic mode with sensor inactive
        $display("\nSwitching to traffic mode with sensor inactive...");
        traffic_sensor = 0;
        #(CLK_PERIOD*200);
        
        // Return to normal mode to complete the test
        $display("\nReturning to normal mode...");
        mode_select = MODE_NORMAL;
        #(CLK_PERIOD*50);
        
        $display("\n======= TEST COMPLETE =======");
        $finish;
    end

endmodule