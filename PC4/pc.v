module pc(
    input clock,               // Clock signal
    input reset,               // Reset signal
    input [31:0] pc_next,      // 32-bit input for the next PC value
    output [31:0] pc_current   // 32-bit output for the current PC value
);

    // Generate 32 D Flip-Flops for each bit of the PC
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : pc_bit
            dffe_ref my_dffe (
                .q(pc_current[i]),   // Connect q to each bit of pc_current
                .d(pc_next[i]),      // Connect d to each bit of pc_next
                .clk(clock),         // Clock signal
                .en(1'b1),           // Enable is always 1
                .clr(reset)          // Reset signal
            );
        end
    endgenerate

endmodule
