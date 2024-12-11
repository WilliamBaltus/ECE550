module processor(clock, reset, /*ps2_key_pressed, ps2_out, lcd_write, lcd_data,*/ dmem_data_in, dmem_address);

	input 			clock, reset/*, ps2_key_pressed*/;
	//input 	[7:0]	ps2_out;
	
	//output 			lcd_write;
	//output 	[31:0] 	lcd_data;
	
	// GRADER OUTPUTS - YOU MUST CONNECT TO YOUR DMEM
	output 	[31:0] 	dmem_data_in;
	output	[11:0]	dmem_address;
	
	
	// your processor here
	//
	
	//////////////////////////////////////
	////// THIS IS REQUIRED FOR GRADING
	// CHANGE THIS TO ASSIGN YOUR DMEM WRITE ADDRESS ALSO TO debug_addr
	assign dmem_address = (12'b000000000001);
	// CHANGE THIS TO ASSIGN YOUR DMEM DATA INPUT (TO BE WRITTEN) ALSO TO debug_data
	assign dmem_data_in = (12'b000000000001);
	////////////////////////////////////////////////////////////
	
		
	// You'll need to change where the dmem and imem read and write...
	dmem mydmem(	.address	(dmem_address),
					.clock		(clock),
					.data		(debug_data),
					.wren		(1'b1) //,	//need to fix this!
					//.q			(wherever_you_want) // change where output q goes...
	);
	
	imem myimem(	.address 	(dmem_data_in),
					.clken		(1'b1),
					.clock		(clock) //,
					//.q			(wherever_you_want) // change where output q goes...
	); 
	
endmodule
