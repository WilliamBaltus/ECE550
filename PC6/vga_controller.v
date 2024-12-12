module vga_controller(
    // I/O Port Declarations
    iRST_n,
    iVGA_CLK,
    oBLANK_n,
    oHS,
    oVS,
    b_data,
    g_data,
    r_data,
    move_up,
    move_down,
    move_left,
    move_right
);

//=======================================================
// Interface Declarations
//=======================================================
input iRST_n;
input iVGA_CLK;
input move_up, move_down, move_left, move_right;
output reg oBLANK_n;
output reg oHS;
output reg oVS;
output [7:0] b_data;
output [7:0] g_data; 
output [7:0] r_data;                        

//=======================================================
// VGA Signal Registers and Wires
//=======================================================
reg [18:0] ADDR;
reg [23:0] bgr_data;
wire VGA_CLK_n;
wire [7:0] index;
wire [23:0] bgr_data_raw;
wire cBLANK_n, cHS, cVS, rst;
assign rst = ~iRST_n;
assign VGA_CLK_n = ~iVGA_CLK;

//=======================================================
// Game State Registers
//=======================================================
// Grid and Collision Detection
reg [143:0] grid_occupancy;  // One bit per grid position
reg [3:0] snake_x [0:141];   // Snake segments X positions
reg [3:0] snake_y [0:141];   // Snake segments Y positions
reg [7:0] snake_length;      // Current length of snake
reg [1:0] food_zone;  // 00: top, 01: middle, 10: bottom
reg [3:0] next_x;     // Added: Next head position
reg [3:0] next_y;     // Added: Next head position
reg [7:0] zone_start, zone_end; // Define zone boundaries based on current food_zone
reg [4:0] zone_sequence_index;  // Track which of the 16 zones we're trying
reg [3:0] zone_x, zone_y;  // Current zone coordinates
reg [3:0] check_x, check_y;  // For food placement calculations
reg [7:0] x_start, x_end, y_start, y_end;


// Game Control
reg [21:0] move_counter;
reg [1:0] current_direction; // 00:up, 01:right, 10:down, 11:left
reg game_over;
reg game_started;
reg game_won;
reg initial_move_made;  // Flag to track first movement


// Food State
reg [3:0] food_x;
reg [3:0] food_y;
reg need_new_food;

// Loop variable
integer i;

//=======================================================
// Display Constants
//=======================================================
localparam BLOCK_SIZE = 30;
localparam GRID_SIZE = 12;
localparam GRID_LEFT = 160;
localparam GRID_TOP = 80;

//=======================================================
// Initial State
//=======================================================
initial begin
    // Snake initialization
    snake_x[0] = 4'd6;
    snake_y[0] = 4'd6;
    snake_length = 8'd1;
    current_direction = 2'b01;
    move_counter = 0;
    game_over = 1'b0;
    game_started = 1'b0;
    game_won = 1'b0;
    food_x = 4'd2;
    food_y = 4'd2;
    need_new_food = 1'b0;
    grid_occupancy = 144'b0;
    grid_occupancy[6 * 12 + 6] = 1'b1; // Initial snake position
    grid_occupancy[2 * 12 + 2] = 1'b1; // Initial food position
    food_zone = 2'b00;  // Start with top zone
	 initial_move_made = 1'b0;
end

//=======================================================
// VGA Signal Generation
//=======================================================
video_sync_generator LTM_ins (
    .vga_clk(iVGA_CLK),
    .reset(rst),
    .blank_n(cBLANK_n),
    .HS(cHS),
    .VS(cVS)
);

always @(posedge iVGA_CLK or negedge iRST_n) begin
    if (!iRST_n)
        ADDR <= 19'd0;
    else if (cHS == 1'b0 && cVS == 1'b0)
        ADDR <= 19'd0;
    else if (cBLANK_n == 1'b1)
        ADDR <= ADDR + 1;
end

img_data img_data_inst (
    .address(ADDR),
    .clock(VGA_CLK_n),
    .q(index)
);

img_index img_index_inst (
    .address(index),
    .clock(iVGA_CLK),
    .q(bgr_data_raw)
);

always @(posedge VGA_CLK_n)
    bgr_data <= bgr_data_raw;

//=======================================================
// Game Logic and Movement
//=======================================================
always @(posedge iVGA_CLK) begin
    if (!iRST_n) begin
        // Reset all game state
        current_direction <= 2'b01;
        move_counter <= 0;
        game_started <= 1'b0;
        game_over <= 1'b0;
        game_won <= 1'b0;
        snake_length <= 8'd1;
        need_new_food <= 1'b0;
        food_zone <= 2'b00;
        
        // Reset positions
        snake_x[0] <= 4'd6;
        snake_y[0] <= 4'd6;
        food_x <= 4'd2;
        food_y <= 4'd2;
        
        // Reset grid
        grid_occupancy <= 144'b0;
        grid_occupancy[6 * 12 + 6] <= 1'b1; // Initial snake position
        grid_occupancy[2 * 12 + 2] <= 1'b1; // Initial food position
		  
		  initial_move_made <= 1'b0;

    end
    else begin
        // Game start detection
        if (!game_started && (move_up || move_down || move_left || move_right)) begin
            game_started <= 1'b1;
            
        end
            
        // Direction updates
        if (!game_over && game_started) begin
		  
				if (!initial_move_made) begin
					grid_occupancy[snake_y[0] * 12 + snake_x[0]] <= 1'b0;
					initial_move_made <= 1'b1;
			  end
		  
            if (move_up && current_direction != 2'b10)
                current_direction <= 2'b00;
            else if (move_right && current_direction != 2'b11)
                current_direction <= 2'b01;
            else if (move_down && current_direction != 2'b00)
                current_direction <= 2'b10;
            else if (move_left && current_direction != 2'b01)
                current_direction <= 2'b11;
        end

        // Movement and collision logic
        if (move_counter == 22'd99999999) begin
            move_counter <= 0;
            
            if (!game_over && game_started) begin
					 // Calculate next head position
					 next_x = snake_x[0];
					 next_y = snake_y[0];
                
                case (current_direction)
                    2'b00: next_y = (snake_y[0] > 0) ? snake_y[0] - 1 : snake_y[0];
                    2'b01: next_x = (snake_x[0] < 11) ? snake_x[0] + 1 : snake_x[0];
                    2'b10: next_y = (snake_y[0] < 11) ? snake_y[0] + 1 : snake_y[0];
                    2'b11: next_x = (snake_x[0] > 0) ? snake_x[0] - 1 : snake_x[0];
                endcase

                // Check collisions
                if (next_x == snake_x[0] && next_y == snake_y[0]) begin
                    game_over <= 1'b1;
                end
                else if (grid_occupancy[next_y * 12 + next_x] && !(next_x == food_x && next_y == food_y)) begin
                    game_over <= 1'b1;
                end
                else begin
                    // Clear tail position in grid
                    grid_occupancy[snake_y[snake_length-1] * 12 + snake_x[snake_length-1]] <= 1'b0;
                    
                    // Move body in chunks
                    for (i = 48; i >= 0; i = i - 1) begin
                        if (i < snake_length) begin
                            snake_x[i+1] <= snake_x[i];
                            snake_y[i+1] <= snake_y[i];
                        end
                    end
                    
                    for (i = 97; i >= 49; i = i - 1) begin
                        if (i < snake_length) begin
                            snake_x[i+1] <= snake_x[i];
                            snake_y[i+1] <= snake_y[i];
                        end
                    end
                    
                    for (i = 140; i >= 98; i = i - 1) begin
                        if (i < snake_length) begin
                            snake_x[i+1] <= snake_x[i];
                            snake_y[i+1] <= snake_y[i];
                        end
                    end

                    // Move head
                    snake_x[0] <= next_x;
                    snake_y[0] <= next_y;
                    grid_occupancy[next_y * 12 + next_x] <= 1'b1;

                    // Check for food collision
                    if (next_x == food_x && next_y == food_y) begin
                        if (snake_length < 8'd141) begin
                            snake_length <= snake_length + 1;
                            need_new_food <= 1'b1;
                        end
                        else begin
                            game_won <= 1'b1;
                        end
                    end
                end
            end

            // Modify food spawning logic
				if (need_new_food && !game_over && !game_won) begin
					 reg found_spot;
					 found_spot = 0;

					 // Calculate current zone based on sequence
					 case(zone_sequence_index)
						  5'd0:  begin zone_x = 0; zone_y = 0; end  // Top-left
						  5'd1:  begin zone_x = 2; zone_y = 2; end  // Middle-right
						  5'd2:  begin zone_x = 1; zone_y = 3; end  // Bottom-middle-left
						  5'd3:  begin zone_x = 3; zone_y = 1; end  // Upper-middle-right
						  5'd4:  begin zone_x = 0; zone_y = 2; end  // Middle-left
						  5'd5:  begin zone_x = 2; zone_y = 0; end  // Top-middle-right
						  5'd6:  begin zone_x = 1; zone_y = 1; end  // Upper-middle-left
						  5'd7:  begin zone_x = 3; zone_y = 3; end  // Bottom-right
						  5'd8:  begin zone_x = 2; zone_y = 1; end  // Upper-middle-right
						  5'd9:  begin zone_x = 0; zone_y = 3; end  // Bottom-left
						  5'd10: begin zone_x = 3; zone_y = 0; end  // Top-right
						  5'd11: begin zone_x = 1; zone_y = 2; end  // Middle-middle-left
						  5'd12: begin zone_x = 2; zone_y = 3; end  // Bottom-middle-right
						  5'd13: begin zone_x = 0; zone_y = 1; end  // Upper-middle-left
						  5'd14: begin zone_x = 3; zone_y = 2; end  // Middle-right
						  5'd15: begin zone_x = 1; zone_y = 0; end  // Top-middle-left
					 endcase

					 // Calculate zone boundaries
					 x_start = zone_x * 3;  // Each zone is 3x3
					 x_end = x_start + 3;
					 y_start = zone_y * 3;
					 y_end = y_start + 3;

					 // Check this zone for open spots (max 9 iterations)
					 for (i = 0; i < 9 && !found_spot; i = i + 1) begin
						  check_x = x_start + (i % 3);
						  check_y = y_start + (i / 3);
						  if (!grid_occupancy[check_y * 12 + check_x]) begin
								food_x <= check_x;
								food_y <= check_y;
								grid_occupancy[check_y * 12 + check_x] <= 1'b1;
								need_new_food <= 1'b0;
								found_spot = 1;
						  end
					 end

					 // Move to next zone if no spot found
					 if (!found_spot) begin
						  zone_sequence_index <= (zone_sequence_index == 5'd15) ? 5'd0 : zone_sequence_index + 1;
					 end
				end
        end 
        else begin
            move_counter <= move_counter + 1;
        end
    end
end

//=======================================================
// Display Logic
//=======================================================
wire [9:0] pixel_x = ADDR % 640;
wire [8:0] pixel_y = ADDR / 640;

// Grid boundary detection
reg is_red_boundary;
always @(*) begin
    is_red_boundary = 0;
    if ((pixel_x >= GRID_LEFT && pixel_x < GRID_LEFT + GRID_SIZE * BLOCK_SIZE && 
         (pixel_y == GRID_TOP || pixel_y == GRID_TOP + GRID_SIZE * BLOCK_SIZE)) || 
        (pixel_y >= GRID_TOP && pixel_y < GRID_TOP + GRID_SIZE * BLOCK_SIZE && 
         (pixel_x == GRID_LEFT || pixel_x == GRID_LEFT + GRID_SIZE * BLOCK_SIZE))) 
    begin
        is_red_boundary = 1;
    end
end

// Simplified snake and food detection
reg is_snake;
reg is_food;
reg [3:0] grid_x;
reg [3:0] grid_y;

always @(*) begin
    grid_x = (pixel_x - GRID_LEFT) / BLOCK_SIZE;
    grid_y = (pixel_y - GRID_TOP) / BLOCK_SIZE;
    
    is_snake = 0;
    is_food = 0;
    
    if (pixel_x >= GRID_LEFT && pixel_x < GRID_LEFT + GRID_SIZE * BLOCK_SIZE &&
        pixel_y >= GRID_TOP && pixel_y < GRID_TOP + GRID_SIZE * BLOCK_SIZE) begin
        
        if (grid_x == food_x && grid_y == food_y)
            is_food = 1;
        else if (grid_occupancy[grid_y * 12 + grid_x])
            is_snake = 1;
    end
end

//=======================================================
// Color Assignment
//=======================================================
assign b_data = is_snake ? (game_over ? 8'h00 : game_won ? 8'h00 : 8'hFF) : 
                is_food ? 8'h00 : 
                is_red_boundary ? 8'h00 : bgr_data[23:16];
assign g_data = is_snake ? (game_won ? 8'hFF : 8'h00) : 
                is_food ? 8'hFF : 
                is_red_boundary ? 8'h00 : bgr_data[15:8];
assign r_data = is_snake ? (game_over ? 8'hFF : 8'h00) : 
                is_food ? 8'h00 : 
                is_red_boundary ? 8'hFF : bgr_data[7:0];

//=======================================================
// VGA Output Assignment
//=======================================================
always @(negedge iVGA_CLK) begin
    oHS <= cHS;
    oVS <= cVS;
    oBLANK_n <= cBLANK_n;
end

endmodule
