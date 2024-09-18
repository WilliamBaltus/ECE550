How it works:

1. I determine if it is add or subtract based on opcode.
2. If it is subtraction then data_operandB must be inverted (2's complement first half)
3. A mux wll select inversion or regular data_operandB based on if we are in subtraction mode
4. Carry_in is set to 1 if subtraction (finish 2's complement) otherwise carry_in is 0
5. 4 8-bit CLA's to make 32 bit adder. Can compute propogate and generate signals since its xor and and's. Computes sum.
6. Compares carry in and out of MSB to see if overflow.
7. DONE
