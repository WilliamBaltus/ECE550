module vga_controller(
    // I/O Port Declarations
    input iRST_n,
    input iVGA_CLK,
    output reg oBLANK_n,
    output reg oHS,
    output reg oVS,
    output [7:0] b_data,
    output [7:0] g_data, 
    output [7:0] r_data,                        
    input move_up,
    input move_down,
    input move_left,
    input move_right,
	 input reset_game
);

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
reg [3:0] food_zone;          // 4 bits to represent 16 zones
reg [3:0] next_x;     // Next head position X
reg [3:0] next_y;     // Next head position Y
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

// Loop variables
integer i;
integer j;  // Additional loop variable for nested loop

//=======================================================
// Display Constants
//=======================================================
localparam BLOCK_SIZE = 30;
localparam GRID_SIZE = 12;
localparam GRID_LEFT = 160;
localparam GRID_TOP = 80;

// Seven Segment Display Constants
localparam SSD_WIDTH = 30;
localparam SSD_HEIGHT = 30;
// Define positions for three SSDs: SSD0 (Hundreds), SSD1 (Tens), SSD2 (Units)
localparam SSD0_LEFT = GRID_LEFT - 120;  // Hundreds digit
localparam SSD1_LEFT = GRID_LEFT - 80;  // Tens digit
localparam SSD2_LEFT = GRID_LEFT - 40;       // Units digit
localparam SSD_TOP = GRID_TOP;

//=======================================================
// Initial State
//=======================================================
initial begin
    // Snake initialization
    snake_x[0] = 4'd0;
    snake_y[0] = 4'd0;
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
    grid_occupancy[0 * 12 + 0] = 1'b1; // Initial snake position
    grid_occupancy[0 * 12 + 0] = 1'b1; // Initial food position
    food_zone = 4'b0000;  // Start with the first zone in the sequence
    initial_move_made = 1'b0;
    next_x = 4'd0;  // Initialize next_x to snake's initial X
    next_y = 4'd0;  // Initialize next_y to snake's initial Y
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
    if (!iRST_n || reset_game) begin
        // Reset all game state
        current_direction <= 2'b01;
        move_counter <= 0;
        game_started <= 1'b0;
        game_over <= 1'b0;
        game_won <= 1'b0;
        snake_length <= 8'd1;  
        need_new_food <= 1'b0;
        food_zone <= 4'b0000;  // 4-bit reset

        // Reset positions
        snake_x[0] <= 4'd0;
        snake_y[0] <= 4'd0;
        food_x <= 4'd2;
        food_y <= 4'd2;

        // Reset grid
        grid_occupancy <= 144'b0;
        grid_occupancy[0 * 12 + 0] <= 1'b1; // Initial snake position
        grid_occupancy[0 * 12 + 0] <= 1'b1; // Initial food position

        initial_move_made <= 1'b0;

        // Initialize next positions
        next_x <= 4'd0;  // Initialize next_x to snake's initial X
        next_y <= 4'd0;  // Initialize next_y to snake's initial Y
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
                // Calculate next head position based on current direction
                next_x = snake_x[0];
                next_y = snake_y[0];

                case (current_direction)
                    2'b00: next_y = (snake_y[0] > 0) ? snake_y[0] - 1 : snake_y[0]; // Up
                    2'b01: next_x = (snake_x[0] < 11) ? snake_x[0] + 1 : snake_x[0]; // Right
                    2'b10: next_y = (snake_y[0] < 11) ? snake_y[0] + 1 : snake_y[0]; // Down
                    2'b11: next_x = (snake_x[0] > 0) ? snake_x[0] - 1 : snake_x[0]; // Left
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
                    if (snake_length > 0)
                        grid_occupancy[snake_y[snake_length-1] * 12 + snake_x[snake_length-1]] <= 1'b0;

                    // Move body segments
                    for (i = 141; i > 0; i = i - 1) begin
                        if (i < snake_length) begin
                            snake_x[i] <= snake_x[i-1];
                            snake_y[i] <= snake_y[i-1];
                        end
                    end

                    // Move head to new position
                    snake_x[0] <= next_x;
                    snake_y[0] <= next_y;
                    grid_occupancy[next_y * 12 + next_x] <= 1'b1;

                    // Check for food collision
                    if (next_x == food_x && next_y == food_y) begin
                        if (snake_length < 8'd143) begin  // Updated WIN CONDITION LENGTH
                            snake_length <= snake_length + 1;
                            need_new_food <= 1'b1;
                        end
                        else begin
                            game_won <= 1'b1;
                        end
                    end
                end
            end
				// Food spawning logic with zone cycling
				// 0  1  2  3
				// 4  5  6  7
				// 8  9 10 11
				// 12 13 14 15
				//8 -> 3 -> 15 -> 0 -> 7 -> 12 -> 2 -> 10 -> 5 -> 14 -> 1 -> 9 -> 4 -> 13 -> 6 -> 11
				if (need_new_food && !game_over && !game_won) begin
					 reg found_spot;
					 found_spot = 0;

					 // Calculate base position for each 3x3 area
					 // Using sequence: 8,3,15,0,7,12,2,10,5,14,1,9,4,13,6,11
					 case(food_zone)
						  // Format: row = (n/4)*3, col = (n%4)*3
						  4'd0:  zone_start = (2*12 + 0);     // Area 8  (row 2, col 0)
						  4'd1:  zone_start = (0*12 + 9);     // Area 3  (row 0, col 3)
						  4'd2:  zone_start = (3*12 + 9);     // Area 15 (row 3, col 3)
						  4'd3:  zone_start = (0*12 + 0);     // Area 0  (row 0, col 0)
						  4'd4:  zone_start = (1*12 + 9);     // Area 7  (row 1, col 3)
						  4'd5:  zone_start = (3*12 + 0);     // Area 12 (row 3, col 0)
						  4'd6:  zone_start = (0*12 + 6);     // Area 2  (row 0, col 2)
						  4'd7:  zone_start = (2*12 + 6);     // Area 10 (row 2, col 2)
						  4'd8:  zone_start = (1*12 + 3);     // Area 5  (row 1, col 1)
						  4'd9:  zone_start = (3*12 + 6);     // Area 14 (row 3, col 2)
						  4'd10: zone_start = (0*12 + 3);     // Area 1  (row 0, col 1)
						  4'd11: zone_start = (2*12 + 3);     // Area 9  (row 2, col 1)
						  4'd12: zone_start = (1*12 + 0);     // Area 4  (row 1, col 0)
						  4'd13: zone_start = (3*12 + 3);     // Area 13 (row 3, col 1)
						  4'd14: zone_start = (1*12 + 6);     // Area 6  (row 1, col 2)
						  4'd15: zone_start = (2*12 + 9);     // Area 11 (row 2, col 3)
						  default: zone_start = 0;
					 endcase

					 // Check 3x3 cells in current area
					for (i = 0; i < 3 && !found_spot; i = i + 1) begin
						 for (j = 0; j < 3 && !found_spot; j = j + 1) begin
							  if (!grid_occupancy[zone_start + i * 12 + j]) begin
									food_x <= (zone_start % 12) + j;     // Keep the column offset from zone_start
									food_y <= (zone_start / 12) + i;     // Add row offset
									grid_occupancy[zone_start + i * 12 + j] <= 1'b1;
									need_new_food <= 1'b0;
									found_spot = 1'b1;
									food_zone <= (food_zone == 4'd15) ? 4'd0 : food_zone + 1;
							  end
						 end
					end

					 // If no spot found in current area, move to next
					 if (!found_spot) begin
						  food_zone <= (food_zone == 4'd15) ? 4'd0 : food_zone + 1;
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
    if (
        (pixel_x >= GRID_LEFT && pixel_x < GRID_LEFT + GRID_SIZE * BLOCK_SIZE && 
         (pixel_y == GRID_TOP || pixel_y == GRID_TOP + GRID_SIZE * BLOCK_SIZE)) || 
        (pixel_y >= GRID_TOP && pixel_y < GRID_TOP + GRID_SIZE * BLOCK_SIZE && 
         (pixel_x == GRID_LEFT || pixel_x == GRID_LEFT + GRID_SIZE * BLOCK_SIZE))
    ) begin
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

    if (
        pixel_x >= GRID_LEFT && pixel_x < GRID_LEFT + GRID_SIZE * BLOCK_SIZE &&
        pixel_y >= GRID_TOP && pixel_y < GRID_TOP + GRID_SIZE * BLOCK_SIZE
    ) begin
        if (grid_x == food_x && grid_y == food_y)
            is_food = 1;
        else if (grid_occupancy[grid_y * 12 + grid_x])
            is_snake = 1;
    end
end

//=======================================================
// Seven Segment Display Logic
//=======================================================

// Digit Registers
reg [3:0] display_digit0; // Units
reg [3:0] display_digit1; // Tens
reg [3:0] display_digit2; // Hundreds

// Extract digits from snake_length
always @(posedge iVGA_CLK) begin
    if (snake_length < 10) begin
        display_digit2 <= 4'd0;
        display_digit1 <= 4'd0;
        display_digit0 <= snake_length;
    end
    else if (snake_length < 100) begin
        display_digit2 <= 4'd0;
        display_digit1 <= snake_length / 10;
        display_digit0 <= snake_length % 10;
    end
    else begin
        display_digit2 <= snake_length / 100;
        display_digit1 <= (snake_length / 10) % 10;
        display_digit0 <= snake_length % 10;
    end
end

// Seven Segment Decoder for Hundreds (SSD0)
reg [6:0] ssd_segments0;
always @(*) begin
    case(display_digit2)
        4'd0: ssd_segments0 = 7'b1111110; // 0
        4'd1: ssd_segments0 = 7'b0110000; // 1
        4'd2: ssd_segments0 = 7'b1101101; // 2
        4'd3: ssd_segments0 = 7'b1111001; // 3
        4'd4: ssd_segments0 = 7'b0110011; // 4
        4'd5: ssd_segments0 = 7'b1011011; // 5
        4'd6: ssd_segments0 = 7'b1011111; // 6
        4'd7: ssd_segments0 = 7'b1110000; // 7
        4'd8: ssd_segments0 = 7'b1111111; // 8
        4'd9: ssd_segments0 = 7'b1111011; // 9
        default: ssd_segments0 = 7'b0000000; // All segments off
    endcase
end

// Seven Segment Decoder for Tens (SSD1)
reg [6:0] ssd_segments1;
always @(*) begin
    case(display_digit1)
        4'd0: ssd_segments1 = 7'b1111110; // 0
        4'd1: ssd_segments1 = 7'b0110000; // 1
        4'd2: ssd_segments1 = 7'b1101101; // 2
        4'd3: ssd_segments1 = 7'b1111001; // 3
        4'd4: ssd_segments1 = 7'b0110011; // 4
        4'd5: ssd_segments1 = 7'b1011011; // 5
        4'd6: ssd_segments1 = 7'b1011111; // 6
        4'd7: ssd_segments1 = 7'b1110000; // 7
        4'd8: ssd_segments1 = 7'b1111111; // 8
        4'd9: ssd_segments1 = 7'b1111011; // 9
        default: ssd_segments1 = 7'b0000000; // All segments off
    endcase
end

// Seven Segment Decoder for Units (SSD2)
reg [6:0] ssd_segments2;
always @(*) begin
    case(display_digit0)
        4'd0: ssd_segments2 = 7'b1111110; // 0
        4'd1: ssd_segments2 = 7'b0110000; // 1
        4'd2: ssd_segments2 = 7'b1101101; // 2
        4'd3: ssd_segments2 = 7'b1111001; // 3
        4'd4: ssd_segments2 = 7'b0110011; // 4
        4'd5: ssd_segments2 = 7'b1011011; // 5
        4'd6: ssd_segments2 = 7'b1011111; // 6
        4'd7: ssd_segments2 = 7'b1110000; // 7
        4'd8: ssd_segments2 = 7'b1111111; // 8
        4'd9: ssd_segments2 = 7'b1111011; // 9
        default: ssd_segments2 = 7'b0000000; // All segments off
    endcase
end

// Seven Segment Display Detection for SSD0 (Hundreds)
reg is_ssd0;
wire [4:0] ssd0_pixel_x = pixel_x - SSD0_LEFT;
wire [4:0] ssd0_pixel_y = pixel_y - SSD_TOP;

always @(*) begin
    is_ssd0 = 0;
    if (
        pixel_x >= SSD0_LEFT && pixel_x < SSD0_LEFT + SSD_WIDTH &&
        pixel_y >= SSD_TOP && pixel_y < SSD_TOP + SSD_HEIGHT
    ) begin
        is_ssd0 = 1;
    end
end

// Define segment boundaries within SSD0 area
wire a_on0 = (ssd0_pixel_y >= 0 && ssd0_pixel_y < 5) && (ssd0_pixel_x >= 5 && ssd0_pixel_x < SSD_WIDTH - 5);
wire b_on0 = (ssd0_pixel_x >= SSD_WIDTH - 5 && ssd0_pixel_x < SSD_WIDTH) && (ssd0_pixel_y >= 5 && ssd0_pixel_y < SSD_HEIGHT / 2);
wire c_on0 = (ssd0_pixel_x >= SSD_WIDTH - 5 && ssd0_pixel_x < SSD_WIDTH) && (ssd0_pixel_y >= SSD_HEIGHT / 2 && ssd0_pixel_y < SSD_HEIGHT - 5);
wire d_on0 = (ssd0_pixel_y >= SSD_HEIGHT - 5 && ssd0_pixel_y < SSD_HEIGHT) && (ssd0_pixel_x >= 5 && ssd0_pixel_x < SSD_WIDTH - 5);
wire e_on0 = (ssd0_pixel_x >= 0 && ssd0_pixel_x < 5) && (ssd0_pixel_y >= SSD_HEIGHT / 2 && ssd0_pixel_y < SSD_HEIGHT - 5);
wire f_on0 = (ssd0_pixel_x >= 0 && ssd0_pixel_x < 5) && (ssd0_pixel_y >= 5 && ssd0_pixel_y < SSD_HEIGHT / 2);
wire g_on0 = (ssd0_pixel_y >= SSD_HEIGHT / 2 - 2 && ssd0_pixel_y < SSD_HEIGHT / 2 + 2) && (ssd0_pixel_x >= 5 && ssd0_pixel_x < SSD_WIDTH - 5);

// Determine if the current pixel should light up for SSD0
wire ssd_pixel0 = (a_on0 && ssd_segments0[6]) ||
                  (b_on0 && ssd_segments0[5]) ||
                  (c_on0 && ssd_segments0[4]) ||
                  (d_on0 && ssd_segments0[3]) ||
                  (e_on0 && ssd_segments0[2]) ||
                  (f_on0 && ssd_segments0[1]) ||
                  (g_on0 && ssd_segments0[0]);

// Seven Segment Display Detection for SSD1 (Tens)
reg is_ssd1;
wire [4:0] ssd1_pixel_x = pixel_x - SSD1_LEFT;
wire [4:0] ssd1_pixel_y = pixel_y - SSD_TOP;

always @(*) begin
    is_ssd1 = 0;
    if (
        pixel_x >= SSD1_LEFT && pixel_x < SSD1_LEFT + SSD_WIDTH &&
        pixel_y >= SSD_TOP && pixel_y < SSD_TOP + SSD_HEIGHT
    ) begin
        is_ssd1 = 1;
    end
end

// Define segment boundaries within SSD1 area
wire a_on1 = (ssd1_pixel_y >= 0 && ssd1_pixel_y < 5) && (ssd1_pixel_x >= 5 && ssd1_pixel_x < SSD_WIDTH - 5);
wire b_on1 = (ssd1_pixel_x >= SSD_WIDTH - 5 && ssd1_pixel_x < SSD_WIDTH) && (ssd1_pixel_y >= 5 && ssd1_pixel_y < SSD_HEIGHT / 2);
wire c_on1 = (ssd1_pixel_x >= SSD_WIDTH - 5 && ssd1_pixel_x < SSD_WIDTH) && (ssd1_pixel_y >= SSD_HEIGHT / 2 && ssd1_pixel_y < SSD_HEIGHT - 5);
wire d_on1 = (ssd1_pixel_y >= SSD_HEIGHT - 5 && ssd1_pixel_y < SSD_HEIGHT) && (ssd1_pixel_x >= 5 && ssd1_pixel_x < SSD_WIDTH - 5);
wire e_on1 = (ssd1_pixel_x >= 0 && ssd1_pixel_x < 5) && (ssd1_pixel_y >= SSD_HEIGHT / 2 && ssd1_pixel_y < SSD_HEIGHT - 5);
wire f_on1 = (ssd1_pixel_x >= 0 && ssd1_pixel_x < 5) && (ssd1_pixel_y >= 5 && ssd1_pixel_y < SSD_HEIGHT / 2);
wire g_on1 = (ssd1_pixel_y >= SSD_HEIGHT / 2 - 2 && ssd1_pixel_y < SSD_HEIGHT / 2 + 2) && (ssd1_pixel_x >= 5 && ssd1_pixel_x < SSD_WIDTH - 5);

// Determine if the current pixel should light up for SSD1
wire ssd_pixel1 = (a_on1 && ssd_segments1[6]) ||
                  (b_on1 && ssd_segments1[5]) ||
                  (c_on1 && ssd_segments1[4]) ||
                  (d_on1 && ssd_segments1[3]) ||
                  (e_on1 && ssd_segments1[2]) ||
                  (f_on1 && ssd_segments1[1]) ||
                  (g_on1 && ssd_segments1[0]);

// Seven Segment Display Detection for SSD2 (Units)
reg is_ssd2;
wire [4:0] ssd2_pixel_x = pixel_x - SSD2_LEFT;
wire [4:0] ssd2_pixel_y = pixel_y - SSD_TOP;

always @(*) begin
    is_ssd2 = 0;
    if (
        pixel_x >= SSD2_LEFT && pixel_x < SSD2_LEFT + SSD_WIDTH &&
        pixel_y >= SSD_TOP && pixel_y < SSD_TOP + SSD_HEIGHT
    ) begin
        is_ssd2 = 1;
    end
end

// Define segment boundaries within SSD2 area
wire a_on2 = (ssd2_pixel_y >= 0 && ssd2_pixel_y < 5) && (ssd2_pixel_x >= 5 && ssd2_pixel_x < SSD_WIDTH - 5);
wire b_on2 = (ssd2_pixel_x >= SSD_WIDTH - 5 && ssd2_pixel_x < SSD_WIDTH) && (ssd2_pixel_y >= 5 && ssd2_pixel_y < SSD_HEIGHT / 2);
wire c_on2 = (ssd2_pixel_x >= SSD_WIDTH - 5 && ssd2_pixel_x < SSD_WIDTH) && (ssd2_pixel_y >= SSD_HEIGHT / 2 && ssd2_pixel_y < SSD_HEIGHT - 5);
wire d_on2 = (ssd2_pixel_y >= SSD_HEIGHT - 5 && ssd2_pixel_y < SSD_HEIGHT) && (ssd2_pixel_x >= 5 && ssd2_pixel_x < SSD_WIDTH - 5);
wire e_on2 = (ssd2_pixel_x >= 0 && ssd2_pixel_x < 5) && (ssd2_pixel_y >= SSD_HEIGHT / 2 && ssd2_pixel_y < SSD_HEIGHT - 5);
wire f_on2 = (ssd2_pixel_x >= 0 && ssd2_pixel_x < 5) && (ssd2_pixel_y >= 5 && ssd2_pixel_y < SSD_HEIGHT / 2);
wire g_on2 = (ssd2_pixel_y >= SSD_HEIGHT / 2 - 2 && ssd2_pixel_y < SSD_HEIGHT / 2 + 2) && (ssd2_pixel_x >= 5 && ssd2_pixel_x < SSD_WIDTH - 5);

// Determine if the current pixel should light up for SSD2
wire ssd_pixel2 = (a_on2 && ssd_segments2[6]) ||
                  (b_on2 && ssd_segments2[5]) ||
                  (c_on2 && ssd_segments2[4]) ||
                  (d_on2 && ssd_segments2[3]) ||
                  (e_on2 && ssd_segments2[2]) ||
                  (f_on2 && ssd_segments2[1]) ||
                  (g_on2 && ssd_segments2[0]);

// Combine SSD pixel signals
wire any_ssd_pixel = ssd_pixel0 || ssd_pixel1 || ssd_pixel2;

//=======================================================
// Color Assignment
//=======================================================
// Assign colors based on SSDs, snake, food, and boundaries
// Ensure only one assign statement per color channel
assign b_data = (ssd_pixel0 && is_ssd0) ? 8'hFF :
                (ssd_pixel1 && is_ssd1) ? 8'hFF :
                (ssd_pixel2 && is_ssd2) ? 8'hFF :
                is_snake ? (game_over ? 8'h00 : game_won ? 8'h00 : 8'hFF) : 
                is_food ? 8'h00 : 
                is_red_boundary ? 8'h00 : 
                bgr_data[23:16];

assign g_data = (ssd_pixel0 && is_ssd0) ? 8'h00 :
                (ssd_pixel1 && is_ssd1) ? 8'h00 :
                (ssd_pixel2 && is_ssd2) ? 8'h00 :
                is_snake ? (game_won ? 8'hFF : 8'h00) : 
                is_food ? 8'hFF : 
                is_red_boundary ? 8'h00 : 
                bgr_data[15:8];

assign r_data = (ssd_pixel0 && is_ssd0) ? 8'hFF :
                (ssd_pixel1 && is_ssd1) ? 8'hFF :
                (ssd_pixel2 && is_ssd2) ? 8'hFF :
                is_snake ? (game_over ? 8'hFF : 8'h00) : 
                is_food ? 8'h00 : 
                is_red_boundary ? 8'hFF : 
                bgr_data[7:0];

//=======================================================
// VGA Output Assignment
//=======================================================
always @(negedge iVGA_CLK) begin
    oHS <= cHS;
    oVS <= cVS;
    oBLANK_n <= cBLANK_n;
end

endmodule
