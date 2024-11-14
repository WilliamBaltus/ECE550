module control(instruction, Rwe, Rdst, ALUinB, DMwe, Rwd, ALUop);
	input [31:0] instruction;
	output Rdst, Rwe, ALUinB, DMwe, Rwd;
	output [4:0] ALUop;
	
	wire [4:0] opcode;
	wire isRtype, isSW, isLW;
	wire[4:0] ALUop;
	assign opcode = instruction[31:27];
	
	//Given we know that R-type opcode is 00000, the & and ~ of all bits will be true if R Type.
	assign isRtype = (~opcode[4])&(~opcode[3])&(~opcode[2])&(~opcode[1])&(~opcode[0]);
	//if not r-type then aluop is set to add for sw,lw,addi else use instruction bits 6:2
	assign ALUop = isRtype? instruction[6:2] : 5'b00000;	
	
	//assign control signal outputs
	//three cases 1. add,sub,and,or, sll, sra (aluopcode) 2. sw 3. lw 4. addi
	assign isSW = (~opcode[4])&(~opcode[3])&(opcode[2])&(opcode[1])&(opcode[0]); //00111
	assign isLW = (~opcode[4])&(opcode[3])&(~opcode[2])&(~opcode[1])&(~opcode[0]); //01000
	assign isAddi = (~opcode[4])&(~opcode[3])&(opcode[2])&(~opcode[1])&(opcode[0]); //00101
	
	//assign based on control truth table
	assign Rwe = isRtype | isAddi | isLW; //regwrite
	assign Rdst = isRtype ? 1'b0 : 1'b1; //reg dst
	assign ALUinB = isAddi | isSW | isLW; //alusrc
	assign DMwe = isSW; //memwrite
	assign Rwd = isLW; //memtoreg
	
endmodule