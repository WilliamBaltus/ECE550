module vga_controller(
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

input iRST_n;
input iVGA_CLK;
input move_up, move_down, move_left, move_right;
output reg oBLANK_n;
output reg oHS;
output reg oVS;
output [7:0] b_data;
output [7:0] g_data; 
output [7:0] r_data;                        

reg [18:0] ADDR;
reg [23:0] bgr_data;
wire VGA_CLK_n;
wire [7:0] index;
wire [23:0] bgr_data_raw;
wire cBLANK_n, cHS, cVS, rst;

reg [143:0] occupancy_grid; // 12x12 grid = 144 bits

// Snake body position registers (4 segments)
reg [3:0] snake_x [0:3];
reg [3:0] snake_y [0:3];

// Food position
reg [3:0] food_x;
reg [3:0] food_y;

reg [20:0] move_counter = 0;    // Counter to control the speed of movement

assign rst = ~iRST_n;

// Declare loop variable outside always block
integer i; 
genvar j; 

video_sync_generator LTM_ins (
    .vga_clk(iVGA_CLK),
    .reset(rst),
    .blank_n(cBLANK_n),
    .HS(cHS),
    .VS(cVS)
);

// Address generator
always @(posedge iVGA_CLK or negedge iRST_n) begin
    if (!iRST_n)
        ADDR <= 19'd0;
    else if (cHS == 1'b0 && cVS == 1'b0)
        ADDR <= 19'd0;
    else if (cBLANK_n == 1'b1)
        ADDR <= ADDR + 1;
end

assign VGA_CLK_n = ~iVGA_CLK;

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

// Initialize snake body to a straight horizontal line
initial begin
    snake_x[0] = 4'd6;
    snake_y[0] = 4'd6;
    snake_x[1] = 4'd5;
    snake_y[1] = 4'd6;
    snake_x[2] = 4'd4;
    snake_y[2] = 4'd6;
    snake_x[3] = 4'd3;
    snake_y[3] = 4'd6;

    // Initialize food position to the first open position
    food_x = 4'd2;
    food_y = 4'd2;
end

// Update the position of the snake
always @(posedge iVGA_CLK) begin
    if (move_counter == 21'd9999999) begin // Move every set clock interval
        move_counter <= 0;
        
        // Shift the snake's body positions
        for (i = 3; i > 0; i = i - 1) begin
            snake_x[i] <= snake_x[i - 1];
            snake_y[i] <= snake_y[i - 1];
        end
        
        // Update the head position
        if (move_up && snake_y[0] > 0) 
            snake_y[0] <= snake_y[0] - 1;
        if (move_down && snake_y[0] < 11) 
            snake_y[0] <= snake_y[0] + 1;
        if (move_left && snake_x[0] > 0) 
            snake_x[0] <= snake_x[0] - 1;
        if (move_right && snake_x[0] < 11) 
            snake_x[0] <= snake_x[0] + 1;
    end else begin
        move_counter <= move_counter + 1;
    end
end

// Update occupancy grid based on snake body and food position
always @(posedge iVGA_CLK or negedge iRST_n) begin
    if (!iRST_n) 
        occupancy_grid <= 144'b0;
    else begin
        // Clear the occupancy grid
        occupancy_grid <= 144'b0;

        // Mark snake body positions as occupied
        for (i = 0; i < 4; i = i + 1) begin
            occupancy_grid[snake_y[i] * 12 + snake_x[i]] <= 1'b1;
        end
        
        // Mark food position as occupied
        occupancy_grid[food_y * 12 + food_x] <= 1'b1;
    end
end

// Randomly spawn new food periodically
always @(posedge iVGA_CLK) begin : loop_block
    if (move_counter == 21'd0) begin
        // Find the first open position for new food
        for (i = 0; i < 144; i = i + 1) begin
            if (!occupancy_grid[i]) begin
                food_x <= i % 12;
                food_y <= i / 12;
                disable loop_block; // End the loop
            end
        end
    end
end

wire [9:0] pixel_x = ADDR % 640;
wire [8:0] pixel_y = ADDR / 640;

localparam BLOCK_SIZE = 30;
localparam GRID_SIZE = 12;
localparam GRID_LEFT = 80;
localparam GRID_TOP = 0;

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

// Logic to draw the snake body
wire is_snake;
wire [3:0] snake_parts;

generate
    for (j = 0; j < 4; j = j + 1) begin : draw_snake_body
        wire [9:0] block_start_x = GRID_LEFT + snake_x[j] * BLOCK_SIZE;
        wire [8:0] block_start_y = GRID_TOP + snake_y[j] * BLOCK_SIZE;
        assign snake_parts[j] = ((pixel_x >= block_start_x) && (pixel_x < block_start_x + BLOCK_SIZE) &&
                                 (pixel_y >= block_start_y) && (pixel_y < block_start_y + BLOCK_SIZE));
    end
endgenerate

assign is_snake = |snake_parts;

// Logic to draw the food
wire is_food;
wire [9:0] food_start_x = GRID_LEFT + food_x * BLOCK_SIZE;
wire [8:0] food_start_y = GRID_TOP + food_y * BLOCK_SIZE;
assign is_food = (pixel_x >= food_start_x) && (pixel_x < food_start_x + BLOCK_SIZE) && 
                 (pixel_y >= food_start_y) && (pixel_y < food_start_y + BLOCK_SIZE);

assign b_data = is_snake ? 8'hFF : is_food ? 8'h00 : is_red_boundary ? 8'h00 : bgr_data[23:16];
assign g_data = is_snake ? 8'h00 : is_food ? 8'hFF : is_red_boundary ? 8'h00 : bgr_data[15:8];
assign r_data = is_snake ? 8'h00 : is_food ? 8'h00 : is_red_boundary ? 8'hFF : bgr_data[7:0];

always @(negedge iVGA_CLK) begin
    oHS <= cHS;
    oVS <= cVS;
    oBLANK_n <= cBLANK_n;
end

endmodule
