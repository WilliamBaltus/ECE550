module PS2_Interface(
   input inclock, resetn,
   inout ps2_clock, ps2_data,
   output ps2_key_pressed,
   output [7:0] ps2_key_data,
   output  reg[7:0]   last_data_received,
   output reg move_up, move_down, move_left, move_right, reset_game
);


   // Internal Registers
   reg [7:0] ascii_data; // Internal register to store the mapped ASCII value
  
   // Mapping scan codes to both ASCII values and direction control signals for WASD keys
   always @(posedge inclock or negedge resetn) begin
       if (!resetn) begin
           move_up <= 1'b0;
           move_down <= 1'b0;
           move_left <= 1'b0;
           move_right <= 1'b0;
			  reset_game <= 1'b0;    // Initialize reset_game
           ascii_data <= 8'd32;  // Default to space character
       end
       else if (ps2_key_pressed) begin
           case (ps2_key_data)
					8'h2D: begin  // 'R' key
                   ascii_data <= 8'd82;  // ASCII for 'R'
                   move_up <= 1'b0;
                   move_down <= 1'b0;
                   move_left <= 1'b0;
                   move_right <= 1'b0;
                   reset_game <= 1'b1;   // Trigger reset
               end
               8'h1D: begin  // 'W' key
                   ascii_data <= 8'd87;  // ASCII for 'W'
                   move_up <= 1'b1;
                   move_down <= 1'b0;
                   move_left <= 1'b0;
                   move_right <= 1'b0;
						 reset_game <= 1'b0;
               end
               8'h1B: begin  // 'S' key
                   ascii_data <= 8'd83;  // ASCII for 'S'
                   move_up <= 1'b0;
                   move_down <= 1'b1;
                   move_left <= 1'b0;
                   move_right <= 1'b0;
						 reset_game <= 1'b0;
               end
               8'h1C: begin  // 'A' key
                   ascii_data <= 8'd65;  // ASCII for 'A'
                   move_up <= 1'b0;
                   move_down <= 1'b0;
                   move_left <= 1'b1;
                   move_right <= 1'b0;
						 reset_game <= 1'b0;
               end
               8'h23: begin  // 'D' key
                   ascii_data <= 8'd68;  // ASCII for 'D'
                   move_up <= 1'b0;
                   move_down <= 1'b0;
                   move_left <= 1'b0;
                   move_right <= 1'b1;
						 reset_game <= 1'b0;
               end
               default: begin  // Reset signals for any other key
                   ascii_data <= 8'd32;  // Space character
                   move_up <= 1'b0;
                   move_down <= 1'b0;
                   move_left <= 1'b0;
                   move_right <= 1'b0;
               end
           endcase
       end
   end


   // ASCII Mapping Logic: Add a small combinational logic block
   always @(posedge inclock) begin
       if (resetn == 1'b0)
           last_data_received <= 8'h00;
       else if (ps2_key_pressed == 1'b1)
           last_data_received <= ascii_data;
   end




   PS2_Controller PS2 (
       .CLOCK_50 (inclock),
       .reset (~resetn),
       .PS2_CLK (ps2_clock),
       .PS2_DAT (ps2_data),
       .received_data (ps2_key_data),
       .received_data_en (ps2_key_pressed)
   );


endmodule



