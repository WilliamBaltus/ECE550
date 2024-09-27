module half_adder(in_a, in_b, c_out, sum_out);
    input in_a, in_b;
    output sum_out, c_out;

    xor(sum_out, in_a, in_b);
    and(c_out, in_a, in_b);
endmodule
