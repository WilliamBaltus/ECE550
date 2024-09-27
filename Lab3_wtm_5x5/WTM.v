//module WTM(in1, in2, cout, product);
//    input [4:0] in1, in2;
//    output [9:0] product;
//	 output cout;
//    genvar a, b;
//    wire [24:0] partial;
//    wire [12:0] sum;
//    wire [12:0] fa_cout;
//    wire [7:0] carry_final;
//
//    // Generate all 25 partial products
//    generate
//        for(b = 0; b < 5; b = b + 1) begin : gen1
//            for(a = 0; a < 5; a = a + 1) begin : gen2
//                and(partial[b*5 + a], in1[a], in2[b]);
//            end
//        end
//    endgenerate
//
//    // First Reduction Stage
//    full_adder fa0(partial[2], partial[6], partial[10], fa_cout[0], sum[0]);
//    full_adder fa1(partial[3], partial[7], partial[11], fa_cout[1], sum[1]);
//    full_adder fa2(partial[4], partial[8], partial[12], fa_cout[2], sum[2]);
//    full_adder fa3(partial[16], partial[20], fa_cout[2], fa_cout[3], sum[3]); // Using carry from fa2
//    full_adder fa4(partial[9], partial[13], partial[17], fa_cout[4], sum[4]);
//    full_adder fa5(partial[14], partial[18], partial[22], fa_cout[5], sum[5]);
//
//    // Second Reduction Stage
//    full_adder fa6(sum[1], partial[15], fa_cout[0], fa_cout[6], sum[6]);
//    full_adder fa7(sum[2], sum[3], fa_cout[1], fa_cout[7], sum[7]);
//    full_adder fa8(sum[4], partial[21], fa_cout[3], fa_cout[8], sum[8]);
//    full_adder fa9(sum[5], fa_cout[4], fa_cout[8], fa_cout[9], sum[9]);
//    full_adder fa10(fa_cout[2], fa_cout[6], fa_cout[7], fa_cout[10], sum[10]);
//
//    // Third Reduction Stage
//    full_adder fa11(sum[8], fa_cout[5], fa_cout[9], fa_cout[11], sum[11]);
//    full_adder fa12(sum[7], sum[10], fa_cout[10], fa_cout[12], sum[12]);
//
//    // Final Addition
//    assign product[0] = partial[0];
//
//    // Column 1
//    full_adder fa_final0(partial[1], partial[5], 1'b0, carry_final[0], product[1]);
//
//    // Column 2
//    full_adder fa_final1(sum[0], fa_cout[6], carry_final[0], carry_final[1], product[2]);
//
//    // Column 3
//    full_adder fa_final2(sum[6], fa_cout[12], carry_final[1], carry_final[2], product[3]);
//
//    // Column 4
//    full_adder fa_final3(sum[12], fa_cout[11], carry_final[2], carry_final[3], product[4]);
//
//    // Column 5
//    full_adder fa_final4(sum[11], fa_cout[9], carry_final[3], carry_final[4], product[5]);
//
//    // Column 6
//    full_adder fa_final5(sum[9], partial[23], carry_final[4], carry_final[5], product[6]);
//
//    // Column 7
//    full_adder fa_final6(partial[19], fa_cout[5], carry_final[5], carry_final[6], product[7]);
//
//    // Column 8
//    full_adder fa_final7(partial[24], carry_final[6], 1'b0, carry_final[7], product[8]);
//
//    // Column 9
//    assign product[9] = carry_final[7];
//	 assign cout = 1'b0;
//
//endmodule









module WTM(a, b, cout, out);

	 input [4:0] a, b;

	 output [9:0] out;

	 output cout;

	

	 wire [4:0] a0, a1, a2, a3, a4;

	 wire [25:0] s;

	 wire [25:0] c;

	 wire cstar;

	

	 genvar i;

	

	 generate

		for (i = 0; i < 5; i = i + 1) begin : gen_loop

						  and tmp_a0(a0[i], a[i], b[0]);

						  and tmp_a1(a1[i], a[i], b[1]);

						  and tmp_a2(a2[i], a[i], b[2]);

						  and tmp_a3(a3[i], a[i], b[3]);

						  and tmp_a4(a4[i], a[i], b[4]);

		end

	 endgenerate

	

	 assign out[0] = a0[0];

	

	 // Stage 1

	 full_adder blah(a0[1], a1[0], 0, out[1], c[1]); // out[1], c1

	 full_adder blah1(a0[2], a1[1], a2[0], s[2], c[2]); // s2, c2

	 full_adder blah2(a0[3], a1[2], a2[1], s[3], c[3]); // s3, c3

	 full_adder blah3(a0[4], a1[3], a2[2], s[4], c[4]); // s4, c4

	 full_adder blah4(a1[4], a2[3], a3[2], s[5], c[5]); // s5, c5

	 full_adder blah5(a2[4], a3[3], a4[2], s[6], c[6]); // s6, c6

	 full_adder blah6(a3[4], a4[3], c[6], s[7], c[7]); // s7, c7

	 full_adder blah7(a4[4], c[7], 0, s[8], cstar); // s8, c8

	

	 // Stage 2

	 full_adder blah8(s[2], c[1], 0, out[2], c[8]); // out[2], c8

	 full_adder blah9(s[3], a1[1], a3[0], s[9], c[9]); // s9, c9

	 full_adder blah10(s[4], a3[1], a4[0], s[10], c[10]); // s10, c10

	 full_adder blah11(s[5], a4[1], c[4], s[11], c[11]); // s11, c11

	 full_adder blah12(s[6], c[5], c[11], s[12], c[12]); // s12, c12

	 full_adder blah13(s[7], c[12], 0, s[13], c[13]); // s13, c13

	

	 // Stage 3

	 full_adder blah14(s[9], c[8], 0, out[3], c[14]); // out[3], c14

	 full_adder blah15(s[10], c[3], c[9], s[15], c[15]); // s15, c15

	 full_adder blah16(s[11], c[10], c[15], s[16], c[16]); // s16, c16

	 full_adder blah17(s[12], c[16], 0, s[17], c[17]); // s17, c17

	 full_adder blah88(s[13], c[17], 0, s[18], c[18]); // s17, c17

	 full_adder blah18(s[8], c[13], c[18], s[19], c[19]); // s19, c19



	 // stage 4

	 full_adder blah19(s[15], c[14], 0, out[4], c[20]); // out[4], c20

	 full_adder blah20(s[16], c[20], 0, out[5], c[21]); // out[5], c21

	 full_adder blah21(s[17], c[21], 0, out[6], c[22]); // out[6], c22 messed this up in the outline

	 full_adder blah22(s[18], c[22], 0, out[7], c[23]); // out[7], c23

	 full_adder blah23(s[19], c[23], 0, out[8], c[24]); // out[8], c24

	 full_adder blah24(cstar, c[19], c[23], out[9], c[25]); // out[9], c25

	 assign cout = c[25];             

endmodule


