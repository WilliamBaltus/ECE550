module regfile (
    clock,
    ctrl_writeEnable,
    ctrl_reset, ctrl_writeReg,
    ctrl_readRegA, ctrl_readRegB, data_writeReg,
    data_readRegA, data_readRegB
);
   input clock, ctrl_writeEnable, ctrl_reset;
   input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
   input [31:0] data_writeReg;

   output [31:0] data_readRegA, data_readRegB;

   // Wires for register outputs
   wire [31:0] reg_out0;           // Output of register 0
   wire [31:0] reg_out[31:1];      // Outputs of registers 1 to 31

   // Wires for write enables
   wire [31:0] write_enable;

   // Wires for read select one-hot encoding
   wire [31:0] sel_onehotA;
   wire [31:0] sel_onehotB;

   // Create a wire that is always zero
   wire zero;
   wire dummy_signal;
   not not_dummy(dummy_signal, dummy_signal); // dummy_signal toggles
   and and_zero(zero, dummy_signal, dummy_signal); // zero is always 0

   // Write enable for register 0 is always 0
   // Using an AND gate to ensure write_enable[0] is always zero
   and and_write_enable0(write_enable[0], zero, zero);

   // Generate write enables for registers 1 to 31
   genvar i_we;
   generate
       for (i_we = 1; i_we < 32; i_we = i_we + 1) begin : gen_write_enable
           wire eq_write;
           comparator5bit #(.CONST_VAL(i_we)) comp_write(
               .in(ctrl_writeReg),
               .eq(eq_write)
           );
           // Use AND gate to generate write enable
           and and_write_enable(write_enable[i_we], ctrl_writeEnable, eq_write);
       end
   endgenerate

   // Instantiate register 0 separately
   zero_register reg_zero(
       .data_out(reg_out0),
       .clk(clock),
       .clr(ctrl_reset)
   );

   // Instantiate registers 1 to 31
   genvar i_reg;
   generate
       for (i_reg = 1; i_reg < 32; i_reg = i_reg + 1) begin : gen_registers
           register32 reg_inst(
               .data_in(data_writeReg),
               .data_out(reg_out[i_reg]),
               .clk(clock),
               .en(write_enable[i_reg]),
               .clr(ctrl_reset)
           );
       end
   endgenerate

   // Generate one-hot select lines for read port A
   genvar i_selA;
   generate
       for (i_selA = 0; i_selA < 32; i_selA = i_selA + 1) begin : gen_sel_onehotA
           comparator5bit #(.CONST_VAL(i_selA)) comp_selA(
               .in(ctrl_readRegA),
               .eq(sel_onehotA[i_selA])
           );
       end
   endgenerate

   // Generate one-hot select lines for read port B
   genvar i_selB;
   generate
       for (i_selB = 0; i_selB < 32; i_selB = i_selB + 1) begin : gen_sel_onehotB
           comparator5bit #(.CONST_VAL(i_selB)) comp_selB(
               .in(ctrl_readRegB),
               .eq(sel_onehotB[i_selB])
           );
       end
   endgenerate

   // Build data_readRegA using multiplexers
   genvar bit_idxA, reg_idxA;
   generate
       for (bit_idxA = 0; bit_idxA < 32; bit_idxA = bit_idxA + 1) begin : gen_bitsA
           wire [31:0] and_outA;
           // For register 0
           and and_gateA0(and_outA[0], reg_out0[bit_idxA], sel_onehotA[0]);
           // For registers 1 to 31
           for (reg_idxA = 1; reg_idxA < 32; reg_idxA = reg_idxA + 1) begin : gen_regsA
               and and_gateA(and_outA[reg_idxA], reg_out[reg_idxA][bit_idxA], sel_onehotA[reg_idxA]);
           end
           // OR the outputs
           or32 or_gateA(
               .in(and_outA),
               .out(data_readRegA[bit_idxA])
           );
       end
   endgenerate

   // Build data_readRegB using multiplexers
   genvar bit_idxB, reg_idxB;
   generate
       for (bit_idxB = 0; bit_idxB < 32; bit_idxB = bit_idxB + 1) begin : gen_bitsB
           wire [31:0] and_outB;
           // For register 0
           and and_gateB0(and_outB[0], reg_out0[bit_idxB], sel_onehotB[0]);
           // For registers 1 to 31
           for (reg_idxB = 1; reg_idxB < 32; reg_idxB = reg_idxB + 1) begin : gen_regsB
               and and_gateB(and_outB[reg_idxB], reg_out[reg_idxB][bit_idxB], sel_onehotB[reg_idxB]);
           end
           // OR the outputs
           or32 or_gateB(
               .in(and_outB),
               .out(data_readRegB[bit_idxB])
           );
       end
   endgenerate

endmodule

// Zero register module
module zero_register(data_out, clk, clr);
    input clk, clr;
    output [31:0] data_out;

    // Data_out is always zero
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_zero_bits
            wire zero_bit;
            and and_zero_bit(zero_bit, 1'b0, 1'b0); // zero_bit is 0
            buf buf_zero(data_out[i], zero_bit);
        end
    endgenerate
endmodule

// Module for 32-bit register using DFFEs
module register32(data_in, data_out, clk, en, clr);
    input [31:0] data_in;
    input clk, en, clr;
    output [31:0] data_out;

    genvar j;
    generate
        for (j = 0; j < 32; j = j + 1) begin : gen_dffe
            dffe_ref dff_inst(
                .q(data_out[j]),
                .d(data_in[j]),
                .clk(clk),
                .en(en),
                .clr(clr)
            );
        end
    endgenerate
endmodule

// 5-bit Comparator Module
module comparator5bit(in, eq);
    parameter [4:0] CONST_VAL = 5'b00000;
    input [4:0] in;
    output eq;

    wire [4:0] xnor_out;

    // XNOR each bit
    xnor xnor0(xnor_out[0], in[0], CONST_VAL[0]);
    xnor xnor1(xnor_out[1], in[1], CONST_VAL[1]);
    xnor xnor2(xnor_out[2], in[2], CONST_VAL[2]);
    xnor xnor3(xnor_out[3], in[3], CONST_VAL[3]);
    xnor xnor4(xnor_out[4], in[4], CONST_VAL[4]);

    // AND all bits together
    and and_eq(eq, xnor_out[0], xnor_out[1], xnor_out[2], xnor_out[3], xnor_out[4]);
endmodule

// 32-input OR gate
module or32(in, out);
    input [31:0] in;
    output out;

    wire [15:0] or_stage1;
    wire [7:0] or_stage2;
    wire [3:0] or_stage3;
    wire [1:0] or_stage4;

    // Stage 1
    or or0(or_stage1[0], in[0], in[1]);
    or or1(or_stage1[1], in[2], in[3]);
    or or2(or_stage1[2], in[4], in[5]);
    or or3(or_stage1[3], in[6], in[7]);
    or or4(or_stage1[4], in[8], in[9]);
    or or5(or_stage1[5], in[10], in[11]);
    or or6(or_stage1[6], in[12], in[13]);
    or or7(or_stage1[7], in[14], in[15]);
    or or8(or_stage1[8], in[16], in[17]);
    or or9(or_stage1[9], in[18], in[19]);
    or or10(or_stage1[10], in[20], in[21]);
    or or11(or_stage1[11], in[22], in[23]);
    or or12(or_stage1[12], in[24], in[25]);
    or or13(or_stage1[13], in[26], in[27]);
    or or14(or_stage1[14], in[28], in[29]);
    or or15(or_stage1[15], in[30], in[31]);

    // Stage 2
    or or16(or_stage2[0], or_stage1[0], or_stage1[1]);
    or or17(or_stage2[1], or_stage1[2], or_stage1[3]);
    or or18(or_stage2[2], or_stage1[4], or_stage1[5]);
    or or19(or_stage2[3], or_stage1[6], or_stage1[7]);
    or or20(or_stage2[4], or_stage1[8], or_stage1[9]);
    or or21(or_stage2[5], or_stage1[10], or_stage1[11]);
    or or22(or_stage2[6], or_stage1[12], or_stage1[13]);
    or or23(or_stage2[7], or_stage1[14], or_stage1[15]);

    // Stage 3
    or or24(or_stage3[0], or_stage2[0], or_stage2[1]);
    or or25(or_stage3[1], or_stage2[2], or_stage2[3]);
    or or26(or_stage3[2], or_stage2[4], or_stage2[5]);
    or or27(or_stage3[3], or_stage2[6], or_stage2[7]);

    // Stage 4
    or or28(or_stage4[0], or_stage3[0], or_stage3[1]);
    or or29(or_stage4[1], or_stage3[2], or_stage3[3]);

    // Stage 5
    or or30(out, or_stage4[0], or_stage4[1]);
endmodule
