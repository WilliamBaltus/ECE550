// set the timescale
`timescale 1 ns / 100 ps
module RCA_tb(); // testbenches take no arguments
 	// set up inputs of NAND gate as registers so they can be manipulated at will
 	reg [3:0]in1;
 	reg [3:0]in2;
	reg cin;
 	
 	// clocks are useful for testbenches because they allow you to check your
 	// circuit at regular intervals large enough for signals to propagate
 	reg clock;
 	
 	// set up output of NAND gate as wire
 	wire cout;
	wire [3:0] sum;
 	
 	// prepare any other variables you want - nothing is off-limits in a TB
 	integer num_errors;
 	
 	// instantiate the RCA 
// please make sure the module name and interface is same as declared
 	RCA_four_bit test_RCA (cin, in1, in2, cout, sum);
 	
 	// begin simulation
 	initial begin
       	$display($time, " simulation start");
       	
       	clock = 1'b0;
       	
       	       	
   @(negedge clock);
       	in1 = 4'b1101;
       	in2 = 4'b1000;
	      cin = 1'b1;
			$display("The sum is %b and the cout is %b", sum, cout);
	@(negedge clock); // wait for the clock to go negative
       	in1 = 4'b1010;
       	in2 = 4'b1001;
	      cin = 1'b0;
   @(negedge clock);
	      $stop;
	   
 	end
 	
 	always
       	#10 clock = ~clock; // toggle clock every 10 timescale units
 	
endmodule
