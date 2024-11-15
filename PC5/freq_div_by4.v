//sourced from https://referencedesigner.com/tutorials/verilogexamples/verilog_ex_03.php as given
module freq_div_by4 (clk, reset, clk_out);

    input clk;
    input reset;
    output reg clk_out;

    reg [1:0] count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 2'b00;
            clk_out <= 1'b0;
        end else begin
            count <= count + 1;
            if (count == 2'b11)
                clk_out <= ~clk_out;
        end
    end

endmodule
