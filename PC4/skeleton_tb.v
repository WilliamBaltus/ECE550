`timescale 1 ns / 100 ps

module skeleton_tb();

    // Declare testbench signals
    reg clock;
    reg reset;

    // Clocks from skeleton module
    wire imem_clock;
    wire dmem_clock;
    wire processor_clock;
    wire regfile_clock;

    // Instantiate the skeleton module (top-level processor wrapper)
    skeleton uut (
        .clock(clock),
        .reset(reset),
        .imem_clock(imem_clock),
        .dmem_clock(dmem_clock),
        .processor_clock(processor_clock),
        .regfile_clock(regfile_clock)
    );

    // Clock generation similar to your TA's example (50 MHz clock)
    always #10 clock = ~clock;

    initial begin
        // Display start message
        $display($time, " simulation start");

        // Initialize the clock and reset signals
        clock = 0;
        reset = 1;
        
        // Release reset after one clock cycle
        @(negedge clock);
        reset = 0;

        // Print a header for easier reading
        $display("Time      | Main Clock | Reset | IMEM Clock | DMEM Clock | Processor Clock | Regfile Clock");
        $display("----------|------------|-------|------------|------------|-----------------|--------------");

        // Run indefinitely, checking the clocks on every negedge of the main clock
        while (1) begin
            @(negedge clock);
            $display("%0t |    %b       |   %b   |     %b      |     %b      |        %b        |      %b",
                     $time, clock, reset, imem_clock, dmem_clock, processor_clock, regfile_clock);
        end
    end

endmodule
