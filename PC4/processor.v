/**
 * READ THIS DESCRIPTION!
 *
 * The processor takes in several inputs from a skeleton file.
 *
 * Inputs
 * clock: this is the clock for your processor at 50 MHz
 * reset: we should be able to assert a reset to start your pc from 0 (sync or
 * async is fine)
 *
 * Imem: input data from imem
 * Dmem: input data from dmem
 * Regfile: input data from regfile
 *
 * Outputs
 * Imem: output control signals to interface with imem
 * Dmem: output control signals and data to interface with dmem
 * Regfile: output control signals and data to interface with regfile
 *
 * Notes
 *
 * Ultimately, your processor will be tested by subsituting a master skeleton, imem, dmem, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file acts as a small wrapper around your processor for this purpose.
 *
 * You will need to figure out how to instantiate two memory elements, called
 * "syncram," in Quartus: one for imem and one for dmem. Each should take in a
 * 12-bit address and allow for storing a 32-bit value at each address. Each
 * should have a single clock.
 *
 * Each memory element should have a corresponding .mif file that initializes
 * the memory element to certain value on start up. These should be named
 * imem.mif and dmem.mif respectively.
 *
 * Importantly, these .mif files should be placed at the top level, i.e. there
 * should be an imem.mif and a dmem.mif at the same level as process.v. You
 * should figure out how to point your generated imem.v and dmem.v files at
 * these MIF files.
 *
 * imem
 * Inputs:  12-bit address, 1-bit clock enable, and a clock
 * Outputs: 32-bit instruction
 *
 * dmem
 * Inputs:  12-bit address, 1-bit clock, 32-bit data, 1-bit write enable
 * Outputs: 32-bit data at the given address
 *
 */
module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for regfile
    ctrl_writeReg,                  // O: Register to write to in regfile
    ctrl_readRegA,                  // O: Register to read from port A of regfile
    ctrl_readRegB,                  // O: Register to read from port B of regfile
    data_writeReg,                  // O: Data to write to for regfile
    data_readRegA,                  // I: Data from port A of regfile
    data_readRegB                   // I: Data from port B of regfile
);
    // Control signals
    input clock, reset;

    // Imem
    output [11:0] address_imem;
    input [31:0] q_imem;

    // Dmem
    output [11:0] address_dmem;
    output [31:0] data;
    output wren;
    input [31:0] q_dmem;

    // Regfile
    output ctrl_writeEnable;
    output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
    output [31:0] data_writeReg;
    input [31:0] data_readRegA, data_readRegB;
		
	  /**********************************************************************************************
	  **********************************CODE STARTS HERE********************************************* 
	  ***********************************************************************************************/

	 //Control wires
	 wire Rwe, Rdst, ALUinB, DMwe, Rwd;
	 wire[4:0] ALUop, shamt, opcode;
	 wire [4:0] rd, rs, rt;
	 wire [31:0] instruction;
	 wire [31:0] rStatus;
	 wire [31:0] write_data_reg;
	 wire [31:0] alu_result;
	 
	 // PC-related wires
    wire [31:0] pc_current, pc_next; 
	 wire [31:0] increment_value = 32'd1; // Constant 1 for PC increment
    wire isNotEqual, isLessThan, overflow_pc, overflow_alu; // ALU flags
	 wire [15:0] immediate;
	 wire [31:0] immediate_sx;
	 
	 
	 
	 // Program Counter (PC) -- init to 0 is reset is high, else mumbo jumbo
	 pc program_counter(.clock(clock), 
							  .reset(reset),
							  .pc_current(pc_current),
							  .pc_next(pc_next));
							  
							  
	 // PC increment
    alu pc_increment_alu(
        .data_operandA(pc_current),      // Current PC
        .data_operandB(increment_value), // Increment by 4
        .ctrl_ALUopcode(5'b00000),       // Opcode for addition
        .ctrl_shiftamt(5'b00000),        // No shift required
        .data_result(pc_next),           // Result assigned to pc_next
        .isNotEqual(isNotEqual),
        .isLessThan(isLessThan),
        .overflow(overflow_pc)
    );
	 
	 assign address_imem = pc_current[11:0];  // where to read instruction code

	 //Control Circuit (CC)
	 control control_circuit(.instruction(q_imem), 
									 .Rwe(Rwe), 
									 .Rdst(Rdst), 
									 .ALUinB(ALUinB), 
									 .DMwe(DMwe), 
									 .Rwd(Rwd), 
									 .ALUop(ALUop));
	 
	 //ALU operation
	 assign opcode = instruction[31:27];
	 
	 assign isAdd = (~ALUop[4])&(~ALUop[3])&(~ALUop[2])&(~ALUop[1])&(~ALUop[0]); //00000
	 assign isSub = (~ALUop[4])&(~ALUop[3])&(~ALUop[2])&(~ALUop[1])&(ALUop[0]); //00001
	 assign isAddi = (~opcode[4])&(~opcode[3])&(opcode[2])&(~opcode[1])&(opcode[0]); //00101
	 assign isLW = (~opcode[4])&(opcode[3])&(~opcode[2])&(~opcode[1])&(~opcode[0]); //01000
	 assign isSW = (~opcode[4])&(~opcode[3])&(opcode[2])&(opcode[1])&(opcode[0]); //00111
	 
	 assign rd = instruction[26:22]; //destination register
	 assign rs = instruction[21:17]; // source register
	 assign rt = instruction[16:12]; // target ("second source") register
	 assign immediate = instruction[15:0]; // get immediate in the case of an I type instruction
	 assign immediate_sx = (instruction[16] == 1'b1) ? {16'b1111111111111111, immediate} : {16'b0000000000000000, immediate}; // immediate sx adjusted
	 assign shamt = isAddi ? 5'b0 : instruction[11:7]; //shift amount
	 assign ctrl_readRegA = rs; 
	 assign ctrl_readRegB = rt;
	 
	 
	 
	 assign ALU_readB = isAddi ? immediate_sx : data_readRegB; // Adjusts the second input to the addi_constant if necessary
	 
	 //Execute ALU
	 alu alu_operation(
        .data_operandA(data_readRegA),      
        .data_operandB(ALU_readB), 
        .ctrl_ALUopcode(ALUop),       
        .ctrl_shiftamt(shamt),        
        .data_result(alu_result),           
        .isNotEqual(isNotEqual),
        .isLessThan(isLessThan),
        .overflow(overflow_alu)
    );
	 
	 // ctrl_writeReg is $rstate ($31) is overflow, else it is $rd
	 assign ctrl_writeReg = overflow_alu ? 5'd31 : rd;
	 // if overflow, then set if add, sub, or addi. else 0
	 assign rStatus = overflow_alu ? (isAdd? 32'd1 : (isSub ? 32'd3 : 32'd2)) : 32'd0;
	 //overwrite writeReg if overflow detected, q_dmem if Rwd is true, and the original data_writeReg if neither 
	 assign write_data_reg = overflow_alu ? rStatus : (Rwd ? q_dmem : alu_result);
	 assign data_writeReg = write_data_reg;
	 
	 assign address_dmem = data_writeReg[11:0];
	 assign data = data_readRegB;
	 assign wren = DMwe; // this is what separates lw and sw (lw = 0, sw = 1)
	  
	 
endmodule