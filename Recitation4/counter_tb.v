// Set the timescale
`timescale 1 ns / 100 ps

module counter_tb();
    // Declare inputs as regs
    reg w;
    reg clock;
    reg reset; // Declared 'reset' as a reg
    
    // Declare outputs as wires
    wire [2:0] state;
    wire trigger;
    
    // Instantiate the counter module
    counter test_counter (
        .clock(clock),
        .reset(reset),
        .w(w),
        .state(state),
        .trigger(trigger)
    );
    
    // Initialize signals and apply test vectors
    initial begin
        // Display simulation start time
        $display($time, " Simulation Start");
        
        // Initialize inputs
        reset = 1'b0;
        w = 1'b0;
        clock = 1'b0;
        
        // Apply reset
        #10 reset = 1'b1; // Assert reset
        #10 reset = 1'b0; // De-assert reset
        
        // Wait for a negative edge of the clock
        @(negedge clock);
        w = 1'b0;
        
        // Apply a series of 'w' inputs
        @(negedge clock);
        w = 1'b1;
        
        @(negedge clock);
        w = 1'b1;
        
        @(negedge clock);
        w = 1'b1;
        
        @(negedge clock);
        w = 1'b1;
        
        @(negedge clock);
        w = 1'b1;
        
        @(negedge clock);
        w = 1'b1;
        
        @(negedge clock);
        w = 1'b1;
        
        // Change 'w' after some time
        #100 w = 1'b0;
        #40 w = 1'b1;
        
        // Final wait and stop simulation
        @(negedge clock);
        $stop;
    end
    
    // Generate clock signal with a period of 20 ns
    always #10 clock = ~clock;
    
    // Optional: Monitor signals for debugging
    initial begin
        $monitor("Time: %0t | Reset: %b | Clock: %b | w: %b | State: %b | Trigger: %b", 
                 $time, reset, clock, w, state, trigger);
    end
endmodule
