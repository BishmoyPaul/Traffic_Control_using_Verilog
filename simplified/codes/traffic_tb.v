module traffic_tb;
    // Parameters
    parameter CLK_PERIOD = 10; // Clock period in time units
    parameter TEST_DURATION = 1000; // Total simulation time

    // Test bench signals
    reg clk;
    reg reset;
    reg x1;
    wire [1:0] horizontal_light;
    wire [1:0] vertical_light;
    
    // Expected outputs for verification
    reg [1:0] expected_h_light;
    reg [1:0] expected_v_light;
    
    // Light color definitions 
    localparam RED = 2'b00;
    localparam YELLOW = 2'b10;
    localparam GREEN = 2'b11;
    
    // State definitions 
    localparam STATE_H_RED_V_GREEN = 2'b00;
    localparam STATE_H_YELLOW_V_YELLOW = 2'b01;
    localparam STATE_H_GREEN_V_RED = 2'b10;   
    localparam STATE_H_YELLOW_V_YELLOW_2 = 2'b11;
    
    // For tracking test results
    integer error_count = 0;
    
    traffic dut (
        .clk(clk),
        .reset(reset),
        .x1(x1),
        .horizontal_light(horizontal_light),
        .vertical_light(vertical_light)
    );
    

    always #(CLK_PERIOD/2) clk = ~clk;
    
    // Monitoring for verification
    always @(posedge clk) begin
        if (!reset) begin
            verify_outputs();
        end
    end
    
    // Verification task
    task verify_outputs;
        begin
            case (dut.current_state)
                STATE_H_RED_V_GREEN: begin
                    expected_h_light = RED;
                    expected_v_light = GREEN;
                end
                
                STATE_H_YELLOW_V_YELLOW, STATE_H_YELLOW_V_YELLOW_2: begin
                    expected_h_light = YELLOW;
                    expected_v_light = YELLOW;
                end
                
                STATE_H_GREEN_V_RED: begin
                    expected_h_light = GREEN;
                    expected_v_light = RED;
                end
                
                default: begin
                    expected_h_light = RED;
                    expected_v_light = RED;
                end
            endcase
            
            // Check if outputs match expected values
            if (horizontal_light !== expected_h_light || vertical_light !== expected_v_light) begin
                $display("ERROR at time %0t: State=%b, H_Light=%b (Expected=%b), V_Light=%b (Expected=%b)",
                         $time, dut.current_state, horizontal_light, expected_h_light, 
                         vertical_light, expected_v_light);
                error_count = error_count + 1;
            end
        end
    endtask


    initial begin
        // Initialize inputs
        clk = 0;
        reset = 1;
        x1 = 1; // Start with x1 high (no transitions)
        
        // Display header
        $display("======= TRAFFIC LIGHT CONTROLLER TESTBENCH =======");
        $display("Time\tReset\tx1\tState\t\tH_Light\tV_Light");
        $display("------------------------------------------------");
        
        // Apply reset
        #(CLK_PERIOD*2);
        reset = 0;
        #(CLK_PERIOD);
        
        // Test normal operation - one complete cycle
        // Display initial state
        display_status();
        
        // Transition through all states
        x1 = 0; // Enable transitions
        #(CLK_PERIOD);
        display_status(); 
        
        #(CLK_PERIOD);
        display_status(); 
        
        #(CLK_PERIOD);
        display_status(); 
        
        #(CLK_PERIOD);
        display_status(); 
        
        // Test staying in current state
        x1 = 1; // Disable transitions
        #(CLK_PERIOD*3);
        display_status(); 
        // Test reset during operation
        x1 = 0; // Enable transitions
        #(CLK_PERIOD);
        display_status(); 
        
        reset = 1; // Apply reset
        #(CLK_PERIOD);
        display_status(); 
        
        reset = 0;
        #(CLK_PERIOD);
        
        // Let it run for a few more cycles
        x1 = 0;
        #(CLK_PERIOD*8);
        
        // Summary
        if (error_count == 0) begin
            $display("\nTEST PASSED: All output values matched expected values");
        end else begin
            $display("\nTEST FAILED: %0d errors detected", error_count);
        end
        
        $display("======= TEST COMPLETE =======");
        $finish;
    end
    
    // Helper task to display current status
    task display_status;
        begin
            $display("%0t\t%b\t%b\t%b (%s)\t%b (%s)\t%b (%s)",
                     $time, reset, x1, dut.current_state, state_to_string(dut.current_state),
                     horizontal_light, light_to_string(horizontal_light),
                     vertical_light, light_to_string(vertical_light));
        end
    endtask
    
    // Convert state to string for display
    function [40*8-1:0] state_to_string;
        input [1:0] state;
        begin
            case (state)
                STATE_H_RED_V_GREEN: state_to_string = "H_RED_V_GREEN";
                STATE_H_YELLOW_V_YELLOW: state_to_string = "H_YELLOW_V_YELLOW";
                STATE_H_GREEN_V_RED: state_to_string = "H_GREEN_V_RED";
                STATE_H_YELLOW_V_YELLOW_2: state_to_string = "H_YELLOW_V_YELLOW_2";
                default: state_to_string = "UNKNOWN";
            endcase
        end
    endfunction
    
    // Convert light code to string
    function [8*8-1:0] light_to_string;
        input [1:0] light;
        begin
            case (light)
                RED: light_to_string = "RED";
                YELLOW: light_to_string = "YELLOW";
                GREEN: light_to_string = "GREEN";
                default: light_to_string = "UNKNOWN";
            endcase
        end
    endfunction

endmodule