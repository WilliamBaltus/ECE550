`timescale 1 ns / 100 ps

module alu_tb();

    // Inputs to the ALU are reg type
    reg            clock;
    reg [31:0] data_operandA, data_operandB, data_expected;
    reg [4:0] ctrl_ALUopcode, ctrl_shiftamt;

    // Outputs from the ALU are wire type
    wire [31:0] data_result;
    wire isNotEqual, isLessThan, overflow;

    // Tracking the number of errors
    integer errors;
    integer index;    // for testing...
    integer shift_index;

    // Instantiate ALU
    alu alu_ut(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt,
        data_result, isNotEqual, isLessThan, overflow);

    initial

    begin
        $display($time, " << Starting the Simulation >>");
        clock = 1'b0;    // at time 0
        errors = 0;

        checkOr();
        checkAnd();
        checkSLL();
        checkSRA();

        checkNE();
        checkLT();

        if(errors == 0) begin
            $display("The simulation completed without errors");
        end
        else begin
            $display("The simulation failed with %d errors", errors);
        end

        $stop;
    end

    // Clock generator
    always
         #10     clock = ~clock;

    task checkOr;
        begin
            @(negedge clock);
            ctrl_ALUopcode = 5'b00011; // OR operation
            ctrl_shiftamt = 5'b00000;

            // Test various patterns
            // Test 1: OR of zero and zero
            data_operandA = 32'h00000000;
            data_operandB = 32'h00000000;

            @(negedge clock);
            if(data_result !== 32'h00000000) begin
                $display("**Error in OR (test 1); expected: %h, actual: %h", 32'h00000000, data_result);
                errors = errors + 1;
            end

            // Test 2: OR of zero and ones
            data_operandA = 32'h00000000;
            data_operandB = 32'hFFFFFFFF;

            @(negedge clock);
            if(data_result !== 32'hFFFFFFFF) begin
                $display("**Error in OR (test 2); expected: %h, actual: %h", 32'hFFFFFFFF, data_result);
                errors = errors + 1;
            end

            // Test 3: OR of alternating bits
            data_operandA = 32'hAAAAAAAA;
            data_operandB = 32'h55555555;

            @(negedge clock);
            if(data_result !== 32'hFFFFFFFF) begin
                $display("**Error in OR (test 3); expected: %h, actual: %h", 32'hFFFFFFFF, data_result);
                errors = errors + 1;
            end

            // Test 4: OR of two negative numbers
            data_operandA = 32'h80000000;
            data_operandB = 32'h40000000;

            @(negedge clock);
            if(data_result !== 32'hC0000000) begin
                $display("**Error in OR (test 4); expected: %h, actual: %h", 32'hC0000000, data_result);
                errors = errors + 1;
            end

            // Additional OR tests can be added here
        end
    endtask

    task checkAnd;
        begin
            @(negedge clock);
            ctrl_ALUopcode = 5'b00010; // AND operation
            ctrl_shiftamt = 5'b00000;

            // Test various patterns
            // Test 1: AND of zero and zero
            data_operandA = 32'h00000000;
            data_operandB = 32'h00000000;

            @(negedge clock);
            if(data_result !== 32'h00000000) begin
                $display("**Error in AND (test 1); expected: %h, actual: %h", 32'h00000000, data_result);
                errors = errors + 1;
            end

            // Test 2: AND of zero and ones
            data_operandA = 32'h00000000;
            data_operandB = 32'hFFFFFFFF;

            @(negedge clock);
            if(data_result !== 32'h00000000) begin
                $display("**Error in AND (test 2); expected: %h, actual: %h", 32'h00000000, data_result);
                errors = errors + 1;
            end

            // Test 3: AND of ones and ones
            data_operandA = 32'hFFFFFFFF;
            data_operandB = 32'hFFFFFFFF;

            @(negedge clock);
            if(data_result !== 32'hFFFFFFFF) begin
                $display("**Error in AND (test 3); expected: %h, actual: %h", 32'hFFFFFFFF, data_result);
                errors = errors + 1;
            end

            // Test 4: AND of alternating bits
            data_operandA = 32'hAAAAAAAA;
            data_operandB = 32'h55555555;

            @(negedge clock);
            if(data_result !== 32'h00000000) begin
                $display("**Error in AND (test 4); expected: %h, actual: %h", 32'h00000000, data_result);
                errors = errors + 1;
            end

            // Test 5: AND of two negative numbers
            data_operandA = 32'h80000000;
            data_operandB = 32'h40000000;

            @(negedge clock);
            if(data_result !== 32'h00000000) begin
                $display("**Error in AND (test 5); expected: %h, actual: %h", 32'h00000000, data_result);
                errors = errors + 1;
            end

            // Additional AND tests can be added here
        end
    endtask

    task checkSLL;
        begin
            @(negedge clock);
            ctrl_ALUopcode = 5'b00100; // SLL operation
            data_operandB = 32'h00000000;

            // Test shifting various values by all shift amounts from 0 to 31
            for (shift_index = 0; shift_index <= 31; shift_index = shift_index + 1) begin
                @(negedge clock);
                ctrl_shiftamt = shift_index[4:0];
                data_operandA = 32'h00000001; // Test shifting 1
                data_expected = (shift_index < 32) ? (32'h00000001 << shift_index) : 32'h00000000;

                @(negedge clock);
                if(data_result !== data_expected) begin
                    $display("**Error in SLL (shift %d bits); expected: %h, actual: %h", shift_index, data_expected, data_result);
                    errors = errors + 1;
                end
            end

            // Test shifting a negative number
            @(negedge clock);
            ctrl_shiftamt = 5'd16;
            data_operandA = 32'hF000000F;
            data_expected = 32'h000F0000;

            @(negedge clock);
            if(data_result !== data_expected) begin
                $display("**Error in SLL (negative number shift); expected: %h, actual: %h", data_expected, data_result);
                errors = errors + 1;
            end

            // Additional SLL tests can be added here
        end
    endtask

    task checkSRA;
        begin
            @(negedge clock);
            ctrl_ALUopcode = 5'b00101; // SRA operation
            data_operandB = 32'h00000000;

            // Test shifting various values by all shift amounts from 0 to 31
            // Positive number
            data_operandA = 32'h7FFFFFFF; // Max positive integer
            for (shift_index = 0; shift_index <= 31; shift_index = shift_index + 1) begin
                @(negedge clock);
                ctrl_shiftamt = shift_index[4:0];
                data_expected = $signed(data_operandA) >>> shift_index; // Arithmetic shift right

                @(negedge clock);
                if(data_result !== data_expected) begin
                    $display("**Error in SRA (positive shift %d bits); expected: %h, actual: %h", shift_index, data_expected, data_result);
                    errors = errors + 1;
                end
            end

            // Negative number
            data_operandA = 32'h80000000; // Min negative integer
            for (shift_index = 0; shift_index <= 31; shift_index = shift_index + 1) begin
                @(negedge clock);
                ctrl_shiftamt = shift_index[4:0];
                data_expected = $signed(data_operandA) >>> shift_index; // Arithmetic shift right

                @(negedge clock);
                if(data_result !== data_expected) begin
                    $display("**Error in SRA (negative shift %d bits); expected: %h, actual: %h", shift_index, data_expected, data_result);
                    errors = errors + 1;
                end
            end

            // Test shifting a negative number with specific pattern
            @(negedge clock);
            ctrl_shiftamt = 5'd16;
            data_operandA = 32'hF000000F;
            data_expected = $signed(data_operandA) >>> 16;

            @(negedge clock);
            if(data_result !== data_expected) begin
                $display("**Error in SRA (negative number shift); expected: %h, actual: %h", data_expected, data_result);
                errors = errors + 1;
            end

            // Additional SRA tests can be added here
        end
    endtask

    task checkNE;
        begin
            @(negedge clock);
            ctrl_ALUopcode = 5'b00001; // SUBTRACT operation
            ctrl_shiftamt = 5'b00000;

            // Test when operands are equal
            data_operandA = 32'h00000000;
            data_operandB = 32'h00000000;

            @(negedge clock);
            if(isNotEqual !== 1'b0) begin
                $display("**Error in isNotEqual (equal operands); expected: %b, actual: %b", 1'b0, isNotEqual);
                errors = errors + 1;
            end

            // Test when operands are not equal
            data_operandA = 32'h00000001;
            data_operandB = 32'h00000000;

            @(negedge clock);
            if(isNotEqual !== 1'b1) begin
                $display("**Error in isNotEqual (operands not equal); expected: %b, actual: %b", 1'b1, isNotEqual);
                errors = errors + 1;
            end

            // Test with negative numbers
            data_operandA = 32'hFFFFFFFF; // -1
            data_operandB = 32'hFFFFFFFF; // -1

            @(negedge clock);
            if(isNotEqual !== 1'b0) begin
                $display("**Error in isNotEqual (negative operands equal); expected: %b, actual: %b", 1'b0, isNotEqual);
                errors = errors + 1;
            end

            data_operandA = 32'hFFFFFFFF; // -1
            data_operandB = 32'h00000001; // 1

            @(negedge clock);
            if(isNotEqual !== 1'b1) begin
                $display("**Error in isNotEqual (negative and positive operands); expected: %b, actual: %b", 1'b1, isNotEqual);
                errors = errors + 1;
            end

            // Do not check isNotEqual after other operations since its value is undefined per the assignment

            // Additional isNotEqual tests can be added here
        end
    endtask

    task checkLT;
        begin
            @(negedge clock);
            ctrl_ALUopcode = 5'b00001; // SUBTRACT operation
            ctrl_shiftamt = 5'b00000;

            // Test when data_operandA < data_operandB (positive numbers)
            data_operandA = 32'h00000001;
            data_operandB = 32'h00000002;

            @(negedge clock);
            if(isLessThan !== 1'b1) begin
                $display("**Error in isLessThan (A < B, positive numbers); expected: %b, actual: %b", 1'b1, isLessThan);
                errors = errors + 1;
            end

            // Test when data_operandA > data_operandB (positive numbers)
            data_operandA = 32'h00000003;
            data_operandB = 32'h00000002;

            @(negedge clock);
            if(isLessThan !== 1'b0) begin
                $display("**Error in isLessThan (A > B, positive numbers); expected: %b, actual: %b", 1'b0, isLessThan);
                errors = errors + 1;
            end

            // Test when data_operandA and data_operandB are equal
            data_operandA = 32'h00000002;
            data_operandB = 32'h00000002;

            @(negedge clock);
            if(isLessThan !== 1'b0) begin
                $display("**Error in isLessThan (A == B); expected: %b, actual: %b", 1'b0, isLessThan);
                errors = errors + 1;
            end

            // Test with negative numbers
            data_operandA = 32'hFFFFFFFE; // -2
            data_operandB = 32'hFFFFFFFF; // -1

            @(negedge clock);
            if(isLessThan !== 1'b1) begin
                $display("**Error in isLessThan (A < B, negative numbers); expected: %b, actual: %b", 1'b1, isLessThan);
                errors = errors + 1;
            end

            data_operandA = 32'hFFFFFFFF; // -1
            data_operandB = 32'hFFFFFFFE; // -2

            @(negedge clock);
            if(isLessThan !== 1'b0) begin
                $display("**Error in isLessThan (A > B, negative numbers); expected: %b, actual: %b", 1'b0, isLessThan);
                errors = errors + 1;
            end

            // Test when data_operandA is positive and data_operandB is negative
            data_operandA = 32'h00000001; // 1
            data_operandB = 32'hFFFFFFFF; // -1

            @(negedge clock);
            if(isLessThan !== 1'b0) begin
                $display("**Error in isLessThan (A positive, B negative); expected: %b, actual: %b", 1'b0, isLessThan);
                errors = errors + 1;
            end

            // Test when data_operandA is negative and data_operandB is positive
            data_operandA = 32'hFFFFFFFF; // -1
            data_operandB = 32'h00000001; // 1

            @(negedge clock);
            if(isLessThan !== 1'b1) begin
                $display("**Error in isLessThan (A negative, B positive); expected: %b, actual: %b", 1'b1, isLessThan);
                errors = errors + 1;
            end

            // Do not check isLessThan after other operations since its value is undefined per the assignment

            // Additional isLessThan tests can be added here
        end
    endtask

endmodule
























//`timescale 1 ns / 100 ps
//
//module alu_tb();
//
//    // inputs to the ALU are reg type
//
//    reg            clock;
//    reg [31:0] data_operandA, data_operandB, data_expected;
//    reg [4:0] ctrl_ALUopcode, ctrl_shiftamt;
//
//
//    // outputs from the ALU are wire type
//    wire [31:0] data_result;
//    wire isNotEqual, isLessThan, overflow;
//
//
//    // Tracking the number of errors
//    integer errors;
//    integer index;    // for testing...
//
//
//    // Instantiate ALU
//    alu alu_ut(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt,
//        data_result, isNotEqual, isLessThan, overflow);
//
//    initial
//
//    begin
//        $display($time, " << Starting the Simulation >>");
//        clock = 1'b0;    // at time 0
//        errors = 0;
//
//        //checkOr();
//        //checkAnd();
//        checkAdd();
//        checkSub();
//        //checkSLL();
//        //checkSRA();
//
//        //checkNE();
//        //checkLT();
//        checkOverflow();
//
//        if(errors == 0) begin
//            $display("The simulation completed without errors");
//        end
//        else begin
//            $display("The simulation failed with %d errors", errors);
//        end
//
//        $stop;
//    end
//
//    // Clock generator
//    always
//         #10     clock = ~clock;
//
//    task checkOr;
//        begin
//            @(negedge clock);
//            assign ctrl_ALUopcode = 5'b00011;
//            assign ctrl_shiftamt = 5'b00000;
//
//            assign data_operandA = 32'h00000000;
//            assign data_operandB = 32'h00000000;
//
//            @(negedge clock);
//            if(data_result !== 32'h00000000) begin
//                $display("**Error in OR (test 1); expected: %h, actual: %h", 32'h00000000, data_result);
//                errors = errors + 1;
//            end
//
//            @(negedge clock);
//            assign data_operandA = 32'hFFFFFFFF;
//            assign data_operandB = 32'h00000000;
//
//            @(negedge clock);
//            if(data_result !== 32'hFFFFFFFF) begin
//                $display("**Error in OR (test 2); expected: %h, actual: %h", 32'hFFFFFFFF, data_result);
//                errors = errors + 1;
//            end
//
//            @(negedge clock);
//            assign data_operandA = 32'h00000000;
//            assign data_operandB = 32'hFFFFFFFF;
//
//            @(negedge clock);
//            if(data_result !== 32'hFFFFFFFF) begin
//                $display("**Error in OR (test 3); expected: %h, actual: %h", 32'hFFFFFFFF, data_result);
//                errors = errors + 1;
//            end
//
//            @(negedge clock);
//            assign data_operandA = 32'hFFFFFFFF;
//            assign data_operandB = 32'hFFFFFFFF;
//
//            @(negedge clock);
//            if(data_result !== 32'hFFFFFFFF) begin
//                $display("**Error in OR (test 4); expected: %h, actual: %h", 32'hFFFFFFFF, data_result);
//                errors = errors + 1;
//            end
//        end
//    endtask
//
//    task checkAnd;
//        begin
//            @(negedge clock);
//            assign ctrl_ALUopcode = 5'b00010;
//            assign ctrl_shiftamt = 5'b00000;
//
//            assign data_operandA = 32'h00000000;
//            assign data_operandB = 32'h00000000;
//
//            @(negedge clock);
//            if(data_result !== 32'h00000000) begin
//                $display("**Error in AND (test 5); expected: %h, actual: %h", 32'h00000000, data_result);
//                errors = errors + 1;
//            end
//
//            @(negedge clock);
//            assign data_operandA = 32'hFFFFFFFF;
//            assign data_operandB = 32'h00000000;
//
//            @(negedge clock);
//            if(data_result !== 32'h00000000) begin
//                $display("**Error in AND (test 6); expected: %h, actual: %h", 32'h00000000, data_result);
//                errors = errors + 1;
//            end
//
//            @(negedge clock);
//            assign data_operandA = 32'h00000000;
//            assign data_operandB = 32'hFFFFFFFF;
//
//            @(negedge clock);
//            if(data_result !== 32'h00000000) begin
//                $display("**Error in AND (test 7); expected: %h, actual: %h", 32'h00000000, data_result);
//                errors = errors + 1;
//            end
//
//            @(negedge clock);
//            assign data_operandA = 32'hFFFFFFFF;
//            assign data_operandB = 32'hFFFFFFFF;
//
//            @(negedge clock);
//            if(data_result !== 32'hFFFFFFFF) begin
//                $display("**Error in AND (test 8); expected: %h, actual: %h", 32'hFFFFFFFF, data_result);
//                errors = errors + 1;
//            end
//        end
//    endtask
//
//    task checkAdd;
//        begin
//            @(negedge clock);
//            assign ctrl_ALUopcode = 5'b00000;
//            assign ctrl_shiftamt = 5'b00000;
//
//            assign data_operandA = 32'h00000000;
//            assign data_operandB = 32'h00000000;
//
//            @(negedge clock);
//            if(data_result !== 32'h00000000) begin
//                $display("**Error in ADD (test 9); expected: %h, actual: %h", 32'h00000000, data_result);
//                errors = errors + 1;
//            end
//
//            for(index = 0; index < 31; index = index + 1)
//            begin
//                @(negedge clock);
//                assign data_operandA = 32'h00000001 << index;
//                assign data_operandB = 32'h00000001 << index;
//
//                assign data_expected = 32'h00000001 << (index + 1);
//
//                @(negedge clock);
//                if(data_result !== data_expected) begin
//                    $display("**Error in ADD (test 17 part %d); expected: %h, actual: %h", index, data_expected, data_result);
//                    errors = errors + 1;
//                end
//            end
//        end
//    endtask
//
//    task checkSub;
//        begin
//            @(negedge clock);
//            assign ctrl_ALUopcode = 5'b00001;
//            assign ctrl_shiftamt = 5'b00000;
//
//            assign data_operandA = 32'h00000000;
//            assign data_operandB = 32'h00000000;
//
//            @(negedge clock);
//            if(data_result !== 32'h00000000) begin
//                $display("**Error in SUB (test 10); expected: %h, actual: %h", 32'h00000000, data_result);
//                errors = errors + 1;
//            end
//        end
//    endtask
//
//    task checkSLL;
//        begin
//            @(negedge clock);
//            assign ctrl_ALUopcode = 5'b00100;
//            assign data_operandB = 32'h00000000;
//
//            assign data_operandA = 32'h00000001;
//            assign ctrl_shiftamt = 5'b00000;
//
//            @(negedge clock);
//            if(data_result !== 32'h00000001) begin
//                $display("**Error in SLL (test 11); expected: %h, actual: %h", 32'h00000001, data_result);
//                errors = errors + 1;
//            end
//
//            for(index = 0; index < 5; index = index + 1)
//            begin
//                @(negedge clock);
//                assign data_operandA = 32'h00000001;
//                assign ctrl_shiftamt = 5'b00001 << index;
//
//                assign data_expected = 32'h00000001 << (2**index);
//
//                @(negedge clock);
//                if(data_result !== data_expected) begin
//                    $display("**Error in SLL (test 18 part %d); expected: %h, actual: %h", index, data_expected, data_result);
//                    errors = errors + 1;
//                end
//            end
//
//            for(index = 0; index < 4; index = index + 1)
//            begin
//                @(negedge clock);
//                assign data_operandA = 32'h00000001;
//                assign ctrl_shiftamt = 5'b00011 << index;
//
//                assign data_expected = 32'h00000001 << ((2**index) + (2**(index + 1)));
//
//                @(negedge clock);
//                if(data_result !== data_expected) begin
//                    $display("**Error in SLL (test 19 part %d); expected: %h, actual: %h", index, data_expected, data_result);
//                    errors = errors + 1;
//                end
//            end
//        end
//    endtask
//
//    task checkSRA;
//        begin
//            @(negedge clock);
//            assign ctrl_ALUopcode = 5'b00101;
//            assign data_operandB = 32'h00000000;
//
//            assign data_operandA = 32'h00000000;
//            assign ctrl_shiftamt = 5'b00000;
//
//            @(negedge clock);
//            if(data_result !== 32'h00000000) begin
//                $display("**Error in SRA (test 12); expected: %h, actual: %h", 32'h00000000, data_result);
//                errors = errors + 1;
//            end
//        end
//    endtask
//
//    task checkNE;
//        begin
//            @(negedge clock);
//            assign ctrl_ALUopcode = 5'b00001;
//            assign ctrl_shiftamt = 5'b00000;
//
//            assign data_operandA = 32'h00000000;
//            assign data_operandB = 32'h00000000;
//
//            @(negedge clock);
//            if(isNotEqual !== 1'b0) begin
//                $display("**Error in isNotEqual (test 13); expected: %b, actual: %b", 1'b0, isNotEqual);
//                errors = errors + 1;
//            end
//        end
//    endtask
//
//    task checkLT;
//        begin
//            @(negedge clock);
//            assign ctrl_ALUopcode = 5'b00001;
//            assign ctrl_shiftamt = 5'b00000;
//
//            assign data_operandA = 32'h00000000;
//            assign data_operandB = 32'h00000000;
//
//            @(negedge clock);
//            if(isLessThan !== 1'b0) begin
//                $display("**Error in isLessThan (test 14); expected: %b, actual: %b", 1'b0, isLessThan);
//                errors = errors + 1;
//            end
//
//            @(negedge clock);
//            assign data_operandA = 32'h0FFFFFFF;
//            assign data_operandB = 32'hFFFFFFFF;
//
//            @(negedge clock);
//            if(isLessThan !== 1'b0) begin
//                $display("**Error in isLessThan (test 23); expected: %b, actual: %b", 1'b0, isLessThan);
//                errors = errors + 1;
//            end
//
//            // Less than with overflow
//            @(negedge clock);
//            assign data_operandA = 32'h80000001;
//            assign data_operandB = 32'h7FFFFFFF;
//
//            @(negedge clock);
//            if(isLessThan !== 1'b1) begin
//                $display("**Error in isLessThan (test 24); expected: %b, actual: %b", 1'b1, isLessThan);
//                errors = errors + 1;
//            end
//        end
//    endtask
//
//    task checkOverflow;
//        begin
//            @(negedge clock);
//            assign ctrl_ALUopcode = 5'b00000;
//            assign ctrl_shiftamt = 5'b00000;
//
//            assign data_operandA = 32'h00000000;
//            assign data_operandB = 32'h00000000;
//
//            @(negedge clock);
//            if(overflow !== 1'b0) begin
//                $display("**Error in overflow (test 15); expected: %b, actual: %b", 1'b0, overflow);
//                errors = errors + 1;
//            end
//
//            @(negedge clock);
//            assign data_operandA = 32'h80000000;
//            assign data_operandB = 32'h80000000;
//
//            @(negedge clock);
//            if(overflow !== 1'b1) begin
//                $display("**Error in overflow (test 20); expected: %b, actual: %b", 1'b1, overflow);
//                errors = errors + 1;
//            end
//
//            @(negedge clock);
//            assign data_operandA = 32'h40000000;
//            assign data_operandB = 32'h40000000;
//
//            @(negedge clock);
//            if(overflow !== 1'b1) begin
//                $display("**Error in overflow (test 21); expected: %b, actual: %b", 1'b1, overflow);
//                errors = errors + 1;
//            end
//
//            @(negedge clock);
//            assign ctrl_ALUopcode = 5'b00001;
//
//            assign data_operandA = 32'h00000000;
//            assign data_operandB = 32'h00000000;
//
//            @(negedge clock);
//            if(overflow !== 1'b0) begin
//                $display("**Error in overflow (test 16); expected: %b, actual: %b", 1'b0, overflow);
//                errors = errors + 1;
//            end
//
//            @(negedge clock);
//            assign data_operandA = 32'h80000000;
//            assign data_operandB = 32'h80000000;
//
//            @(negedge clock);
//            if(overflow !== 1'b0) begin
//                $display("**Error in overflow (test 22); expected: %b, actual: %b", 1'b0, overflow);
//                errors = errors + 1;
//            end
//
//            @(negedge clock);
//            assign data_operandA = 32'h80000000;
//            assign data_operandB = 32'h0F000000;
//
//            @(negedge clock);
//            if(overflow !== 1'b1) begin
//                $display("**Error in overflow (test 25); expected: %b, actual: %b", 1'b1, overflow);
//                errors = errors + 1;
//            end
//        end
//    endtask
//
//endmodule
