module skeleton_tb;

    // Declare testbench signals for clock and reset
    reg clock;
    reg reset;
    
    // Declare wires to observe outputs from skeleton module
    wire imem_clock;
    wire dmem_clock;
    wire processor_clock;
    wire regfile_clock;
    wire [11:0] address_imem;
    wire [31:0] q_imem;

    // Instantiate the skeleton module (Unit Under Test, or UUT)
    skeleton uut (
        .clock(clock),
        .reset(reset),
        .imem_clock(imem_clock),
        .dmem_clock(dmem_clock),
        .processor_clock(processor_clock),
        .regfile_clock(regfile_clock)
    );

    // Clock Generation: Toggle clock every 10 ns for a 50 MHz clock
    initial begin
        clock = 0;
        forever #10 clock = ~clock; // 50 MHz clock (period of 20 ns)
    end

    // Simulation control
    initial begin
        // Initialize reset
        reset = 1;
        #20; // Keep reset high for 20 ns to initialize the PC
        reset = 0; // Release reset, allowing the processor to start executing

        // Run the simulation for a specified amount of time
        #200; // Run for 200 ns (adjust as needed to observe behavior)

        // End the simulation
        $stop;
    end

    // Monitor output values to the console for debugging
    initial begin
        $monitor("Time = %0dns, address_imem = %h, q_imem = %h", 
                 $time, uut.address_imem, uut.q_imem);
    end

endmodule
