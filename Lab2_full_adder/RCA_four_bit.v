module RCA_four_bit(c_in, in_a, in_b, c_out, sum_out);
	input [3:0] in_a, in_b;
	input c_in;
	output [3:0] sum_out;
	output c_out;
	
	wire add_1_C_out, add_2_c_out, add_3_c_out;
	
	adder adder_1(in_a[0], in_b[0], c_in, sum_out[0], add_1_c_out);
	adder adder_2(in_a[1], in_b[1], add_1_c_out, sum_out[1], add_2_c_out);
	adder adder_3(in_a[2], in_b[2], add_2_c_out, sum_out[2], add_3_c_out);
	adder adder_4(in_a[3], in_b[3], add_3_c_out, sum_out[3], c_out);
	
endmodule