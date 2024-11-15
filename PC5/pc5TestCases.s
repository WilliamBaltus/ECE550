nop

addi $1, $0, 65535       # r1 = 65535 = 0x0000FFFF
sll $2, $1, 15           # r2 = r1 << 15 = 0x7FFF8000 = 2147450880(decimal)
addi $3, $2, 32767       # r3 = r2 + 32767 = 0x7FFFFFFF(hex) = 2147483647(decimal)
addi $4, $0, 1           # r4 = 1
add $6, $1, $4           # r6 = 65535 + 1 = 65536  (normal addition)
sll $7, $4, 31           # r7 = r4 << 31 = 0x80000000(hex) = -2147483648(decimal)
sub $9, $1, $4           # r9 = r1 - r4 = 65535 - 1 = 65534 (normal subtraction)
and $10, $1, $2          # r10 = r1 & r2 = 0x00008000(hex) = 32768(decimal)
or $12, $1, $2           # r12 = r1 | r2 = 0x7FFFFFFF(hex) = 2147483647(decimal)

addi $20, $0, 2          # r20 = 2
add $21, $4, $20         # r21 = 3
sub $22, $20, $4         # r22 = 2 - 1 = 1
and $23, $22, $21        # r23 = 1 & 3 = 1
or $24, $20, $23         # r24 = 2 | 1 = 3
sll $25, $23,1           # r25 = 1 << 1 = 2
sra $26, $25,1           # r26 = 2 >> 1 = 1 

sw $4, 1($0)             # store 1 into address 1
sw $20, 2($0)            # store 2 into address 2
addi $27, $0, 456        # r27 = 456 
sw $1, 0($27)            # store 65535 into address 456
lw $28, 1($0)            # load 1 from address 1 into r28 (r28 = 1)
lw $29, 2($0)            # load 2 from address 2 into r29 (r29 = 2)
lw $19, 0($27)           # load 65535 from address 456 into r19 (r19 = 65535)

# Test the `bne` and `j` commands
addi $13, $0, 1          # r13 = 1
addi $14, $0, 2          # r14 = 2
bne $13, $14, LABEL1     # Branch to LABEL1 if r13 != r14 (this branch will be taken)
nop                      # This line is skipped if branch is taken
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