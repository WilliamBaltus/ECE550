module pc (
    input clock,            // Clock signal
    input reset,            // Reset signal
    input [31:0] pc_current,   // 32-bit input for the next PC value
    output [31:0] pc_next // 32-bit output for the current PC value
);

	 assign pc_input = reset ? 32'b0 : pc_next;

    // Generate 32 D Flip-Flops for each bit of the PC
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : pc_dffe
            dffe my_dffe(
					 pc_next[i], // Bit i of output PC value (current PC)
                pc_current[i],   // Bit i of input PC value (next PC)
                clock,      // Clock
                1'b1,        // Always enabled
                reset      // Reset line
                
            );
        end
    endgenerate

endmodule
