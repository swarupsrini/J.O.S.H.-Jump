// Part 2 skeleton

module lab6b
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
	
    wire enable, ld_x, ld_y, ld_c;
	 
    // Instantiate datapath
    datapath d0(SW[6:0], CLOCK50, resetn, enable, ld_x, ld_y, ld_c, SW[9:7], colour, x, y);

    // Instantiate FSM control
    control c0(~KEY[3], ~KEY[1], resetn, CLOCK50, enable, ld_x, ld_y, ld_c, writeEn);
    //control(go, fill, reset_n, clock, enable, ld_x, ld_y, ld_c, plot);
	 
endmodule

module datapath(data_in, clock, reset_n, enable, ld_x, ld_y, ld_c, col_in, col_out, X, Y);
	input reset_n, enable, ld_x, ld_y, ld_c, clock;
	input [6:0] data_in;
	input [2:0] col_in;
	output [6:0] X, Y;
	output [2:0] col_out;
	reg [6:0] x1, y1, c1;
	wire [1:0] q1, q2;
	wire q1out;
	
	always @(posedge clock) begin
		if (!reset_n) begin
			x1 <= 7'b0;
			y1 <= 7'b0;
			c1 <= 2'b0;
		end
		else begin
			if (ld_x)
				x1 <= {1'b0, data_in};
			if (ld_y)
				y1 <= data_in;
			if (ld_c)
				c1 <= col_in;
		end
	end
	
	sync_counter s1(enable, clock, reset_n, 1'b0, 3'd3, 1'b1, q1);
	assign q1out = (q1 == 1'b0) ? 1 : 0; // allnor
	sync_counter s2(q1out, clock, reset_n, 1'b0, 3'd3, 1'b1, q2);
	assign X = x1 + q1;
	assign Y = y1 + q2;
	assign col_out = c1;
endmodule

module control(go, fill, reset_n, clock, enable, ld_x, ld_y, ld_c, plot);
	input go, fill, reset_n, clock;
	output reg enable, ld_x, ld_y, ld_c, plot;
	reg [3:0] curr_s, next_s;
	
   localparam  S_LOAD_X   = 5'd0,
               S_LOAD_Y   = 5'd1,
               S_CYCLE_0  = 5'd2;
	
	always @(*)
	begin: state_table // next state logic
		case (curr_s)
			S_LOAD_X: next_s = go ? S_LOAD_Y : S_LOAD_X;
			S_LOAD_Y: next_s = fill ? S_CYCLE_0: S_LOAD_Y;
			S_CYCLE_0: next_s = S_LOAD_X;
			default: next_s = S_LOAD_X;
		endcase
	end
	
	always @(*)
	begin: enable_signals // datapath control signals
		ld_x = 1'b0;
		ld_y = 1'b0;
		ld_c = 1'b0;
		enable = 1'b0;
		plot = 1'b0;
		
		case (curr_s)
			S_LOAD_X: begin
				ld_x = 1'b1;
			end
			S_LOAD_Y: begin
				ld_y = 1'b1;
			end
			S_CYCLE_0: begin
				ld_c = 1'b1;
				enable = 1'b1;
				plot = 1'b1;
			end
		endcase
	end
	always @(posedge clock)
	begin: state_FFs // current state registers
		if (!reset_n)
			curr_s = S_LOAD_X;
		else
			curr_s = next_s;
	end
endmodule

module sync_counter(enable, clock, reset_n, startb, endb, inc, q);
	input enable, clock, reset_n, inc;
	input [27:0] startb, endb;
	output reg [27:0] q;
	
	always @(posedge clock)
	begin
		if (reset_n == 1'b0)
			q <= startb;
		else if (enable == 1'b1)
			if (q == endb)
				q <= startb;
			else
				q <= q + inc;
	end
endmodule
