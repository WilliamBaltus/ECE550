module led_test(led_high,led_low,clk,rst_n,s0);
output[1:0] led_high;
output[1:0] led_low;
input clk,rst_n,s0;
reg[1:0] led_high,led_low;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		led_high <= 2'b00;
	else 
		led_high <= led_high+1'b1;
end

always @(*) begin
	case(s0)
		1'b0 : led_low <=2'b01;
		1'b1 : led_low <=2'b10;
		default:led_low <=2'b00;
	endcase
end

endmodule
