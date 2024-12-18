nop                            # PC = 0 (increments PC by 1, no changes to registers)

# Test the `jr` command
addi $2, $0, 5                 # PC = 1, $r2 = 5 (set $r2 to the target instruction address)
jr $2                          # PC = 2, jump to instruction at address 5
addi $3, $0, 300               # PC = 3 (skipped due to `jr`, $r3 remains 0)
addi $4, $0, 400               # PC = 4 (skipped due to `jr`, $r4 remains 0)

# Test the `blt` command (branch taken)
addi $5, $0, 5                 # PC = 5, $r5 = 5 (setup for comparison, $rd)
addi $6, $0, 10                # PC = 6, $r6 = 10 (setup for comparison, $rs)
blt $5, $6, BLT_TRUE           # PC = 7, branch to BLT_TRUE if $r5 < $r6 (branch taken)
addi $7, $0, 1000              # PC = 8 (skipped due to `blt`, $r7 remains 0)
BLT_TRUE:
addi $7, $7, 5                 # PC = 9, $r7 = $r7 + 5 (modify $r7 as part of testing)

# Test the `blt` command (branch not taken)
addi $8, $0, 15                # PC = 10, $r8 = 15 (setup for comparison, $rd)
addi $9, $0, 10                # PC = 11, $r9 = 10 (setup for comparison, $rs)
blt $8, $9, BLT_FALSE          # PC = 12, branch to BLT_FALSE if $r8 < $r9 (branch not taken)
addi $10, $0, 1500             # PC = 13, $r10 = 1500 (this line executes because branch not taken)
j AFTER_BLT                    # PC = 14, jump to AFTER_BLT to skip BLT_FALSE code
BLT_FALSE:
addi $10, $0, 1500             # PC = 15, $r10 = 1500 (executed if branch taken)
addi $10, $10, 50              # PC = 16, $r10 = $r10 + 50 (modify $r10 when branch taken)
AFTER_BLT:
addi $20, $0, 1234             # PC = 17, $r20 = 1234 (additional instruction to observe execution flow)

# Test the first `jal` command
addi $11, $0, 700              # PC = 18, $r11 = 700 (setup before jump and link)
jal LABEL_JAL                  # PC = 19, jump to LABEL_JAL and store return address (PC + 1 = 20) in $r31
addi $12, $0, 8000             # PC = 20, $r12 = 8000 (this line is executed after returning via `jr $31`)
addi $12, $12, 100             # PC = 21, $r12 = $r12 + 100 (further test after returning)

# Test the second `jal` command
addi $13, $0, 500              # PC = 22, $r13 = 500 (setup before second jump and link)
jal LABEL_JAL2                 # PC = 23, jump to LABEL_JAL2 and store return address (PC + 1 = 24) in $r31
addi $14, $0, 1000             # PC = 24, $r14 = 1000 (this line is executed after returning via `jr $31`)

addi $21, $0, 5678             # PC = 25, $r21 = 5678 (additional instruction to observe execution flow)

addi $19, $0, 2000             # PC = 26, $r19 = 2000 (this line is executed after all jumps)
addi $22, $0, 2222             # PC = 27, $r22 = 2222 (additional instructions)
addi $23, $0, 2323             # PC = 28, $r23 = 2323
addi $24, $0, 2424             # PC = 29, $r24 = 2424
addi $25, $0, 2525             # PC = 30, $r25 = 2525
addi $26, $0, 2626             # PC = 31, $r26 = 2626
addi $27, $0, 2727             # PC = 32, $r27 = 2727
addi $28, $0, 2828             # PC = 33, $r28 = 2828
addi $29, $0, 2929             # PC = 34, $r29 = 2929
addi $30, $0, 3030             # PC = 35, $r30 = 3030

# Subroutine for the first `jal`
LABEL_JAL:
addi $15, $0, 900              # PC = 36, $r15 = 900 (executed after first `jal`)
addi $16, $0, 1000             # PC = 37, $r16 = 1000
jr $31                         # PC = 38, return to the instruction after `jal` (PC = 20)

# Subroutine for the second `jal`
LABEL_JAL2:
addi $17, $0, 1200             # PC = 39, $r17 = 1200 (executed after second `jal`)
addi $18, $0, 1300             # PC = 40, $r18 = 1300
jr $31                         # PC = 41, return to the instruction after `jal` (PC = 24)

# Expected final register values:
# $r0  = 0      # (always zero)
# $r2  = 5      # (set for the first `jr`)
# $r3  = 0      # (skipped due to `jr`)
# $r4  = 0      # (skipped due to `jr`)
# $r5  = 5      # (set for first `blt` test)
# $r6  = 10     # (set for first `blt` test)
# $r7  = 5      # (modified in `BLT_TRUE`)
# $r8  = 15     # (set for second `blt` test)
# $r9  = 10     # (set for second `blt` test)
# $r10 = 1500   # (set at PC = 13; addition of 50 skipped because branch not taken)
# $r11 = 700    # (set before the first `jal`)
# $r12 = 8100   # (modified after returning from first `jal`)
# $r13 = 500    # (set before the second `jal`)
# $r14 = 1000   # (set after returning from second `jal`)
# $r15 = 900    # (set in `LABEL_JAL`)
# $r16 = 1000   # (set in `LABEL_JAL`)
# $r17 = 1200   # (set in `LABEL_JAL2`)
# $r18 = 1300   # (set in `LABEL_JAL2`)
# $r19 = 2000   # (set after all jumps and branches)
# $r20 = 1234   # (set at PC = 17)
# $r21 = 5678   # (set at PC = 25)
# $r22 = 2222   # (set at PC = 27)
# $r23 = 2323   # (set at PC = 28)
# $r24 = 2424   # (set at PC = 29)
# $r25 = 2525   # (set at PC = 30)
# $r26 = 2626   # (set at PC = 31)
# $r27 = 2727   # (set at PC = 32)
# $r28 = 2828   # (set at PC = 33)
# $r29 = 2929   # (set at PC = 34)
# $r30 = 3030   # (set at PC = 35)
# $r31 = 24     # (return address stored after the second `jal`)
