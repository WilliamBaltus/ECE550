`timescale 1 ns / 100 ps

module skeleton_tb;

    // Testbench signals
    reg clock;
    reg reset;

    // Clocks generated by the skeleton module
    wire imem_clock;
    wire dmem_clock;
    wire processor_clock;
    wire regfile_clock;

    // Declare integer for loop
    integer i;

    // Instantiate the skeleton module
    skeleton uut (
        .clock(clock),
        .reset(reset),
        .imem_clock(imem_clock),
        .dmem_clock(dmem_clock),
        .processor_clock(processor_clock),
        .regfile_clock(regfile_clock)
    );

    // Generate main clock (50 MHz, 20 ns period)
    always #10 clock = ~clock;

    initial begin
        // Display initial message to confirm testbench starts
        $display("Starting testbench...");

        // Initialize clock and reset
        clock = 0;
        reset = 1;
        
        // Wait a few cycles, then deassert reset
        #20 reset = 0;
        $display("Reset deasserted");

        // Run the processor for a larger number of cycles, checking registers periodically
        repeat (40) @(posedge processor_clock); // First set of cycles
        $display("Register values after 40 processor cycles:");
        for (i = 0; i < 32; i = i + 1) begin
            $display("Register %0d: %h (hex) --- %0d (signed decimal)", i, $signed(uut.my_regfile.registers[i]), $signed(uut.my_regfile.registers[i]));
        end

        // Continue for additional cycles to cover the entire instruction set
        repeat (80) @(posedge processor_clock); // Next set of cycles
        $display("Register values after 120 processor cycles:");
        for (i = 0; i < 32; i = i + 1) begin
            $display("Register %0d: %h (hex) --- %0d (signed decimal)", i, $signed(uut.my_regfile.registers[i]), $signed(uut.my_regfile.registers[i]));
        end

//        // Final check after more cycles to ensure all instructions have run
//        repeat (240) @(posedge processor_clock); // Final set of cycles
//        $display("Final register values after 360 processor cycles:");
//        for (i = 0; i < 32; i = i + 1) begin
//            $display("Register %0d: %h (hex) --- %0d (signed decimal)", i, $signed(uut.my_regfile.registers[i]), $signed(uut.my_regfile.registers[i]));
//        end

        // End simulation
        $display("Ending testbench.");
        $finish;
    end

endmodule

