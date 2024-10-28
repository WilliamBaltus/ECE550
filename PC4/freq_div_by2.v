//sourced from https://referencedesigner.com/tutorials/verilogexamples/verilog_ex_02.php as given 
module freq_div_by2 ( clk ,reset,clk_out );
output reg clk_out;
input clk ;
input reset;
always @(posedge clk)
begin
if (reset)
     clk_out <= 1'b0;
else
     clk_out <= ~clk_out;	
end
endmodule