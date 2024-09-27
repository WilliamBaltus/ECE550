// ALU Module
module alu(
    data_operandA,
    data_operandB,
    ctrl_ALUopcode,
    ctrl_shiftamt,
    data_result,
    isNotEqual,
    isLessThan,
    overflow
);
    input [31:0] data_operandA, data_operandB;
    input [4:0] ctrl_ALUopcode, ctrl_shiftamt;
    output [31:0] data_result;
    output isNotEqual, isLessThan, overflow;

    // Declare wires for control signals
    wire is_add, is_subtract, is_and_op, is_or_op, is_sll, is_sra, is_add_or_subtract;

    // Invert ctrl_ALUopcode bits
    wire n_ctrl_ALUopcode_4, n_ctrl_ALUopcode_3, n_ctrl_ALUopcode_2, n_ctrl_ALUopcode_1, n_ctrl_ALUopcode_0;
    not not4(n_ctrl_ALUopcode_4, ctrl_ALUopcode[4]);
    not not3(n_ctrl_ALUopcode_3, ctrl_ALUopcode[3]);
    not not2(n_ctrl_ALUopcode_2, ctrl_ALUopcode[2]);
    not not1(n_ctrl_ALUopcode_1, ctrl_ALUopcode[1]);
    not not0(n_ctrl_ALUopcode_0, ctrl_ALUopcode[0]);

    // Generate control signals
    // is_add = 00000
    and is_add_gate(is_add, n_ctrl_ALUopcode_4, n_ctrl_ALUopcode_3, n_ctrl_ALUopcode_2, n_ctrl_ALUopcode_1, n_ctrl_ALUopcode_0);
    // is_subtract = 00001
    and is_subtract_gate(is_subtract, n_ctrl_ALUopcode_4, n_ctrl_ALUopcode_3, n_ctrl_ALUopcode_2, n_ctrl_ALUopcode_1, ctrl_ALUopcode[0]);
    // is_and_op = 00010
    and is_and_gate(is_and_op, n_ctrl_ALUopcode_4, n_ctrl_ALUopcode_3, n_ctrl_ALUopcode_2, ctrl_ALUopcode[1], n_ctrl_ALUopcode_0);
    // is_or_op = 00011
    and is_or_gate(is_or_op, n_ctrl_ALUopcode_4, n_ctrl_ALUopcode_3, n_ctrl_ALUopcode_2, ctrl_ALUopcode[1], ctrl_ALUopcode[0]);
    // is_sll = 00100
    and is_sll_gate(is_sll, n_ctrl_ALUopcode_4, n_ctrl_ALUopcode_3, ctrl_ALUopcode[2], n_ctrl_ALUopcode_1, n_ctrl_ALUopcode_0);
    // is_sra = 00101
    and is_sra_gate(is_sra, n_ctrl_ALUopcode_4, n_ctrl_ALUopcode_3, ctrl_ALUopcode[2], n_ctrl_ALUopcode_1, ctrl_ALUopcode[0]);
    // is_add_or_subtract
    or is_add_or_subtract_gate(is_add_or_subtract, is_add, is_subtract);

    // ADD/SUBTRACT operations

    // Invert data_operandB if subtracting
    wire [31:0] data_operandB_inverted;
    wire [31:0] operandB_selected;

    // Generate inversion of data_operandB and select operandB
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : invert_and_select_B
            not not_b_inv(data_operandB_inverted[i], data_operandB[i]);
            // Use MUX to select between data_operandB and data_operandB_inverted
            mux2to1 mux_operandB(
                .in0(data_operandB[i]),
                .in1(data_operandB_inverted[i]),
                .sel(is_subtract),
                .out(operandB_selected[i])
            );
        end
    endgenerate

    // Initial carry-in connected via gates
    wire carry_in;
    // carry_in = is_subtract;
    and and_carry_in(carry_in, is_subtract, 1'b1);

    // Generate G and P signals
    wire [31:0] G, P;

    generate
        for (i = 0; i < 32; i = i + 1) begin : generate_G_P
            // Compute G[i] = A[i] AND B[i]
            and and_gate_G(G[i], data_operandA[i], operandB_selected[i]);
            // Compute P[i] = A[i] XOR B[i]
            xor xor_gate_P(P[i], data_operandA[i], operandB_selected[i]);
        end
    endgenerate

    // Implement CLA using 4-bit CLA blocks
    wire [31:0] C; // Internal carries
    wire [7:0] PG, GG; // Block propagate and generate
    wire [7:0] carry_block; // Carries into each block

    // carry_block[0] connected via gates
    // carry_block[0] = carry_in;
    and and_carry_block0(carry_block[0], carry_in, 1'b1);

    // Generate CLA blocks
    generate
        for (i = 0; i < 8; i = i + 1) begin : cla_blocks
            // Instantiate 4-bit CLA block
            cla_block_4bit cla_block_inst(
                .G(G[i*4 + 3 : i*4]),
                .P(P[i*4 + 3 : i*4]),
                .Cin(carry_block[i]),
                .Cout(C[i*4 + 3 : i*4]),
                .PG(PG[i]),
                .GG(GG[i])
            );
        end
    endgenerate

    // Compute carry into next block for i = 0 to 6
    generate
        for (i = 0; i < 7; i = i + 1) begin : compute_carry
            wire temp1;
            and and_pg_cin(temp1, PG[i], carry_block[i]);
            or or_carry_block(carry_block[i+1], GG[i], temp1);
        end
    endgenerate

    // Compute sum bits
    wire [31:0] sum;

    // Compute sum[0] separately
    xor xor_sum0(sum[0], P[0], carry_in);

    // Compute sum[1] to sum[31]
    generate
        for (i = 1; i < 32; i = i + 1) begin : compute_sum
            xor xor_sum(sum[i], P[i], C[i - 1]);
        end
    endgenerate

    // Bitwise AND
    wire [31:0] and_result;
    generate
        for (i = 0; i < 32; i = i + 1) begin : generate_and
            and and_gate(and_result[i], data_operandA[i], data_operandB[i]);
        end
    endgenerate

    // Bitwise OR
    wire [31:0] or_result;
    generate
        for (i = 0; i < 32; i = i + 1) begin : generate_or
            or or_gate(or_result[i], data_operandA[i], data_operandB[i]);
        end
    endgenerate

    // Instantiate SLL and SRA modules
    wire [31:0] sll_result, sra_result;

    SLL sll_inst(
        .a(data_operandA),
        .ctrl_shiftamt(ctrl_shiftamt),
        .out(sll_result)
    );

    SRA sra_inst(
        .a(data_operandA),
        .ctrl_shiftamt(ctrl_shiftamt),
        .out(sra_result)
    );

    // Select data_result
    generate
        for (i = 0; i < 32; i = i + 1) begin : generate_data_result
            wire sum_result_bit, and_result_bit, or_result_bit, sll_result_bit, sra_result_bit;
            and and_sum_result(sum_result_bit, sum[i], is_add_or_subtract);
            and and_and_result(and_result_bit, and_result[i], is_and_op);
            and and_or_result(or_result_bit, or_result[i], is_or_op);
            and and_sll_result(sll_result_bit, sll_result[i], is_sll);
            and and_sra_result(sra_result_bit, sra_result[i], is_sra);
            or or_data_result(data_result[i], sum_result_bit, and_result_bit, or_result_bit, sll_result_bit, sra_result_bit);
        end
    endgenerate

    // Compute isNotEqual and isLessThan
    // Compute isNotEqual
    wire is_subtract_only;
    and and_is_subtract_only(is_subtract_only, is_subtract, 1'b1);

    // Compute sum_not_zero
    wire sum_not_zero;
    wire [31:0] sum_inverted;
    generate
        for (i = 0; i < 32; i = i + 1) begin : invert_sum_for_zero_check
            not not_sum_inverted(sum_inverted[i], sum[i]);
        end
    endgenerate

    wire all_zeros;
    and and_all_zeros(all_zeros, sum_inverted[0], sum_inverted[1], sum_inverted[2], sum_inverted[3],
                      sum_inverted[4], sum_inverted[5], sum_inverted[6], sum_inverted[7],
                      sum_inverted[8], sum_inverted[9], sum_inverted[10], sum_inverted[11],
                      sum_inverted[12], sum_inverted[13], sum_inverted[14], sum_inverted[15],
                      sum_inverted[16], sum_inverted[17], sum_inverted[18], sum_inverted[19],
                      sum_inverted[20], sum_inverted[21], sum_inverted[22], sum_inverted[23],
                      sum_inverted[24], sum_inverted[25], sum_inverted[26], sum_inverted[27],
                      sum_inverted[28], sum_inverted[29], sum_inverted[30], sum_inverted[31]);

    not not_sum_not_zero(sum_not_zero, all_zeros);
    and and_isNotEqual(isNotEqual, sum_not_zero, is_subtract_only);

    // Compute isLessThan
    // sum_sign = sum[31] XOR overflow
    wire sum_sign;
    xor xor_sum_sign(sum_sign, sum[31], overflow);

    and and_isLessThan(isLessThan, sum_sign, is_subtract_only);

    // Overflow detection
    wire carry_in_MSB, carry_out_MSB;
    // carry_in_MSB = C[30];
    and and_carry_in_MSB(carry_in_MSB, C[30], 1'b1);

    // carry_out_MSB = C[31];
    and and_carry_out_MSB(carry_out_MSB, C[31], 1'b1);

    wire overflow_internal;
    xor xor_overflow_internal(overflow_internal, carry_in_MSB, carry_out_MSB);
    // Assign overflow only during ADD or SUBTRACT
    and and_overflow(overflow, overflow_internal, is_add_or_subtract);

endmodule


// 4-bit CLA Block Module
module cla_block_4bit(
    input [3:0] G,     // Generate signals for each bit
    input [3:0] P,     // Propagate signals for each bit
    input Cin,         // Carry-in for the block
    output [3:0] Cout, // Carry-out signals for each bit
    output PG,         // Block propagate
    output GG          // Block generate
);

    // Internal wires for carry computation
    wire c1_intermediate;
    wire c2_intermediate1, c2_intermediate2;
    wire c3_intermediate1, c3_intermediate2, c3_intermediate3;

    // Compute carries using carry-lookahead logic
    // Cout[0] = G[0] + (P[0] & Cin)
    wire p0c0;
    and and_p0c0(p0c0, P[0], Cin);
    or or_cout0(Cout[0], G[0], p0c0);

    // Cout[1] = G[1] + (P[1] & G[0]) + (P[1] & P[0] & Cin)
    wire p1g0, p1p0c0;
    and and_p1g0(p1g0, P[1], G[0]);
    and and_p1p0c0(p1p0c0, P[1], P[0], Cin);
    or or_c1_intermediate(c1_intermediate, G[1], p1g0);
    or or_cout1(Cout[1], c1_intermediate, p1p0c0);

    // Cout[2] = G[2] + (P[2] & G[1]) + (P[2] & P[1] & G[0]) + (P[2] & P[1] & P[0] & Cin)
    wire p2g1, p2p1g0, p2p1p0c0;
    and and_p2g1(p2g1, P[2], G[1]);
    and and_p2p1g0(p2p1g0, P[2], P[1], G[0]);
    and and_p2p1p0c0(p2p1p0c0, P[2], P[1], P[0], Cin);
    or or_c2_intermediate1(c2_intermediate1, G[2], p2g1);
    or or_c2_intermediate2(c2_intermediate2, c2_intermediate1, p2p1g0);
    or or_cout2(Cout[2], c2_intermediate2, p2p1p0c0);

    // Cout[3] = G[3] + (P[3] & G[2]) + (P[3] & P[2] & G[1]) +
    //           (P[3] & P[2] & P[1] & G[0]) + (P[3] & P[2] & P[1] & P[0] & Cin)
    wire p3g2, p3p2g1, p3p2p1g0, p3p2p1p0c0;
    and and_p3g2(p3g2, P[3], G[2]);
    and and_p3p2g1(p3p2g1, P[3], P[2], G[1]);
    and and_p3p2p1g0(p3p2p1g0, P[3], P[2], P[1], G[0]);
    and and_p3p2p1p0c0(p3p2p1p0c0, P[3], P[2], P[1], P[0], Cin);
    or or_c3_intermediate1(c3_intermediate1, G[3], p3g2);
    or or_c3_intermediate2(c3_intermediate2, c3_intermediate1, p3p2g1);
    or or_c3_intermediate3(c3_intermediate3, c3_intermediate2, p3p2p1g0);
    or or_cout3(Cout[3], c3_intermediate3, p3p2p1p0c0);

    // Compute block propagate (PG) and block generate (GG)
    // PG = P[3] & P[2] & P[1] & P[0]
    and and_pg(PG, P[3], P[2], P[1], P[0]);

    // GG = G[3] + (P[3] & G[2]) + (P[3] & P[2] & G[1]) +
    //      (P[3] & P[2] & P[1] & G[0])
    wire p3g2_for_gg, p3p2g1_for_gg, p3p2p1g0_for_gg;
    and and_p3g2_for_gg(p3g2_for_gg, P[3], G[2]);
    and and_p3p2g1_for_gg(p3p2g1_for_gg, P[3], P[2], G[1]);
    and and_p3p2p1g0_for_gg(p3p2p1g0_for_gg, P[3], P[2], P[1], G[0]);
    or or_gg_intermediate(GG, G[3], p3g2_for_gg, p3p2g1_for_gg, p3p2p1g0_for_gg);

endmodule


// 2:1 Multiplexer Module (Same as before)
module mux2to1(
    input in0,
    input in1,
    input sel,
    output out
);
    wire nsel, a0, a1;
    not not_sel(nsel, sel);
    and and0(a0, in0, nsel);
    and and1(a1, in1, sel);
    or or_out(out, a0, a1);
endmodule

// SLL Module
module SLL(a, ctrl_shiftamt, out);
    // Logical Left Shift
    input [31:0] a;
    input [4:0] ctrl_shiftamt;
    output [31:0] out;

    wire [31:0] stage0, stage1, stage2, stage3;

    // Stage 0: shift by 1 bit
    assign stage0[0] = ctrl_shiftamt[0] ? 1'b0 : a[0];
    assign stage0[31:1] = ctrl_shiftamt[0] ? a[30:0] : a[31:1];

    // Stage 1: shift by 2 bits
    assign stage1[1:0] = ctrl_shiftamt[1] ? 2'b00 : stage0[1:0];
    assign stage1[31:2] = ctrl_shiftamt[1] ? stage0[29:0] : stage0[31:2];

    // Stage 2: shift by 4 bits
    assign stage2[3:0] = ctrl_shiftamt[2] ? 4'b0000 : stage1[3:0];
    assign stage2[31:4] = ctrl_shiftamt[2] ? stage1[27:0] : stage1[31:4];

    // Stage 3: shift by 8 bits
    assign stage3[7:0] = ctrl_shiftamt[3] ? 8'b00000000 : stage2[7:0];
    assign stage3[31:8] = ctrl_shiftamt[3] ? stage2[23:0] : stage2[31:8];

    // Stage 4: shift by 16 bits
    assign out[15:0] = ctrl_shiftamt[4] ? 16'b0000000000000000 : stage3[15:0];
    assign out[31:16] = ctrl_shiftamt[4] ? stage3[15:0] : stage3[31:16];

endmodule

// SRA Module
module SRA(a, ctrl_shiftamt, out);
    // Arithmetic Right Shift
    input [31:0] a;
    input [4:0] ctrl_shiftamt;
    output [31:0] out;

    wire [31:0] stage0, stage1, stage2, stage3;

    // Stage 0: shift by 1 bit
    assign stage0[31] = a[31];
    assign stage0[30:0] = ctrl_shiftamt[0] ? a[31:1] : a[30:0];

    // Stage 1: shift by 2 bits
    generate
        genvar i;
        for (i = 31; i > 29; i = i - 1) begin : sra_stage1_gen
            assign stage1[i] = ctrl_shiftamt[1] ? stage0[31] : stage0[i];
        end
    endgenerate
    assign stage1[29:0] = ctrl_shiftamt[1] ? stage0[31:2] : stage0[29:0];

    // Stage 2: shift by 4 bits
    generate
        for (i = 31; i > 27; i = i - 1) begin : sra_stage2_gen
            assign stage2[i] = ctrl_shiftamt[2] ? stage1[31] : stage1[i];
        end
    endgenerate
    assign stage2[27:0] = ctrl_shiftamt[2] ? stage1[31:4] : stage1[27:0];

    // Stage 3: shift by 8 bits
    generate
        for (i = 31; i > 23; i = i - 1) begin : sra_stage3_gen
            assign stage3[i] = ctrl_shiftamt[3] ? stage2[31] : stage2[i];
        end
    endgenerate
    assign stage3[23:0] = ctrl_shiftamt[3] ? stage2[31:8] : stage2[23:0];

    // Stage 4: shift by 16 bits
    generate
        for (i = 31; i > 15; i = i - 1) begin : sra_stage4_gen
            assign out[i] = ctrl_shiftamt[4] ? stage3[31] : stage3[i];
        end
    endgenerate
    assign out[15:0] = ctrl_shiftamt[4] ? stage3[31:16] : stage3[15:0];

endmodule
