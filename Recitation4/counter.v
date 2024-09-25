module counter(clock,reset,w,state,trigger);
	input clock, reset, w;
	output reg trigger;
	output reg [2:0] state;
	reg[2:0] state_next;
	
	localparam[2:0] //moore states, up to 8 since 3 bit
		zeroMoore = 3'b000,
		oneMoore = 3'b001,
		twoMoore = 3'b010,
		threeMoore = 3'b011,
		fourMoore = 3'b100;
		
	//reset and clk handle
	always @(posedge clock, posedge reset) 
	begin
		if (reset) //go to zero
		begin
			state <= zeroMoore;
		end
		else //clock
			state <= state_next;
	end
	
	
	always @(*) 
begin
    case(state)
        zeroMoore:
            if(w)
                state_next <= oneMoore;
            else
                state_next <= zeroMoore; // Maintain current state if w is not asserted
        oneMoore:
            if(w)
                state_next <= twoMoore;
            else
                state_next <= oneMoore;
        twoMoore:
            if(w)
                state_next <= threeMoore;
            else
                state_next <= twoMoore;
        threeMoore:
            if(w)
                state_next <= fourMoore;
            else
                state_next <= threeMoore;
        fourMoore:
            if(w)
                state_next <= zeroMoore;
            else
                state_next <= fourMoore;
        default:
            state_next <= zeroMoore;
    endcase
end

	
	
	//output count
	always @ (*) 
	begin
		case(state)
			fourMoore:
				trigger <= 1'b1;
			default:
				trigger <= 1'b0;
		endcase
	end
		
endmodule
