
//Sw[7:0] data_in

//KEY[0] synchronous reset when pressed
//KEY[1] go signal

//LEDR displays result
//HEX0 & HEX1 also displays result

module JOSH(
    input [9:0] SW,
    input [3:0] KEY,
    input CLOCK_50,
    output [9:0] LEDR,
    output [6:0] HEX0, HEX1,

    output VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N,
    output [9:0] VGA_R, VGA_G, VGA_B
    );

    wire resetn;
    wire grav;
    wire ingame;
    wire go;
	 
	 wire [7:0] x,y;
	 
	 wire [3:0]colour;

    wire endgame;

    assign resetn = KEY[0];
    assign grav = SW[0];
    assign go = SW[1];
	 
	 wire [5:0] curr;
	 wire [11999:0] vwall;
	 wire [119:0] hwall;
	 wire [7:0] vdude, hdude;
	 wire enable, o, menu, physics, setup, display;
	 
	 //assign LEDR[3:0] = curr; // debugging
	 
	 vga_adapter VGA(
                             .resetn(resetn),
                             .clock(CLOCK_50),
                             .colour(colour),
                             .x(x),
                             .y(y),
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
        defparam VGA.RESOLUTION = "160x120";
        defparam VGA.MONOCHROME = "FALSE";
        defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
    
    control c0 (CLOCK_50, resetn, grav, go, o, endgame, menu, physics, setup, display, curr);
    datapath d0 (CLOCK_50, resetn, grav, menu, physics, setup, display, curr, endgame, vwall, hwall, vdude, hdude, enable);
	 update_screen u0 (enable, vwall, vdude, hdude, CLOCK_50, resetn, setup, display, x,y,colour,o);
	 hex_decoder h0(curr, HEX0);
	 
	 
endmodule 
                

module control(
		 // inputs from top-level
		 input clk,
		 input resetn,
		 input grav,
		 input go,
		 
		 // inputs from datapath
		 input o,
		 input endgame,
		 
		 // signals to datapath
		 output reg menu,
		 output reg physics,
		 output reg setup,
		 output reg display, 
		  
		 // debugging output
		 output reg [5:0] current_state
		 //output [6:0] HEX1
    );

    reg [5:0] next_state;
	 
	 //hex_decoder h1(2, HEX1);
	 
	 //assign curr = current_state; // debugging output
    
    localparam  S_MENU        	= 0,
					 S_MENU_WAIT 		= 1,
                S_PHYSICS     	= 2,
					 S_PHYSICS_WAIT	= 3,
                S_SETUP       	= 4,
					 S_SETUP_WAIT 		= 5,
					 S_DISPLAY     	= 6,
					 S_DISPLAY_WAIT   = 7;
    
    // state table
    always @(*)
    begin: state_table 
            case (current_state)
					 S_MENU: next_state = (go && resetn) ? S_PHYSICS_WAIT : S_MENU;
					 S_PHYSICS: next_state = (!resetn || endgame) ? S_MENU_WAIT : S_SETUP_WAIT;
					 S_SETUP: next_state = (!resetn) ? S_MENU_WAIT : S_DISPLAY_WAIT;
                S_DISPLAY: begin
						if (!resetn) next_state = S_MENU_WAIT;
						else if (o) next_state = S_PHYSICS_WAIT;
						else next_state = S_DISPLAY_WAIT;
					 end
					 //waits
					 S_MENU_WAIT: next_state = S_MENU;
					 S_PHYSICS_WAIT: next_state = S_PHYSICS;
					 S_SETUP_WAIT: next_state = S_SETUP;
					 S_DISPLAY_WAIT: next_state = S_DISPLAY;
            default: next_state = S_MENU_WAIT;
        endcase
    end
   

    // Output logic aka all datapath control signals
    always @(*)
    begin: enable_signals
				menu = 0;
            physics = 0;
				setup = 0;
				display = 0;
        case (current_state)
            S_MENU: begin
                menu = 1;
            end
				S_PHYSICS: begin
					physics = 1;
				end
				S_SETUP: begin
					setup = 1;
				end
				S_DISPLAY: begin
					display = 1;
				end
           default: begin
			  end
			  // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state = S_MENU;
        else
            current_state = next_state;
    end // state_FFS
endmodule

module datapath(
		 // inputs from top-level
		 input clk,
		 input resetn,
		 input grav, // should be connected to a switch input
		 
		 // inputs from control
		 input menu,
		 input physics,
		 input setup,
		 input display,
		 input [5:0] curr,
		 
		 // output to control
		 output reg endgame,
		 
		 // output to VGA
		 output reg [11999:0] vwall,
		 output reg [119:0] hwall,
		 output reg [7:0] vdude, 
		 output reg [7:0] hdude,
		 output reg enable
    );
	 
	 initial hdude = 30;
	 initial vdude = 94;
	 initial vwall = 0;
	 initial hwall = 0;
	 
	 integer i;
    integer j;
<<<<<<< HEAD
<<<<<<< HEAD
	 
	 wire i100;
	 assign i100 = i * 100;
	 
	 wire [7:0] hdude100;
	 assign hdude100 = hdude * 100;
	 
    reg [3:0] surr;
	 reg [5:0] surrh;
	 reg [99:0] walltop = 100'b1111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000;
    reg [99:0] wallbot = 100'b0000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111111111111;
    reg [99:0] wallall = 100'b1111111111111111111100000000000000000000000000000000000000000000000000000000000011111111111111111111;
    reg [99:0] wallmid = 100'b0000000000000000000000000000001111111111111111111111111111111111111111000000000000000000000000000000;
=======
=======
>>>>>>> parent of b515b95... Update joshtest.v

    // top left coordinates of dude
    reg [4:0] surr;
    reg [99:0] nextwall;
    reg [99:0] nextwall1;
>>>>>>> parent of b515b95... Update joshtest.v
	 reg which=0; 
	 
	 always@(posedge clk) begin
		case (curr)
			0: begin // MENU
				vwall <= 0;
				hwall <= 0;
				hdude <= 30;
				vdude <= 94;
				enable <= 1;
			end
			
			2: begin // PHYSICS
				// 1. collision check
            // a. vertical
            if (!grav) begin  // grav down
					 surr[3] <= vwall[100*hdude + vdude-1];
					 surr[2] <= vwall[100*(hdude+1) + vdude-1];
					 surr[1] <= vwall[100*(hdude+2) + vdude-1];
					 surr[0] <= vwall[100*(hdude+3) + vdude-1];
                //surr <= {vwall[100*hdude + vdude-1], vwall[100*(hdude+1) + vdude-1], vwall[100*(hdude+2) + vdude-1], vwall[100*(hdude+3) + vdude-1]};
            end
				else begin // grav up
					 surr[3] <= vwall[100*hdude + vdude+6+1];
					 surr[2] <= vwall[100*(hdude+1) + vdude+6+1];
					 surr[1] <= vwall[100*(hdude+2) + vdude+6+1];
					 surr[0] <= vwall[100*(hdude+3) + vdude+6+1];
                //surr <= {vwall[100*hdude + vdude+6+1], vwall[100*(hdude+1) + vdude+6+1], vwall[100*(hdude+2) + vdude+6+1], vwall[100*(hdude+3) + vdude+6+1]};
            end
				if (|surr) begin
					if (grav) vdude = vdude - 1;
					else vdude = vdude + 1;
 				end
				
            // b. horizontal
            if (hwall[hdude+1]) begin
					 // if (|vwall[(100*(hdude+4+1) + vdude) : (100*(hdude+4+1) + vdude+5)]) begin
						  if (|{vwall[100*(hdude+4+1) + vdude], vwall[(100*(hdude+4+1) + vdude+1)], vwall[(100*(hdude+4+1) + vdude+2)], vwall[(100*(hdude+4+1) + vdude+3)], vwall[(100*(hdude+4+1) + vdude+4)], vwall[(100*(hdude+4+1) + vdude+5)]}) begin
                    hdude = hdude-1;
                    if (hdude <= 0) endgame = 1;
                end
            end
				
            // 2. shifting
            // TODO: use RAM to get next walls from the map
            //if (|nextwall == 0) begin
            //    endgame = 1'b1;
            //end
            for (i=0; i<119; i=i+1) begin
					for (j=0; j<100; j=j+1) begin
<<<<<<< HEAD
						 vwall[i100 + j] = vwall[i100 + 100+ j];
					end
				end
				for (j=0; j<100; j=j+1) begin
                if (which == 0) vwall[11800 + j] = wallbot[j];
					 else if (which == 1) vwall[11800 + j] = walltop[j];
					 else if (which == 2) vwall[11800 + j] = wallmid[j];
					 else if (which == 3) vwall[11800 + j] = wallall[j];
            end
				which = (which == 3) ? 0 : which + 1;
=======
						 vwall[i*100 + j] = vwall[(i+1)*100 + j];
						 hwall[i] = hwall[i+1];
					end
				end
				for (j=0; j<100; j=j+1) begin
                if (which) vwall[119*100 + j] = nextwall[j];
					 else vwall[119*100 + j] = nextwall1[j];
            end
				which = !which;
<<<<<<< HEAD
>>>>>>> parent of b515b95... Update joshtest.v
=======
>>>>>>> parent of b515b95... Update joshtest.v
			end
		endcase
	end

endmodule

module update_screen(
		 input [11999:0] vwall, // maybe too much? 
		 input [7:0] hdude, // group of 4 1s 
		 input [7:0] vdude, // 4 pixels wide
		 input enable,
		 input clk,
		 input resetn,
		 input setup,
		 input display,

		 output reg [7:0] x,y,
		 output reg [3:0] colour,
		 output reg o
	 );
    reg [7:0]h_counter_w = 20;
    reg [7:0]v_counter_w = 10;
    reg [7:0]h_counter_d = 0;
    reg [7:0]v_counter_d = 0;
	
    
    // WALLS
    always @(posedge clk)
        begin 
				
				if(setup) begin
            h_counter_w = 20;
            v_counter_w = 10;
            h_counter_d = 0;
            v_counter_d = 0;
				o = 0;
				end
				
            if (h_counter_w < 140 && display) // 120 
                begin 
                    if (v_counter_w < 110)
                        begin
                            colour = (datapath.vwall[100*(h_counter_w-20) + (v_counter_w-10)] == 1'b1 ? 3'b111 : 3'b000);

                             v_counter_w = v_counter_w + 1;
                             y = v_counter_w;
                        end
                    else if (h_counter_w < 139)
                        begin 
                            h_counter_w = h_counter_w + 1;
                            v_counter_w = 10;
                            x = h_counter_w;
                        end
							else if (h_counter_w == 139)begin
									h_counter_w = h_counter_w + 1;
									x = h_counter_d + hdude + 20;
									y = v_counter_d + vdude + 10 + 1;
									colour = 3'b100;
							end
                end

                else if (h_counter_d < 4 && display) 
                begin 
                    if (v_counter_d < 6)
                        begin
                            colour = 3'b100;

                            v_counter_d = v_counter_d + 1;
                            y = v_counter_d + vdude + 10;
                        end
                    else if(h_counter_d < 3)
                        begin 
                            h_counter_d = h_counter_d + 1;
                            v_counter_d = 4'd0;
                            x = h_counter_d + hdude + 20;
                        end
                end
					 
					 else if (h_counter_w == 160 && h_counter_d == 5) begin
					     o = 1;
					 end
        end

endmodule

// module clock_divider(div, clock, clock_out, resetn);
//     input clock;
//     output clock_out;
//     wire q;
//     wire qout;
//     sync_counter sc(1'b1, )

// endmodule

module sync_counter(enable, clock, resetn, startb, endb, inc, q);
	input enable, clock, resetn, inc;
	input [27:0] startb, endb;
	output reg [27:0] q;
	
	always @(posedge clock)
	begin
		if (resetn == 1'b0)
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
