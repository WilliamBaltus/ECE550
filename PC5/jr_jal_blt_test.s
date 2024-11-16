nop                            # PC = 0 (increments PC by 1, no changes to registers)

# Test the `jr` command
addi $2, $0, 5                 # PC = 1, $r2 = 5 (set $r2 to the target instruction address)
jr $2                          # PC = 2, jump to instruction 5
addi $3, $0, 300               # PC = 3 (skipped due to `jr`, $r3 remains 0)
addi $4, $0, 400               # PC = 4 (skipped due to `jr`, $r4 remains 0)

# Test the `blt` command (branch taken)
addi $5, $0, 5                 # PC = 5, $r5 = 5 (setup for comparison, $rd)
addi $6, $0, 10                # PC = 6, $r6 = 10 (setup for comparison, $rs)
blt $5, $6, BLT_TRUE           # PC = 7, branch to BLT_TRUE if $r5 < $r6 (branch taken)
addi $7, $0, 1000              # PC = 8, $r7 = 1000 (skipped due to `blt`)
BLT_TRUE:
addi $7, $7, 5                 # PC = 9, $r7 = $r7 + 5 (modify $r7 as part of testing)

# Test the `blt` command (branch not taken)
addi $8, $0, 15                # PC = 10, $r8 = 15 (setup for comparison, $rd)
addi $9, $0, 10                # PC = 11, $r9 = 10 (setup for comparison, $rs)
blt $8, $9, BLT_FALSE          # PC = 12, branch to BLT_FALSE if $r8 < $r9 (branch not taken)
addi $10, $0, 1500             # PC = 13, $r10 = 1500 (this line executes because branch not taken)
BLT_FALSE:
addi $10, $10, 50              # PC = 14, $r10 = $r10 + 50 (modify $r10 as part of testing)

# Test the first `jal` command
addi $11, $0, 700              # PC = 15, $r11 = 700 (setup before jump and link)
jal LABEL_JAL                  # PC = 16, jump to LABEL_JAL and store return address (PC + 1 = 17) in $r31
addi $12, $0, 8000             # PC = 17, $r12 = 8000 (this line is executed after returning via `jr $31`)
addi $12, $12, 100             # PC = 18, $r12 = $r12 + 100 (further test after returning)

# Test the second `jal` command
addi $13, $0, 500              # PC = 19, $r13 = 500 (setup before second jump and link)
jal LABEL_JAL2                 # PC = 20, jump to LABEL_JAL2 and store return address (PC + 1 = 21) in $r31
addi $14, $0, 1000             # PC = 21, $r14 = 1000 (this line is executed after returning via `jr $31`)

LABEL_JAL:
addi $15, $0, 900              # PC = 22, $r15 = 900 (this line is executed after first `jal`)
addi $16, $0, 1000             # PC = 23, $r16 = 1000 (instruction after first `jal` target)
jr $31                         # PC = 24, return to the instruction after `jal` (PC = 17)

LABEL_JAL2:
addi $17, $0, 1200             # PC = 25, $r17 = 1200 (this line is executed after second `jal`)
addi $18, $0, 1300             # PC = 26, $r18 = 1300 (instruction after second `jal` target)
jr $31                         # PC = 27, return to the instruction after `jal` (PC = 21)

addi $19, $0, 2000             # PC = 28, $r19 = 2000 (this line is executed after all jumps)

# $r0  = 0    # (always zero)
# $r2  = 5    # (set for the first `jr`)
# $r3  = 0    # (skipped due to the first `jr`)
# $r4  = 0    # (skipped due to the first `jr`)
# $r5  = 5    # (set for first `blt` test, $rd)
# $r6  = 10   # (set for first `blt` test, $rs)
# $r7  = 5    # (modified in `BLT_TRUE`, $r7 = $r7 + 5)
# $r8  = 15   # (set for second `blt` test, $rd)
# $r9  = 10   # (set for second `blt` test, $rs)
# $r10 = 1550 # (modified in `BLT_FALSE`, $r10 = $r10 + 50)
# $r11 = 700  # (set before the first `jal`)
# $r12 = 8100 # (modified after returning from first `jal`)
# $r13 = 500  # (set before the second `jal`)
# $r14 = 1000 # (set after returning to `addi $14, $0, 1000` at PC = 21)
# $r15 = 900  # (set in `LABEL_JAL`)
# $r16 = 1000 # (set in `LABEL_JAL`)
# $r17 = 1200 # (set in `LABEL_JAL2`)
# $r18 = 1300 # (set in `LABEL_JAL2`)
# $r19 = 2000 # (set after all jumps and branches)
# $r31 = 21   # (return address stored after the second `jal`)
