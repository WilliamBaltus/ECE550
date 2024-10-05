module sevensegment(
    input [3:0] in,
    output reg [6:0] display
);
    always @(*) begin
        case(in)
            0: display = 7'b1000000; 
            1: display = 7'b1111001; 
            2: display = 7'b0100100; 
            3: display = 7'b0110000; 
            4: display = 7'b0011001; 
            5: display = 7'b0010010; 
            6: display = 7'b0000010; 
            7: display = 7'b1111000; 
            8: display = 7'b0000000; 
            9: display = 7'b0010000; 
            default: display = 7'b1111111; // Blank
        endcase
    end
endmodule





/*
    A
    ------
   |      |
 F |      | B
   |   G  |
    ------
   |      |
 E |      | C
   |      |
    ------
      D
*/

/*
Bit 6 corresponds to segment A
Bit 5 corresponds to segment B
Bit 4 corresponds to segment C
Bit 3 corresponds to segment D
Bit 2 corresponds to segment E
Bit 1 corresponds to segment F
Bit 0 corresponds to segment G
*/
