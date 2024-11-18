//module control(instruction, Rwe, Rdst, ALUinB, DMwe, Rwd, ALUop, BR, JP);
//	input [31:0] instruction;
//	output Rdst, Rwe, ALUinB, DMwe, Rwd, BR, JP;
//	output [4:0] ALUop;
//	
//	wire [4:0] opcode;
//	wire isRtype, isSW, isLW;
//	wire[4:0] ALUop;
//	assign opcode = instruction[31:27];
//	
//	//Given we know that R-type opcode is 00000, the & and ~ of all bits will be true if R Type.
//	assign isRtype = (~opcode[4])&(~opcode[3])&(~opcode[2])&(~opcode[1])&(~opcode[0]);
//	//if not r-type then aluop is set to add for sw,lw,addi else use instruction bits 6:2
//	assign ALUop = isRtype? instruction[6:2] : 5'b00000;	
//	
//	//assign control signal outputs
//	//three cases 1. add,sub,and,or, sll, sra (aluopcode) 2. sw 3. lw 4. addi -- PC4
//	assign isSW = (~opcode[4])&(~opcode[3])&(opcode[2])&(opcode[1])&(opcode[0]); //00111
//	assign isLW = (~opcode[4])&(opcode[3])&(~opcode[2])&(~opcode[1])&(~opcode[0]); //01000
//	assign isAddi = (~opcode[4])&(~opcode[3])&(opcode[2])&(~opcode[1])&(opcode[0]); //00101
//	//PC5 Opcodes-- all new cases Jal, Jr, Blt, Bex, Setx
//	assign isJ = (~opcode[4])&(~opcode[3])&(~opcode[2])&(~opcode[1])&(opcode[0]); //00001
//	assign isBne = (~opcode[4])&(~opcode[3])&(~opcode[2])&(opcode[1])&(~opcode[0]); //00010
//	assign isJal = (~opcode[4])&(~opcode[3])&(~opcode[2])&(opcode[1])&(opcode[0]); //00011
//	assign isJr = (~opcode[4])&(~opcode[3])&(opcode[2])&(~opcode[1])&(~opcode[0]); //00100
//	assign isBlt = (~opcode[4])&(~opcode[3])&(opcode[2])&(opcode[1])&(~opcode[0]); //00110
//	assign isBex = (opcode[4])&(~opcode[3])&(opcode[2])&(opcode[1])&(~opcode[0]); //10110
//	assign isSetx = (opcode[4])&(~opcode[3])&(opcode[2])&(~opcode[1])&(opcode[0]); //10101
//	
//	
//	//assign based on control truth table
//	assign Rwe = isRtype | isAddi | isLW | isJal | isSetx; //regwrite
//	assign Rdst = isRtype ? 1'b0 : 1'b1; //reg dst
//	assign ALUinB = isAddi | isSW | isLW; //alusrc
//	assign DMwe = isSW; //memwrite
//	assign Rwd = isLW; //memtoreg
//	assign BR = isBlt | isBne; //BR
//	assign JP = isJ | isJal; //JP
//	
//endmodule

module control(instruction, Rwe, Rdst, ALUinB, DMwe, Rwd, ALUop, BR, JP);
	input [31:0] instruction;
	output Rdst, Rwe, ALUinB, DMwe, Rwd, BR, JP;
	output [4:0] ALUop;
	
	wire [4:0] opcode;
	//wire isRtype, isSW, isLW;
	//wire[4:0] ALUop;
    wire isRtype, isSW, isLW, isAddi, isJ, isBne, isJal, isJr, isBlt, isBex, isSetx;
	assign opcode = instruction[31:27];
    

	//Given we know that R-type opcode is 00000, the & and ~ of all bits will be true if R Type.
	assign isRtype = (~opcode[4])&(~opcode[3])&(~opcode[2])&(~opcode[1])&(~opcode[0]);
	//if not r-type then aluop is set to add for sw,lw,addi else use instruction bits 6:2
	//assign ALUop = isRtype? instruction[6:2] : 5'b00000;	
    // Assign ALUop based on instruction type
    //changed this part
    assign ALUop = isBlt ? 5'b00001 :   // SUBTRACT for BLT
                   isRtype ? instruction[6:2] : // R-Type ALUop from instruction
                   5'b00000;               // ADD for non-R-Type and non-BLT
	
	//assign control signal outputs
	//three cases 1. add,sub,and,or, sll, sra (aluopcode) 2. sw 3. lw 4. addi -- PC4
	assign isSW = (~opcode[4])&(~opcode[3])&(opcode[2])&(opcode[1])&(opcode[0]); //00111
	assign isLW = (~opcode[4])&(opcode[3])&(~opcode[2])&(~opcode[1])&(~opcode[0]); //01000
	assign isAddi = (~opcode[4])&(~opcode[3])&(opcode[2])&(~opcode[1])&(opcode[0]); //00101
	//PC5 Opcodes-- all new cases Jal, Jr, Blt, Bex, Setx
	assign isJ = (~opcode[4])&(~opcode[3])&(~opcode[2])&(~opcode[1])&(opcode[0]); //00001
	assign isBne = (~opcode[4])&(~opcode[3])&(~opcode[2])&(opcode[1])&(~opcode[0]); //00010
	assign isJal = (~opcode[4])&(~opcode[3])&(~opcode[2])&(opcode[1])&(opcode[0]); //00011
	assign isJr = (~opcode[4])&(~opcode[3])&(opcode[2])&(~opcode[1])&(~opcode[0]); //00100
	assign isBlt = (~opcode[4])&(~opcode[3])&(opcode[2])&(opcode[1])&(~opcode[0]); //00110
	assign isBex = (opcode[4])&(~opcode[3])&(opcode[2])&(opcode[1])&(~opcode[0]); //10110
	assign isSetx = (opcode[4])&(~opcode[3])&(opcode[2])&(~opcode[1])&(opcode[0]); //10101
	
	
	//assign based on control truth table
	assign Rwe = isRtype | isAddi | isLW | isJal | isSetx; //regwrite
	assign Rdst = isRtype ? 1'b0 : 1'b1; //reg dst
	assign ALUinB = isAddi | isSW | isLW; //alusrc
	assign DMwe = isSW; //memwrite
	assign Rwd = isLW; //memtoreg
	assign BR = isBlt | isBne; //BR
	assign JP = isJ | isJal; //JP
	
endmodule