module alu_behavioral(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, data_result, isNotEqual, isLessThan, overflow);
   input [31:0] data_operandA, data_operandB;
   input [4:0] ctrl_ALUopcode, ctrl_shiftamt;

   output reg [31:0] data_result;
   output reg isNotEqual, isLessThan, overflow;
   
	// Sign bits
   wire signA = data_operandA[31];
   wire signB = data_operandB[31];
	 
	localparam [4:0] //opcodes, 5 bits
		ADD = 5'b00000,
		SUBTRACT = 5'b00001,
		SLL = 5'b00010,
		SRA = 5'b00011,
		AND = 5'b00100,
		OR = 5'b00101;
	
	//determine operation and execute!
	always @(*) 
	begin
		 // Default values
		 isNotEqual = 1'b0;
		 isLessThan = 1'b0;
		 overflow = 1'b0;
		 data_result = 32'b0;

		 case(ctrl_ALUopcode)
			  ADD:
			  begin
					data_result = data_operandA + data_operandB;
					
					// Overflow detection for addition
					if ((signA == signB) && (data_result[31] != signA))
						 overflow = 1'b1;
			  end
			  SUBTRACT:
			  begin
					data_result = data_operandA - data_operandB;

					// Overflow detection for subtraction
					if ((signA != signB) && (data_result[31] != signA))
						 overflow = 1'b1;

					// isNotEqual
					if (data_result != 32'b0)
						 isNotEqual = 1'b1;

					// isLessThan
					if ((signA != signB && signA == 1'b1) || (signA == signB && data_result[31] == 1'b1))
						 isLessThan = 1'b1;
			  end
			  SLL:
					data_result = data_operandA << ctrl_shiftamt;
			  SRA:
					data_result = data_operandA >>> ctrl_shiftamt; // Arithmetic right shift
			  AND:
					data_result = data_operandA & data_operandB;
			  OR:
					data_result = data_operandA | data_operandB;
			  default:
					data_result = 32'b0;
		 endcase
	end

	
endmodule
