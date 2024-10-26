module pc (
    input clock,            // Clock signal
    input reset,            // Reset signal
    input [31:0] pc_next,   // 32-bit input for the next PC value
    output [31:0] pc_current // 32-bit output for the current PC value
);

    // Generate 32 D Flip-Flops for each bit of the PC
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : pc_dffe
            dffe my_dffe(
                .d(pc_next[i]),   // Bit i of input PC value (next PC)
                .clk(clock),      // Clock
                .en(1'b1),        // Always enabled
                .clr(reset),      // Reset line
                .q(pc_current[i]) // Bit i of output PC value (current PC)
            );
        end
    endgenerate

endmodule
