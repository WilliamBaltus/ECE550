nop

# Test the `bne` and `j` commands
addi $1, $0, 1          # r1 = 1
addi $2, $0, 2          # r2 = 2
bne $1, $2, LABEL1     # Branch to LABEL1 if r13 != r14 (this branch will be taken)
addi $13, $0, 456                      # This line is skipped if branch is taken
addi $14, $0, 327
LABEL1:
addi $15, $0, 100        # r15 = 100 (this line executes after branch)

# Edge case: Test when `bne` does not succeed
addi $16, $0, 1          # r16 = 1
addi $17, $0, 1          # r17 = 1
bne $16, $17, LABEL2     # Branch to LABEL2 if r16 != r17 (this branch will NOT be taken)
addi $18, $0, 200        # r18 = 200 (this line executes because branch is NOT taken)
LABEL2:
addi $19, $0, 300        # r19 = 300 (this line executes after label)

# Test the `j` command and edge cases
addi $20, $0, 400        # r20 = 400 (executed before jump)
j TEST_JUMP              # Jump unconditionally to TEST_JUMP
addi $21, $0, 500        # r21 = 500 (this line should be skipped due to the jump)
TEST_JUMP:
addi $22, $0, 600        # r22 = 600 (this line is executed after the jump)

nop                      # End of program