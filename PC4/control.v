module control(instruction, Rwe, Rdst, ALUinB, DMwe, Rwd, ALUop)
	input[31:0] instruction;
	output Rdst,Rwe ALUinB, DMwe, Rwd;
	output [4:0] ALUop;
	
	wire [4:0] opcode;
	wire Rwe,Rdst, ALUinB, DMwe, Rwd, isRType, isSW, isLW;
	wire[4:0] ALUop;
	assign opcode = instruction[31:27];
	
	//Given we know that R-type opcode is 00000, the & and ~ of all bits will be true if R Type.
	assign isRType = (~opcode[4])&(~opcode[3])&(~opcode[2])&(~opcode[1])&(~opcode[0]);
	//if not r-type then aluop is set to add for sw,lw,addi else use instruction bits 6:2
	assign ALUop = isRType? instruction[6:2] : 5'b00000;	
	
	//assign control signal outputs
	//three cases 1. add,sub,and,or, sll, sra (aluopcode) 2. sw 3. lw
	assign isSW = (~opcode[4])&(~opcode[3])&(opcode[2])&(opcode[1])&(opcode[0]); //00111
	assign isLW = (~opcode[4])&(opcode[3])&(~opcode[2])&(~opcode[1])&(~opcode[0]); //01000
	
	//assign based on control truth table
	assign Rwe = isRtype | isLW; //regwrite
	assign Rdst = isRtype ? 1'b0 : 1'b1; //reg dst
	assign ALUinB = isSw | isLW; //alusrc
	assign DMwe = isSw; //memwrite
	assign Rwd = isLw; //memtoreg
	
endmodule