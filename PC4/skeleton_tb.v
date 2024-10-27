module processor_tb;

    reg clock;
    reg reset;

    wire imem_clock, dmem_clock, processor_clock, regfile_clock;

    // Processor IO
    wire [11:0] address_imem;
    wire [31:0] q_imem;
    wire [11:0] address_dmem;
    wire [31:0] data;
    wire wren;
    wire [31:0] q_dmem;
    wire ctrl_writeEnable;
    wire [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
    wire [31:0] data_writeReg;
    wire [31:0] data_readRegA, data_readRegB;

    // Instantiate skeleton (top-level module for the processor)
    skeleton uut (
        .clock(clock),
        .reset(reset),
        .imem_clock(imem_clock),
        .dmem_clock(dmem_clock),
        .processor_clock(processor_clock),
        .regfile_clock(regfile_clock)
    );

    // Clock generation (50 MHz clock cycle)
    always #10 clock = ~clock;

    initial begin
        // Initialize signals
        clock = 0;
        reset = 1;

        // Apply reset
        #20 reset = 0;

        // Load instructions into imem (assuming imem.mif handles this in Quartus)
        // Optionally, add instructions directly if not using .mif files:
        // imem_memory[0] = 32'hxxxx_xxxx; // Assembly instruction 1
        // imem_memory[1] = 32'hxxxx_xxxx; // Assembly instruction 2

        // Run the processor for a certain number of cycles
        #100;  // Run the processor for 100 time units

        // Display register values after executing some instructions
        $display("Register values:");
        $display("data_readRegA (rs): %h", data_readRegA);
        $display("data_readRegB (rt): %h", data_readRegB);
        $display("data_writeReg (rd): %h", data_writeReg);
        $display("ctrl_writeReg (Destination Register): %d", ctrl_writeReg);
        $display("Overflow: %b", uut.my_processor.overflow_alu);

        // Add any specific checks or monitors for debugging here if necessary

        // Finish simulation
        #20 $stop;
    end

endmodule
