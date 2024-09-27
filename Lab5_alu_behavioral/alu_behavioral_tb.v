`timescale 1ns / 100ps

module ALU_tb(); // testbenches take no arguments
    reg [31:0] dataA, dataB;
    reg [4:0] ctrl_ALUopcode; // Control signal should be 5 bits wide
    reg [4:0] ctrl_shiftamt;  // Shift amount for shift operations
    reg clock;
    reg [31:0] expected_result; // Expected result for comparison
    integer error_count = 0;    // Error counter
    wire [31:0] data_result;
    wire isNotEqual, isLessThan, overflow;

    // Instantiate the ALU
    alu test_ALU (
        .data_operandA(dataA), 
        .data_operandB(dataB), 
        .ctrl_ALUopcode(ctrl_ALUopcode), 
        .ctrl_shiftamt(ctrl_shiftamt), 
        .data_result(data_result), 
        .isNotEqual(isNotEqual), 
        .isLessThan(isLessThan), 
        .overflow(overflow)
    );

    // Begin simulation
    initial begin
        $display($time, " Simulation start");

        clock = 1'b0;

        // AND operation
        @ (negedge clock);
        dataA = 32'hFFFFFFFF;
        dataB = 32'h0000AAAA;
        ctrl_ALUopcode = 5'b00100; // AND opcode
        expected_result = 32'h0000AAAA;
        @ (negedge clock);
        if (data_result !== expected_result) begin
            $display("ERROR: AND failed. Expected: %h, Got: %h", expected_result, data_result);
            error_count = error_count + 1;
        end

        // OR operation
        @ (negedge clock);
        dataA = 32'hAAAAAAAA;
        dataB = 32'h55555555;
        ctrl_ALUopcode = 5'b00101; // OR opcode
        expected_result = 32'hFFFFFFFF;
        @ (negedge clock);
        if (data_result !== expected_result) begin
            $display("ERROR: OR failed. Expected: %h, Got: %h", expected_result, data_result);
            error_count = error_count + 1;
        end

        // ADD operation
        @ (negedge clock);
        dataA = 32'h000000AA;
        dataB = 32'h11111100;
        ctrl_ALUopcode = 5'b00000; // ADD opcode
        expected_result = 32'h111111AA;
        @ (negedge clock);
        if (data_result !== expected_result) begin
            $display("ERROR: ADD failed. Expected: %h, Got: %h", expected_result, data_result);
            error_count = error_count + 1;
        end

        // SUBTRACT operation
        @ (negedge clock);
        dataA = 32'h76543210;
        dataB = 32'h12345678;
        ctrl_ALUopcode = 5'b00001; // SUBTRACT opcode
        expected_result = 32'h641FDB98;
        @ (negedge clock);
        if (data_result !== expected_result) begin
            $display("ERROR: SUBTRACT failed. Expected: %h, Got: %h", expected_result, data_result);
            error_count = error_count + 1;
        end

        // SLL (Shift Left Logical) operation
        @ (negedge clock);
        dataA = 32'h00000001;
        ctrl_shiftamt = 5'd4; // Shift amount
        ctrl_ALUopcode = 5'b00010; // SLL opcode
        expected_result = 32'h00000010;
        @ (negedge clock);
        if (data_result !== expected_result) begin
            $display("ERROR: SLL failed. Expected: %h, Got: %h", expected_result, data_result);
            error_count = error_count + 1;
        end

        // SRA (Shift Right Arithmetic) operation
        @ (negedge clock);
        dataA = 32'h80000000;
        ctrl_shiftamt = 5'd4; // Shift amount
        ctrl_ALUopcode = 5'b00011; // SRA opcode
        expected_result = 32'hF8000000;
        @ (negedge clock);
        if (data_result !== expected_result) begin
            $display("ERROR: SRA failed. Expected: %h, Got: %h", expected_result, data_result);
            error_count = error_count + 1;
        end

        // SLT (Set Less Than) operation
        @ (negedge clock);
        dataA = 32'h0000000F;
        dataB = 32'h0000000A;
        ctrl_ALUopcode = 5'b10101; // SLT opcode
        expected_result = 32'h00000000;
        @ (negedge clock);
        if (data_result !== expected_result || isLessThan !== 1'b1) begin
            $display("ERROR: SLT failed. Expected: %h, Got: %h", expected_result, data_result);
            error_count = error_count + 1;
        end

        $display("Simulation finished with %0d errors.", error_count);
    end

    always
        #10 clock = ~clock; // Toggle clock every 10 timescale units
endmodule
