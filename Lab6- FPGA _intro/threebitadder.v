module threebitadder(
    input [2:0] a, b,    
	  /*
	  a[0] = AB27/SW4 
	  a[1] = AC26/SW5
	  a[2] = AC24/SW10
	  b[0] = AD26/SW6
	  b[1] = AB26/SW7
	  b[2] = AB25/SW9
	  cin = AC25/SW8
	  */
    input cin,               
    output [6:0] HEX3, HEX1, HEX0, 
	 input [3:0] in2
);
    reg [3:0] sum, cout;           
    wire [3:0] upper_digit, lower_digit;

    always @(*) begin
		  cout <= 0;
        sum = a + b + cin;    
    end

    assign lower_digit = sum % 10;  // Lower digit (ones place)
    assign upper_digit = sum / 10;  // Upper digit (tens place)

    sevensegment sevensegment0(lower_digit, HEX0);
    sevensegment sevensegment1(upper_digit, HEX1);
    sevensegment sevensegment2(cin, HEX3);
endmodule
