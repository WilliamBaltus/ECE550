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
    
    // Control signals
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

            // Compute carry into next block
            if (i < 7) begin : next_carry
                wire temp1;
                and and_pg_cin(temp1, PG[i], carry_block[i]);
                or or_carry_block(carry_block[i+1], GG[i], temp1);
            end
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

    // Implement SLL (Shift Left Logical)
    wire [31:0] sll_stage0, sll_stage1, sll_stage2, sll_stage3, sll_stage4;

    // Stage 0: Shift by 16 bits
    generate
        for (i = 0; i < 32; i = i + 1) begin : sll_shift16
            wire shift_in;
            if (i < 16) begin
                assign shift_in = 1'b0;
            end else begin
                assign shift_in = data_operandA[i - 16];
            end
            mux2to1 mux_sll_stage0(
                .in0(data_operandA[i]),
                .in1(shift_in),
                .sel(ctrl_shiftamt[4]),
                .out(sll_stage0[i])
            );
        end
    endgenerate

    // Stage 1: Shift by 8 bits
    generate
        for (i = 0; i < 32; i = i + 1) begin : sll_shift8
            wire shift_in;
            if (i < 8) begin
                assign shift_in = 1'b0;
            end else begin
                assign shift_in = sll_stage0[i - 8];
            end
            mux2to1 mux_sll_stage1(
                .in0(sll_stage0[i]),
                .in1(shift_in),
                .sel(ctrl_shiftamt[3]),
                .out(sll_stage1[i])
            );
        end
    endgenerate

    // Stage 2: Shift by 4 bits
    generate
        for (i = 0; i < 32; i = i + 1) begin : sll_shift4
            wire shift_in;
            if (i < 4) begin
                assign shift_in = 1'b0;
            end else begin
                assign shift_in = sll_stage1[i - 4];
            end
            mux2to1 mux_sll_stage2(
                .in0(sll_stage1[i]),
                .in1(shift_in),
                .sel(ctrl_shiftamt[2]),
                .out(sll_stage2[i])
            );
        end
    endgenerate

    // Stage 3: Shift by 2 bits
    generate
        for (i = 0; i < 32; i = i + 1) begin : sll_shift2
            wire shift_in;
            if (i < 2) begin
                assign shift_in = 1'b0;
            end else begin
                assign shift_in = sll_stage2[i - 2];
            end
            mux2to1 mux_sll_stage3(
                .in0(sll_stage2[i]),
                .in1(shift_in),
                .sel(ctrl_shiftamt[1]),
                .out(sll_stage3[i])
            );
        end
    endgenerate

    // Stage 4: Shift by 1 bit
    generate
        for (i = 0; i < 32; i = i + 1) begin : sll_shift1
            wire shift_in;
            if (i < 1) begin
                assign shift_in = 1'b0;
            end else begin
                assign shift_in = sll_stage3[i - 1];
            end
            mux2to1 mux_sll_stage4(
                .in0(sll_stage3[i]),
                .in1(shift_in),
                .sel(ctrl_shiftamt[0]),
                .out(sll_stage4[i])
            );
        end
    endgenerate

    // Implement SRA (Shift Right Arithmetic)
    wire [31:0] sra_stage0, sra_stage1, sra_stage2, sra_stage3, sra_stage4;

    // Stage 0: Shift by 16 bits
    generate
        for (i = 31; i >= 0; i = i - 1) begin : sra_shift16
            wire shift_in;
            if (i + 16 > 31) begin
                assign shift_in = data_operandA[31]; // Sign extend
            end else begin
                assign shift_in = data_operandA[i + 16];
            end
            mux2to1 mux_sra_stage0(
                .in0(data_operandA[i]),
                .in1(shift_in),
                .sel(ctrl_shiftamt[4]),
                .out(sra_stage0[i])
            );
        end
    endgenerate

    // Stage 1: Shift by 8 bits
    generate
        for (i = 31; i >= 0; i = i - 1) begin : sra_shift8
            wire shift_in;
            if (i + 8 > 31) begin
                assign shift_in = data_operandA[31];
            end else begin
                assign shift_in = sra_stage0[i + 8];
            end
            mux2to1 mux_sra_stage1(
                .in0(sra_stage0[i]),
                .in1(shift_in),
                .sel(ctrl_shiftamt[3]),
                .out(sra_stage1[i])
            );
        end
    endgenerate

    // Stage 2: Shift by 4 bits
    generate
        for (i = 31; i >= 0; i = i - 1) begin : sra_shift4
            wire shift_in;
            if (i + 4 > 31) begin
                assign shift_in = data_operandA[31];
            end else begin
                assign shift_in = sra_stage1[i + 4];
            end
            mux2to1 mux_sra_stage2(
                .in0(sra_stage1[i]),
                .in1(shift_in),
                .sel(ctrl_shiftamt[2]),
                .out(sra_stage2[i])
            );
        end
    endgenerate

    // Stage 3: Shift by 2 bits
    generate
        for (i = 31; i >= 0; i = i - 1) begin : sra_shift2
            wire shift_in;
            if (i + 2 > 31) begin
                assign shift_in = data_operandA[31];
            end else begin
                assign shift_in = sra_stage2[i + 2];
            end
            mux2to1 mux_sra_stage3(
                .in0(sra_stage2[i]),
                .in1(shift_in),
                .sel(ctrl_shiftamt[1]),
                .out(sra_stage3[i])
            );
        end
    endgenerate

    // Stage 4: Shift by 1 bit
    generate
        for (i = 31; i >= 0; i = i - 1) begin : sra_shift1
            wire shift_in;
            if (i + 1 > 31) begin
                assign shift_in = data_operandA[31];
            end else begin
                assign shift_in = sra_stage3[i + 1];
            end
            mux2to1 mux_sra_stage4(
                .in0(sra_stage3[i]),
                .in1(shift_in),
                .sel(ctrl_shiftamt[0]),
                .out(sra_stage4[i])
            );
        end
    endgenerate

    // Select data_result
    generate
        for (i = 0; i < 32; i = i + 1) begin : generate_data_result
            wire sum_result_bit, and_result_bit, or_result_bit, sll_result_bit, sra_result_bit;
            and and_sum_result(sum_result_bit, sum[i], is_add_or_subtract);
            and and_and_result(and_result_bit, and_result[i], is_and_op);
            and and_or_result(or_result_bit, or_result[i], is_or_op);
            and and_sll_result(sll_result_bit, sll_stage4[i], is_sll);
            and and_sra_result(sra_result_bit, sra_stage4[i], is_sra);
            or or_data_result(data_result[i], sum_result_bit, and_result_bit, or_result_bit, sll_result_bit, sra_result_bit);
        end
    endgenerate

    // Compute isNotEqual and isLessThan
    // Compute isNotEqual
    wire is_subtract_only;
    and and_is_subtract_only(is_subtract_only, is_subtract, 1'b1);

    // Compute if sum is zero
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
    input [3:0] G,
    input [3:0] P,
    input Cin,
    output [3:0] Cout,
    output PG,
    output GG
);

    wire p0c0, p1g0, p1p0c0;
    wire p2g1, p2p1g0, p2p1p0c0;
    wire p3g2, p3p2g1, p3p2p1g0, p3p2p1p0c0;
    wire c1_partial, c2_partial1, c2_partial2;
    wire c3_partial1, c3_partial2, c3_partial3;

    // c[0] = G[0] + (P[0] & Cin)
    and and_p0c0(p0c0, P[0], Cin);
    or or_c0(Cout[0], G[0], p0c0);

    // c[1] = G[1] + (P[1] & G[0]) + (P[1] & P[0] & Cin)
    and and_p1g0(p1g0, P[1], G[0]);
    and and_p1p0c0(p1p0c0, P[1], P[0], Cin);
    or or_c1_partial(c1_partial, G[1], p1g0);
    or or_c1(Cout[1], c1_partial, p1p0c0);

    // c[2] = G[2] + (P[2] & G[1]) + (P[2] & P[1] & G[0]) + (P[2] & P[1] & P[0] & Cin)
    and and_p2g1(p2g1, P[2], G[1]);
    and and_p2p1g0(p2p1g0, P[2], P[1], G[0]);
    and and_p2p1p0c0(p2p1p0c0, P[2], P[1], P[0], Cin);
    or or_c2_partial1(c2_partial1, G[2], p2g1);
    or or_c2_partial2(c2_partial2, c2_partial1, p2p1g0);
    or or_c2(Cout[2], c2_partial2, p2p1p0c0);

    // c[3] = G[3] + (P[3] & G[2]) + (P[3] & P[2] & G[1]) + (P[3] & P[2] & P[1] & G[0]) +
    //        (P[3] & P[2] & P[1] & P[0] & Cin)
    and and_p3g2(p3g2, P[3], G[2]);
    and and_p3p2g1(p3p2g1, P[3], P[2], G[1]);
    and and_p3p2p1g0(p3p2p1g0, P[3], P[2], P[1], G[0]);
    and and_p3p2p1p0c0(p3p2p1p0c0, P[3], P[2], P[1], P[0], Cin);
    or or_c3_partial1(c3_partial1, G[3], p3g2);
    or or_c3_partial2(c3_partial2, c3_partial1, p3p2g1);
    or or_c3_partial3(c3_partial3, c3_partial2, p3p2p1g0);
    or or_c3(Cout[3], c3_partial3, p3p2p1p0c0);

    // Compute block propagate (PG) and generate (GG)
    and and_pg(PG, P[3], P[2], P[1], P[0]);

    // GG = G[3] + (P[3] & G[2]) + (P[3] & P[2] & G[1]) + (P[3] & P[2] & P[1] & G[0])
    wire gg_p3g2, gg_p3p2g1, gg_p3p2p1g0;
    and and_gg_p3g2(gg_p3g2, P[3], G[2]);
    and and_gg_p3p2g1(gg_p3p2g1, P[3], P[2], G[1]);
    and and_gg_p3p2p1g0(gg_p3p2p1g0, P[3], P[2], P[1], G[0]);
    or or_gg(GG, G[3], gg_p3g2, gg_p3p2g1, gg_p3p2p1g0);

endmodule

// 2:1 Multiplexer Module
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
