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

    // Define operation codes (unused as we cannot compare using '==')
    // parameter ADD_OPCODE = 5'b00000;
    // parameter SUB_OPCODE = 5'b00001;

    // Control signal for subtraction
    wire is_subtract;

    // Generate 'is_subtract' signal using gates
    // is_subtract = (ctrl_ALUopcode == 5'b00001)
    wire n_ctrl_ALUopcode_4, n_ctrl_ALUopcode_3, n_ctrl_ALUopcode_2, n_ctrl_ALUopcode_1;
    not not4(n_ctrl_ALUopcode_4, ctrl_ALUopcode[4]);
    not not3(n_ctrl_ALUopcode_3, ctrl_ALUopcode[3]);
    not not2(n_ctrl_ALUopcode_2, ctrl_ALUopcode[2]);
    not not1(n_ctrl_ALUopcode_1, ctrl_ALUopcode[1]);
    and is_subtract_gate(is_subtract, n_ctrl_ALUopcode_4, n_ctrl_ALUopcode_3, n_ctrl_ALUopcode_2, n_ctrl_ALUopcode_1, ctrl_ALUopcode[0]);

    // Invert data_operandB
    wire [31:0] data_operandB_inverted;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : invert_B
            not not_gate(data_operandB_inverted[i], data_operandB[i]);
        end
    endgenerate

    // Select correct version of data_operandB
    wire [31:0] operandB_selected;

    generate
        for (i = 0; i < 32; i = i + 1) begin : select_B
            assign operandB_selected[i] = is_subtract ? data_operandB_inverted[i] : data_operandB[i];
        end
    endgenerate

    // Initial carry-in
    wire carry_in;
    assign carry_in = is_subtract;

    // Generate and propagate signals
    wire [31:0] G, P;

    generate
        for (i = 0; i < 32; i = i + 1) begin : generate_G_P
            // Compute G[i] = A[i] AND B[i]
            and and_gate_G(G[i], data_operandA[i], operandB_selected[i]);
            // Compute P[i] = A[i] XOR B[i]
            xor xor_gate_P(P[i], data_operandA[i], operandB_selected[i]);
        end
    endgenerate

    // Implement CLA
    wire [31:0] C; // Internal carries
    wire [7:0] PG, GG; // Block propagate and generate
    wire [7:0] carry_block; // Carries into each block

    assign carry_block[0] = carry_in;

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
                or  or_carry_block(carry_block[i+1], GG[i], temp1);
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

    // Assign result
    assign data_result = sum;

    // Overflow detection
    wire carry_in_MSB, carry_out_MSB;

    assign carry_in_MSB = C[30]; // Carry into bit 31
    assign carry_out_MSB = C[31]; // Carry out from bit 31

    xor xor_overflow(overflow, carry_in_MSB, carry_out_MSB);
endmodule

// Corrected 4-bit CLA block module
module cla_block_4bit(
    input [3:0] G,
    input [3:0] P,
    input Cin,
    output [3:0] Cout,
    output PG,
    output GG
);
    // Internal wires for carry computation
    wire p0c0, p1g0, p1p0c0;
    wire p2g1, p2p1g0, p2p1p0c0;
    wire p3g2, p3p2g1_carry, p3p2p1g0_carry, p3p2p1p0c0;
    wire c1_partial, c2_partial1, c2_partial2;
    wire c3_partial1, c3_partial2, c3_partial3;

    // c[0] = G[0] + (P[0] & Cin)
    and and_p0c0(p0c0, P[0], Cin);
    or  or_c0(Cout[0], G[0], p0c0);

    // c[1] = G[1] + (P[1] & G[0]) + (P[1] & P[0] & Cin)
    and and_p1g0(p1g0, P[1], G[0]);
    and and_p1p0c0(p1p0c0, P[1], P[0], Cin);
    or  or_c1_partial(c1_partial, G[1], p1g0);
    or  or_c1(Cout[1], c1_partial, p1p0c0);

    // c[2] = G[2] + (P[2] & G[1]) + (P[2] & P[1] & G[0]) + (P[2] & P[1] & P[0] & Cin)
    and and_p2g1(p2g1, P[2], G[1]);
    and and_p2p1g0(p2p1g0, P[2], P[1], G[0]);
    and and_p2p1p0c0(p2p1p0c0, P[2], P[1], P[0], Cin);
    or  or_c2_partial1(c2_partial1, G[2], p2g1);
    or  or_c2_partial2(c2_partial2, c2_partial1, p2p1g0);
    or  or_c2(Cout[2], c2_partial2, p2p1p0c0);

    // c[3] = G[3] + (P[3] & G[2]) + (P[3] & P[2] & G[1]) + (P[3] & P[2] & P[1] & G[0]) +
    //        (P[3] & P[2] & P[1] & P[0] & Cin)
    and and_p3g2(p3g2, P[3], G[2]);
    and and_p3p2g1_carry(p3p2g1_carry, P[3], P[2], G[1]);
    and and_p3p2p1g0_carry(p3p2p1g0_carry, P[3], P[2], P[1], G[0]);
    and and_p3p2p1p0c0(p3p2p1p0c0, P[3], P[2], P[1], P[0], Cin);
    or  or_c3_partial1(c3_partial1, G[3], p3g2);
    or  or_c3_partial2(c3_partial2, c3_partial1, p3p2g1_carry);
    or  or_c3_partial3(c3_partial3, c3_partial2, p3p2p1g0_carry);
    or  or_c3(Cout[3], c3_partial3, p3p2p1p0c0);

    // Compute block propagate (PG) and generate (GG)
    wire p_all;
    and and_pg(p_all, P[3], P[2], P[1], P[0]);
    assign PG = p_all;

    // Internal wires for GG computation
    wire temp1_gg, temp2_gg, temp3_gg, temp4_gg, temp5_gg, g_all;

    // Compute GG
    and and_p3p2p1p0c_gg(temp1_gg, P[3], P[2], P[1], P[0], Cin);
    and and_p3p2p1g0_gg(temp2_gg, P[3], P[2], P[1], G[0]);
    and and_p3p2g1_gg(temp3_gg, P[3], P[2], G[1]);
    or  or_gg_partial1(temp4_gg, G[3], temp3_gg);
    or  or_gg_partial2(temp5_gg, temp4_gg, temp2_gg);
    or  or_gg_partial3(g_all, temp5_gg, temp1_gg);
    assign GG = g_all;

endmodule
