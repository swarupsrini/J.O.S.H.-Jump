//Sw[7:0] data_in

//KEY[0] synchronous reset when pressed
//KEY[1] go signal

//LEDR displays result
//HEX0 & HEX1 also displays result

module JOSH_Jump(
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

    wire endgame;

    assign resetn = KEY[0];
    assign grav = SW[0];
    assign go = SW[1];
    
    control c0 (CLOCK_50, resetn, grav, go, endgame, ingame);
    datapath d0 (CLOCK_50, resetn, ingame, grav, endgame, VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B);

endmodule 
                

module control(
    input clk,
    input resetn,
    // user input
    input grav,
    input go,
    // signals from datapath
    input endgame,
    
    // signals to datapath
    output reg ingame, // 0 for menu, 1 for game
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
                S_MENU_WAIT: next_state = S_GAME;
                S_GAME: next_state = endgame ? S_MENU : S_GAME;
            default: next_state = S_MENU;
        endcase
    end
   

    // Output logic aka all datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
            ingame = 1'b0;
        case (current_state)
            //S_MENU: begin
            //    startgame = 1'b0;
            //end
            S_GAME: begin
                ingame = 1'b1;
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
    input ingame,
    input grav, // should be connected to a switch input
    output reg endgame,

    output VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N,
    output [9:0] VGA_R, VGA_G, VGA_B
    );

    // ints
    integer i;
    integer j;

    // registers/wires
    reg [99:0] vwall [119:0]; 
    reg [11999:0] vwall1;
    reg [119:0] hwall;
    // top left coordinates of dude
    reg [6:0] hdude = 7'd20; // from 0 to 20
    reg [7:0] vdude = 8'd100; // from 6 to 100
    
    reg [4:0] surr;
    reg inc = 1'b1;
    reg [3:0] xdude = 4'd4; // if we change this we need to change the collision check to be a for loop
    reg [3:0] ydude = 4'd6;
    reg [99:0] nextwall;
    reg [6:0] h_counter_w = 7'd120; // 20 - 120 when start, change to 20
    reg [6:0] v_counter_w = 7'd10; // 10
    reg [3:0] h_counter_d = 4'd4; // 0 - 4 when start change to 0
    reg [3:0] v_counter_d = 4'b0;

    // modules
    update_screen us(vwall1, hwall, vdude, hdude, h_counter_w, v_counter_w, h_counter_d, v_counter_d, clk, resetn, VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B);

    always @(posedge clk) begin

        // 0. resetting
        if (!resetn) begin
            endgame = 1'b1;
        end
        else if (!ingame) begin
            endgame = 1'b0;
            for (i=0; i<120; i=i+1) begin
            for (j=0; j<100; j=j+1) begin
                vwall[i][j] = 1'b0;
            end
            end
            for (i=0; i<120; i=i+1) begin
                hwall[i] = 1'b0;
            end
            hdude = 7'd20;
            vdude = 8'd100;

            inc = 1'b1;
            xdude = 4'd4;
        end
        else if (ingame) begin
            // 1. collision check
            // a. vertical
            if (!grav)  // grav down
                surr = {vwall[hdude][vdude-1'b1], vwall[hdude+1'b1][vdude-1'b1], vwall[hdude+2'd2][vdude-1'b1], vwall[hdude+2'd3][vdude-1'b1]};
            else        // grav up
                surr = {vwall[hdude][vdude+ydude+1'b1], vwall[hdude+1'b1][vdude+ydude+1'b1], vwall[hdude+2'd2][vdude+ydude+1'b1], vwall[hdude+2'd3][vdude+ydude+1'b1]};
            
            // b. horizontal
            if (hwall[1'b1]) begin
                if (~|{vwall[hdude+xdude+1'b1][vdude], vwall[hdude+xdude+1'b1][vdude+1'b1], vwall[hdude+xdude+1'b1][vdude+2'd2], vwall[hdude+xdude+1'b1][vdude+2'd3], vwall[hdude+xdude+1'b1][vdude+3'd4], vwall[hdude+xdude+1'b1][vdude+3'd5]}) begin
                    hdude = hdude-1'b1;
                    if (hdude <= 1'b0)
                        endgame = 1'b1;
                end
            end

            // 2. shifting
            // TODO: use RAM to get next walls from the map
            nextwall = 100'b1111111111111111111100000000000000000000000000000000000000000000000000000000000011111111111111111111;
            if (|nextwall == 0) begin
                endgame = 1'b1;
            end
            for (i=0; i<119; i=i+1) begin
                vwall[i] = vwall[i+1];
                hwall[i] = hwall[i+1];
            end
            vwall[119] = nextwall;

            // 3. drawing
            for (i=0; i<120; i=i+1) begin
                for (j=0; j<100; j=j+1) begin
                    vwall1[i*j] = vwall[i][j];
                end
            end
            h_counter_w = 7'd20;
            h_counter_d = 4'd0;
        end
    end

endmodule

module update_screen(vwall, hwall, vdude, hdude, h_counter_w_i, v_counter_w_i, h_counter_d_i, v_counter_d_i, clk, resetn, VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B);
    input [11999:0] vwall; // maybe too much? 
    input [119:0] hwall;
    input [6:0] hdude; // group of 4 1s 
    input [7:0] vdude; // 4 pixels wide
    input [6:0] h_counter_w_i;
    input [6:0] v_counter_w_i;
    input [3:0] h_counter_d_i;
    input [3:0] v_counter_d_i;
    input clk;
    input resetn;

    output VGA_CLK,   					//	VGA Clock
	    VGA_HS,							//	VGA H_SYNC
        VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,					//	VGA BLANK
		VGA_SYNC_N;                     //	VGA SYNC

	output [9:0]	VGA_R,   			    //	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B;         					//	VGA Blue[9:0]

    reg [2:0] colourFinal;

    reg [6:0]h_counter_w;
    reg [6:0]v_counter_w;
    reg [3:0]h_counter_d;
    reg [3:0]v_counter_d;
    reg [6:0]h_final;
    reg [6:0]v_final;
    
    // WALLS
    always @(posedge clk)
        begin 
            h_counter_w = h_counter_w_i;
            v_counter_w = v_counter_w_i;
            h_counter_d = h_counter_d_i;
            v_counter_d = v_counter_d_i;

            if (h_counter_w < 7'b1111000) // 120 
                begin 
                    if (v_counter_w < 7'd100)
                        begin
                            colourFinal = (vwall[120*h_counter_w + v_counter_w] == 1'b1 ? 3'b111 : 3'b000);

                             v_counter_w = v_counter_w + 1;
                             v_final = v_counter_w;
                        end
                    else 
                        begin 
                            h_counter_w = h_counter_w + 1;
                            v_counter_w = 7'd10;
                            h_final = h_counter_w;
                        end
                end

                else if (h_counter_d < 4'd4) 
                begin 
                    if (v_counter_d < 4'd6)
                        begin
                            colourFinal = 3'b100;

                            v_counter_d = v_counter_d + 1;
                            v_final = v_counter_d + vdude;
                        end
                    else 
                        begin 
                            h_counter_d = h_counter_d + 1;
                            v_counter_d = 4'd0;
                            h_final = h_counter_d + hdude;
                        end
                end
        end

        vga_adapter VGA(
                             .resetn(resetn),
                             .clock(clk),
                             .colour(colourFinal),
                             .x(h_final),
                             .y(v_final),
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
        // defparam VGA.BACKGROND_IMAGE = "black.mif";

        // vga_adapter VGA2(
        //                      .resetn(resetn),
        //                      .clock(clk),
        //                      .colour(colour2),
        //                      .x(hdude + h_counter_d),
        //                      .y(vdude + v_counter_d),
        //                      .plot(1'b1),
        //                      /* Signals for the DAC to drive the monitor. */
        //                      .VGA_R(VGA_R),
        //                      .VGA_G(VGA_G),
        //                      .VGA_B(VGA_B),
        //                      .VGA_HS(VGA_HS),
        //                      .VGA_VS(VGA_VS),
        //                      .VGA_BLANK(VGA_BLANK_N),
        //                      .VGA_SYNC(VGA_SYNC_N),
        //                      .VGA_CLK(VGA_CLK));
        

        // // DUDE
        // always @(posedge clk)
        // begin 
        //     if (h_counter_d < 4'd4) 
        //         begin 
        //             if (v_counter_d < 4'd6)
        //                 begin
        //                     assign colour = 3'b100;

        //                     vga_adapter VGA(
        //                      .resetn(resetn),
        //                      .clock(clk),
        //                      .colour(colour),
        //                      .x(hdude + h_counter_d),
        //                      .y(vdude + v_counter_d),
        //                      .plot(1'b1),
        //                      /* Signals for the DAC to drive the monitor. */
        //                      .VGA_R(VGA_R),
        //                      .VGA_G(VGA_G),
        //                      .VGA_B(VGA_B),
        //                      .VGA_HS(VGA_HS),
        //                      .VGA_VS(VGA_VS),
        //                      .VGA_BLANK(VGA_BLANK_N),
        //                      .VGA_SYNC(VGA_SYNC_N),
        //                      .VGA_CLK(VGA_CLK));

        //                      v_counter_d = v_counter_d + 1;
        //                 end
        //             else 
        //                 begin 
        //                     h_counter_d = h_counter_d + 1;
        //                     v_counter_d = 4'd0;
        //                 end
        //         end
        // end

    // integer i,j;
 
    // // wall update
    // initial begin : lol
    //     for (i=0; i < 120; i = i + 1)
    //         begin : hello
    //             if (hwall[i] == 1'b1)
    //             begin : klalala
    //                 for (j=0; j < 100; j = j + 1)
    //                     begin : wall_update
    //                         assign colour = (vwall[i][j] == 1'b1 ? 3'b111 : 3'b000);

    //                         vga_adapter VGA(
    //                         .resetn(resetn),
    //                         .clock(clk),
    //                         .colour(colour),
    //                         .x(7'd20 + i),
    //                         .y(6'd10 + j),
    //                         .plot(1'b1),
    //                         /* Signals for the DAC to drive the monitor. */
    //                         .VGA_R(VGA_R),
    //                         .VGA_G(VGA_G),
    //                         .VGA_B(VGA_B),
    //                         .VGA_HS(VGA_HS),
    //                         .VGA_VS(VGA_VS),
    //                         .VGA_BLANK(VGA_BLANK_N),
    //                         .VGA_SYNC(VGA_SYNC_N),
    //                         .VGA_CLK(VGA_CLK));
    //                     end
    //             end 
    //         end
    // end

    // // dude update
    // initial begin 
    //     for (i=0; i < 4; i = i + 1)
    //         begin
    //                 for (j=0); j < 6; j = j + 1)
    //                     assign colour = 3'b100;
    //                     begin : dude_update
    //                         vga_adapter VGA(
    //                         .resetn(resetn),
    //                         .clock(clk),
    //                         .colour(colour),
    //                         .x(7'd20 + hdude + i),
    //                         .y(6'd10 + vdude + j),
    //                         .plot(1'b1),
    //                         /* Signals for the DAC to drive the monitor. */
    //                         .VGA_R(VGA_R),
    //                         .VGA_G(VGA_G),
    //                         .VGA_B(VGA_B),
    //                         .VGA_HS(VGA_HS),
    //                         .VGA_VS(VGA_VS),
    //                         .VGA_BLANK(VGA_BLANK_N),
    //                         .VGA_SYNC(VGA_SYNC_N),
    //                         .VGA_CLK(VGA_CLK));
    //                     end
    //         end
    // end 

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