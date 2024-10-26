//sourced from https://referencedesigner.com/tutorials/verilogexamples/verilog_ex_02.php as given 
module freq_div_by2 ( clk ,rst,out_clk );
output reg out_clk;
input clk ;
input rst;
always @(posedge clk)
begin
if (~rst)
     out_clk <= 1'b0;
else
     out_clk <= ~out_clk;	
end
endmodule