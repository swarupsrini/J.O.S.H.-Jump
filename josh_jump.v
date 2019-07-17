//Sw[7:0] data_in

//KEY[0] synchronous reset when pressed
//KEY[1] go signal

//LEDR displays result
//HEX0 & HEX1 also displays result

module JOSH_Jump(SW, KEY, CLOCK_50, LEDR, HEX0, HEX1);
    input [9:0] SW;
    input [3:0] KEY;
    input CLOCK_50;
    output [9:0] LEDR;
    output [6:0] HEX0, HEX1;

    wire resetn;
    wire go;

    wire [7:0] data_result;
    assign go = ~KEY[1];
    assign resetn = KEY[0];

    part2 u0(
        .clk(CLOCK_50),
        .resetn(resetn),
        .go(go),
        .data_in(SW[7:0]),
        .data_result(data_result)
    );
      
    assign LEDR[7:0] = data_result;

    hex_decoder H0(
        .hex_digit(data_result[3:0]), 
        .segments(HEX0)
        );
        
    hex_decoder H1(
        .hex_digit(data_result[7:4]), 
        .segments(HEX1)
        );

endmodule

module part2(
    input clk,
    input resetn,
    input go,
    input [7:0] data_in,
    output [7:0] data_result
    );

    // lots of wires to connect our datapath and control
    wire ld_a, ld_b, ld_c, ld_x, ld_r;
    wire ld_alu_out;
    wire [1:0]  alu_select_a, alu_select_b;
    wire alu_op;

    control C0(
        .clk(clk),
        .resetn(resetn),
        
        .go(go),
        
        .ld_alu_out(ld_alu_out), 
        .ld_x(ld_x),
        .ld_a(ld_a),
        .ld_b(ld_b),
        .ld_c(ld_c), 
        .ld_r(ld_r), 
        
        .alu_select_a(alu_select_a),
        .alu_select_b(alu_select_b),
        .alu_op(alu_op)
    );

    datapath D0(
        .clk(clk),
        .resetn(resetn),

        .ld_alu_out(ld_alu_out), 
        .ld_x(ld_x),
        .ld_a(ld_a),
        .ld_b(ld_b),
        .ld_c(ld_c), 
        .ld_r(ld_r), 

        .alu_select_a(alu_select_a),
        .alu_select_b(alu_select_b),
        .alu_op(alu_op),

        .data_in(data_in),
        .data_result(data_result)
    );
                
 endmodule        
                

module control(
    input clk,
    input resetn,
    // user input
    input grav,
    // signals from datapath
    input endgame,
    
    // signals to datapath
    output reg startgame // 0 for menu, 1 for game
    );

    reg [5:0] current_state, next_state; 
    
    localparam  S_MENU        = 2'd0,
                S_MENU_WAIT   = 2'd1,
                S_GAME        = 2'd2;
    
    // state table
    always@(*)
    begin: state_table 
            case (current_state)
                S_MENU: next_state = go ? S_MENU_WAIT : S_MENU;
                S_MENU_WAIT: next_state = S_GAME_START;
                S_GAME: next_state = endgame ? S_MENU : S_GAME;
            default: next_state = S_MENU;
        endcase
    end
   

    // Output logic aka all datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
            startgame = 1'b0;
        case (current_state)
            //S_MENU: begin
            //    startgame = 1'b0;
            //end
            S_GAME: begin
                startgame = 1'b1;
            end
            
        // default:  // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_MENU;
        else
            current_state <= next_state;
    end // state_FFS
endmodule

module datapath(
    input clk,
    input resetn,
    input startgame,
    input grav, // should be connected to a switch input
    output reg endgame
    );
    
    // registers
    reg [99:0] vwall [119:0]; 
    reg [119:0] hwall;
    // top left coordinates of dude
    reg [6:0] hdude = 7'd20; // from 0 to 20
    reg [7:0] vdude = 8'd100; // from 6 to 100
    
    reg [4:0] surr;
    wire inc = 1'b1;

    always @(posedge clk) begin
        // 0. resetting
        if (!reset_n) begin
            endgame = 1'b1;
        end
        else begin
            // 1. collision check
            // a. vertical
            if (!grav)  // grav down
                surr = {vwall[hdude][vdude-1'b1], vwall[hdude+1'b1][vdude-1'b1], vwall[hdude+2'd2][vdude-1'b1], vwall[hdude+2'd3][vdude-1'b1]};
            else        // grav up
                surr = {vwall[hdude][vdude+1'b1], vwall[hdude+1'b1][vdude+1'b1], vwall[hdude+2'd2][vdude-1'b1], vwall[hdude+2'd3][vdude-1'b1]};
            
            // b. horizontal
            if (hwall[1'b1]) begin
                
            end

        end

    end

endmodule

module update_screen(vwall, hwall, vdude, hdude, clk, reset_n, o)
    input [99:0] vwall [119:0]; // maybe too much? 
    input [119:0] hwall;
    input [:0] hdude; // group of 4 1s 
    input [119:0] vdude; // 4 pixels wide
    input clk;

    wire VGA_CLK,   					//	VGA Clock
	    VGA_HS,							//	VGA H_SYNC
        VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,					//	VGA BLANK
		VGA_SYNC_N;                     //	VGA SYNC

	wire [9:0]	VGA_R,   			    //	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B;         					//	VGA Blue[9:0]

    wire [2:0] colour;

    integer i,j;
    reg [6:0] h_counter, v_counter;

    h_counter_wall = 7'b0010100;
    v_counter_wall = 7'b0001010;

    // get x value, do walls
    initial begin 
        for (i=0; i < 120; i = i + 1)
            begin
                if (hwall[i] == 1'b1)
                begin
                    for (j=0); j < 100; j = j + 1)
                        assign colour = (vwall[i][j] == 1'b1 ? 3'b111 : 3'b000);
                        begin
                            vga_adapter VGA(
                            .resetn(reset_n),
                            .clock(clk),
                            .colour(colour),
                            .x(i),
                            .y(j),
                            .plot(1'b1),
                            /* Signals for the DAC to drive the monitor. */
                            .VGA_R(VGA_R),
                            .VGA_G(VGA_G),
                            .VGA_B(VGA_B),
                            .VGA_HS(VGA_HS),
                            .VGA_VS(VGA_VS),
                            .VGA_BLANK(VGA_BLANK_N),
                            .VGA_SYNC(VGA_SYNC_N),
                            .VGA_CLK(VGA_CLK));
                        end
                end 
            end
    end

    initial begin 
        for (i=0; i < 4; i = i + 1)
            begin
                    for (j=0); j < 6; j = j + 1)
                        assign colour = 3'b100;
                        begin
                            vga_adapter VGA(
                            .resetn(reset_n),
                            .clock(clk),
                            .colour(colour),
                            .x(hi),
                            .y(j),
                            .plot(1'b1),
                            /* Signals for the DAC to drive the monitor. */
                            .VGA_R(VGA_R),
                            .VGA_G(VGA_G),
                            .VGA_B(VGA_B),
                            .VGA_HS(VGA_HS),
                            .VGA_VS(VGA_VS),
                            .VGA_BLANK(VGA_BLANK_N),
                            .VGA_SYNC(VGA_SYNC_N),
                            .VGA_CLK(VGA_CLK));
                        end
            end
    end 




endmodule

module vga_adapter(
			resetn,
			clock,
			colour,
			x, y, plot,
			/* Signals for the DAC to drive the monitor. */
			VGA_R,
			VGA_G,
			VGA_B,
			VGA_HS,
			VGA_VS,
			VGA_BLANK,
			VGA_SYNC,
			VGA_CLK);
 
	parameter BITS_PER_COLOUR_CHANNEL = 1;
	/* The number of bits per colour channel used to represent the colour of each pixel. A value
	 * of 1 means that Red, Green and Blue colour channels will use 1 bit each to represent the intensity
	 * of the respective colour channel. For BITS_PER_COLOUR_CHANNEL=1, the adapter can display 8 colours.
	 * In general, the adapter is able to use 2^(3*BITS_PER_COLOUR_CHANNEL ) colours. The number of colours is
	 * limited by the screen resolution and the amount of on-chip memory available on the target device.
	 */	
	
	parameter MONOCHROME = "FALSE";
	/* Set this parameter to "TRUE" if you only wish to use black and white colours. Doing so will reduce
	 * the amount of memory you will use by a factor of 3. */
	
	parameter RESOLUTION = "320x240";
	/* Set this parameter to "160x120" or "320x240". It will cause the VGA adapter to draw each dot on
	 * the screen by using a block of 4x4 pixels ("160x120" resolution) or 2x2 pixels ("320x240" resolution).
	 * It effectively reduces the screen resolution to an integer fraction of 640x480. It was necessary
	 * to reduce the resolution for the Video Memory to fit within the on-chip memory limits.
	 */
	
	parameter BACKGROUND_IMAGE = "background.mif";
	/* The initial screen displayed when the circuit is first programmed onto the DE2 board can be
	 * defined useing an MIF file. The file contains the initial colour for each pixel on the screen
	 * and is placed in the Video Memory (VideoMemory module) upon programming. Note that resetting the
	 * VGA Adapter will not cause the Video Memory to revert to the specified image. */


	/*****************************************************************************/
	/* Declare inputs and outputs.                                               */
	/*****************************************************************************/
	input resetn;
	input clock;
	
	/* The colour input can be either 1 bit or 3*BITS_PER_COLOUR_CHANNEL bits wide, depending on
	 * the setting of the MONOCHROME parameter.
	 */
	input [((MONOCHROME == "TRUE") ? (0) : (BITS_PER_COLOUR_CHANNEL*3-1)):0] colour;
	
	/* Specify the number of bits required to represent an (X,Y) coordinate on the screen for
	 * a given resolution.
	 */
	input [((RESOLUTION == "320x240") ? (8) : (7)):0] x; 
	input [((RESOLUTION == "320x240") ? (7) : (6)):0] y;
	
	/* When plot is high then at the next positive edge of the clock the pixel at (x,y) will change to
	 * a new colour, defined by the value of the colour input.
	 */
	input plot;
	
	/* These outputs drive the VGA display. The VGA_CLK is also used to clock the FSM responsible for
	 * controlling the data transferred to the DAC driving the monitor. */
	output [9:0] VGA_R;
	output [9:0] VGA_G;
	output [9:0] VGA_B;
	output VGA_HS;
	output VGA_VS;
	output VGA_BLANK;
	output VGA_SYNC;
	output VGA_CLK;

	/*****************************************************************************/
	/* Declare local signals here.                                               */
	/*****************************************************************************/
	
	wire valid_160x120;
	wire valid_320x240;
	/* Set to 1 if the specified coordinates are in a valid range for a given resolution.*/
	
	wire writeEn;
	/* This is a local signal that allows the Video Memory contents to be changed.
	 * It depends on the screen resolution, the values of X and Y inputs, as well as 
	 * the state of the plot signal.
	 */
	
	wire [((MONOCHROME == "TRUE") ? (0) : (BITS_PER_COLOUR_CHANNEL*3-1)):0] to_ctrl_colour;
	/* Pixel colour read by the VGA controller */
	
	wire [((RESOLUTION == "320x240") ? (16) : (14)):0] user_to_video_memory_addr;
	/* This bus specifies the address in memory the user must write
	 * data to in order for the pixel intended to appear at location (X,Y) to be displayed
	 * at the correct location on the screen.
	 */
	
	wire [((RESOLUTION == "320x240") ? (16) : (14)):0] controller_to_video_memory_addr;
	/* This bus specifies the address in memory the vga controller must read data from
	 * in order to determine the colour of a pixel located at coordinate (X,Y) of the screen.
	 */
	
	wire clock_25;
	/* 25MHz clock generated by dividing the input clock frequency by 2. */
	
	wire vcc, gnd;
	
	/*****************************************************************************/
	/* Instances of modules for the VGA adapter.                                 */
	/*****************************************************************************/	
	assign vcc = 1'b1;
	assign gnd = 1'b0;
	
	vga_address_translator user_input_translator(
					.x(x), .y(y), .mem_address(user_to_video_memory_addr) );
		defparam user_input_translator.RESOLUTION = RESOLUTION;
	/* Convert user coordinates into a memory address. */

	assign valid_160x120 = (({1'b0, x} >= 0) & ({1'b0, x} < 160) & ({1'b0, y} >= 0) & ({1'b0, y} < 120)) & (RESOLUTION == "160x120");
	assign valid_320x240 = (({1'b0, x} >= 0) & ({1'b0, x} < 320) & ({1'b0, y} >= 0) & ({1'b0, y} < 240)) & (RESOLUTION == "320x240");
	assign writeEn = (plot) & (valid_160x120 | valid_320x240);
	/* Allow the user to plot a pixel if and only if the (X,Y) coordinates supplied are in a valid range. */
	
	/* Create video memory. */
	altsyncram	VideoMemory (
				.wren_a (writeEn),
				.wren_b (gnd),
				.clock0 (clock), // write clock
				.clock1 (clock_25), // read clock
				.clocken0 (vcc), // write enable clock
				.clocken1 (vcc), // read enable clock				
				.address_a (user_to_video_memory_addr),
				.address_b (controller_to_video_memory_addr),
				.data_a (colour), // data in
				.q_b (to_ctrl_colour)	// data out
				);
	defparam
		VideoMemory.WIDTH_A = ((MONOCHROME == "FALSE") ? (BITS_PER_COLOUR_CHANNEL*3) : 1),
		VideoMemory.WIDTH_B = ((MONOCHROME == "FALSE") ? (BITS_PER_COLOUR_CHANNEL*3) : 1),
		VideoMemory.INTENDED_DEVICE_FAMILY = "Cyclone II",
		VideoMemory.OPERATION_MODE = "DUAL_PORT",
		VideoMemory.WIDTHAD_A = ((RESOLUTION == "320x240") ? (17) : (15)),
		VideoMemory.NUMWORDS_A = ((RESOLUTION == "320x240") ? (76800) : (19200)),
		VideoMemory.WIDTHAD_B = ((RESOLUTION == "320x240") ? (17) : (15)),
		VideoMemory.NUMWORDS_B = ((RESOLUTION == "320x240") ? (76800) : (19200)),
		VideoMemory.OUTDATA_REG_B = "CLOCK1",
		VideoMemory.ADDRESS_REG_B = "CLOCK1",
		VideoMemory.CLOCK_ENABLE_INPUT_A = "BYPASS",
		VideoMemory.CLOCK_ENABLE_INPUT_B = "BYPASS",
		VideoMemory.CLOCK_ENABLE_OUTPUT_B = "BYPASS",
		VideoMemory.POWER_UP_UNINITIALIZED = "FALSE",
		VideoMemory.INIT_FILE = BACKGROUND_IMAGE;
		
	vga_pll mypll(clock, clock_25);
	/* This module generates a clock with half the frequency of the input clock.
	 * For the VGA adapter to operate correctly the clock signal 'clock' must be
	 * a 50MHz clock. The derived clock, which will then operate at 25MHz, is
	 * required to set the monitor into the 640x480@60Hz display mode (also known as
	 * the VGA mode).
	 */
	
	vga_controller controller(
			.vga_clock(clock_25),
			.resetn(resetn),
			.pixel_colour(to_ctrl_colour),
			.memory_address(controller_to_video_memory_addr), 
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK),
			.VGA_SYNC(VGA_SYNC),
			.VGA_CLK(VGA_CLK)				
		);
		defparam controller.BITS_PER_COLOUR_CHANNEL  = BITS_PER_COLOUR_CHANNEL ;
		defparam controller.MONOCHROME = MONOCHROME;
		defparam controller.RESOLUTION = RESOLUTION;

endmodule

module clock_divider(div, clock, clock_out, reset_n);
    input clock;
    output clock_out;
    wire q;
    wire qout;
    sync_counter sc(1'b1, )

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

module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule