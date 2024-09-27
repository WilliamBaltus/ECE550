module full_adder(in_a, in_b, c_in, sum_out, c_out);
    input in_a, in_b, c_in;
    output sum_out, c_out;
    wire xor_ab, and_ab, and_xor_cin;

    xor(xor_ab, in_a, in_b);
    xor(sum_out, xor_ab, c_in);

    and(and_ab, in_a, in_b);
    and(and_xor_cin, xor_ab, c_in);
    or(c_out, and_ab, and_xor_cin);
endmodule

//
//module full_adder(in_a, in_b, c_in, c_out, sum_out);
//    input in_a, in_b, c_in;
//    output sum_out, c_out;
//    wire xor_ab, and_ab, and_xor_cin;
//
//    xor(xor_ab, in_a, in_b);
//    xor(sum_out, xor_ab, c_in);
//
//    and(and_ab, in_a, in_b);
//    and(and_xor_cin, xor_ab, c_in);
//    or(c_out, and_ab, and_xor_cin);
//endmodule
