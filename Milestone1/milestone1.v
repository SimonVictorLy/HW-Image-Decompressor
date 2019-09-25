

`timescale 1ns/100ps
`default_nettype none

`include "define_state.h"

module milestone1(
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock
		input logic resetn,
		input logic [15:0] SRAM_read_data,
		input logic SRAM_enable,
		
		output logic SRAM_disable,
		output logic [17:0] SRAM_address,
		output logic [15:0] SRAM_write_data,
		output logic SRAM_we_n

);
	


////////////////////////////////////////////////////////////////
// Milestone 1 
////////////////////////////////////////////////////////////////
logic [15:0] m1_read_data;
logic signed [31:0] U_odd;
logic signed [31:0] V_odd;
state_type state;
// Counters
logic [17:0] y_counter;
logic [17:0] rgb_counter;
logic [17:0] uv_counter;
logic [8:0] pixel_counter;
logic [7:0] row_counter;
 // toggles odd and even
logic [1:0] flip;
// Buffers for YUV
logic signed [15:0] Y_buffer;
logic signed [15:0] U_buffer [3:0];
logic signed [15:0] V_buffer [3:0];
logic signed [15:0] temp;
// Buffer for RGB
logic signed [15:0] RGB_buffer[2:0];
// Offset Values for U and V
parameter U_OFFSET = 18'd38400,
		V_OFFSET = 18'd57600,
		RGB_OFFSET = 18'd146944;
// 8 Most and least significant bits of SRAM_write_data
logic [7:0] SRAM_write_data_a;
logic [7:0] SRAM_write_data_b;
// Multiplier inputs
logic signed [31:0] Mult_op_1  [2:0];
logic signed [31:0] Mult_op_2  [2:0];
// Multiplier Outputs
logic signed [31:0] Mult_result[2:0];
logic signed [63:0] Mult_result_long[2:0];
// Adders
logic signed [31:0] add_Mult_01;
logic signed [31:0] add_Mult_02;
logic signed [31:0] add_Mult_012;
// Multiplier Outputs
assign Mult_result_long[0] = Mult_op_1[0] * Mult_op_2[0];
assign Mult_result_long[1] = Mult_op_1[1] * Mult_op_2[1];
assign Mult_result_long[2] = Mult_op_1[2] * Mult_op_2[2];
// Truncated Multiplier Outputs
assign Mult_result[0] = Mult_result_long[0][31:0];
assign Mult_result[1] = Mult_result_long[1][31:0];
assign Mult_result[2] = Mult_result_long[2][31:0];
// Adder for calculating red byte
assign add_Mult_01   = Mult_result[0] + Mult_result[1];
// Adder for calculating blue byte
assign add_Mult_02   = Mult_result[0] + Mult_result[2];
// Adder for calculating green byte
assign add_Mult_012  = Mult_result[0] + Mult_result[1] + Mult_result[2];
// Writing to the SRAM
assign SRAM_write_data = {SRAM_write_data_a,SRAM_write_data_b};

// We realized we were loading the buffers from the SRAM in reverse.
// To fix this issue we flipped the SRAM_read_data most significant
// byte with our least signficant byte.
assign m1_read_data = {SRAM_read_data[7:0],SRAM_read_data[15:8]};

// Milestone 1 State Machine
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		
		SRAM_address <= 18'd0;
		SRAM_write_data_a <= 8'd0;
		SRAM_write_data_b <= 8'd0;
		SRAM_we_n <= 1'b1;
		
		y_counter <= 18'd0;	    // 38400
		uv_counter <= 18'd0;    // 19200
		rgb_counter <= 18'd0;   // 115200
		pixel_counter <= 9'd0;  // 320px
		row_counter <= 8'd0;    // 240px
		flip <= 1'b1;
		
		RGB_buffer[0] <= 8'd0;
		RGB_buffer[1] <= 8'd0;
		RGB_buffer[2] <= 8'd0;
		
		Y_buffer <= 16'd0;
		
		U_buffer[0] <= 16'd0;
		U_buffer[1] <= 16'd0;
		U_buffer[2] <= 16'd0;
		U_buffer[3] <= 16'd0;
		
		V_buffer[0] <= 16'd0;
		V_buffer[1] <= 16'd0;
		V_buffer[2] <= 16'd0;
		V_buffer[3] <= 16'd0;
		
		Mult_op_1[0] <= 32'd0;
		Mult_op_2[0] <= 32'd0;
		Mult_op_1[1] <= 32'd0;
		Mult_op_2[1] <= 32'd0;
		Mult_op_1[2] <= 32'd0;
		Mult_op_2[2] <= 32'd0;
		
		temp <= 16'd0;
		
		U_odd <= 16'd0;
		V_odd <= 16'd0;
		
		SRAM_disable <= 1'b0;
		
		state <= S_IDLE_M1;
		
	end else begin
		case (state)
		S_IDLE_M1: begin
					
			SRAM_address <= 18'd0;
			SRAM_write_data_a <= 8'd0;
			SRAM_write_data_b <= 8'd0;
			SRAM_we_n <= 1'b1;
			
			y_counter <= 18'd0;	    // 16'd38400
			uv_counter <= 18'd0;    // 15'd19200
			rgb_counter <= 18'd0;   // 17'd115200
			pixel_counter <= 9'd0;  // 320px
			row_counter <= 8'd0;    // 240px
			flip <= 1'b1;
			
			Mult_op_1[0] <= 32'd0;
			Mult_op_2[0] <= 32'd0;
			Mult_op_1[1] <= 32'd0;
			Mult_op_2[1] <= 32'd0;
			Mult_op_1[2] <= 32'd0;
			Mult_op_2[2] <= 32'd0;
			
			RGB_buffer[0] <= 8'd0;
			RGB_buffer[1] <= 8'd0;
			RGB_buffer[2] <= 8'd0;
			
			Y_buffer <= 16'd0;
			
			U_buffer[0] <= 16'd0;
			U_buffer[1] <= 16'd0;
			U_buffer[2] <= 16'd0;
			U_buffer[3] <= 16'd0;
			
			V_buffer[0] <= 16'd0;
			V_buffer[1] <= 16'd0;
			V_buffer[2] <= 16'd0;
			V_buffer[3] <= 16'd0;
			
			temp <= 16'd0;
			
			U_odd <= 16'd0;
			V_odd <= 16'd0;
			
			if (SRAM_enable & !SRAM_disable) 
				state <= S_STATE_0;
		end
		
		S_STATE_0: begin	
				SRAM_address <= uv_counter + U_OFFSET;

				SRAM_we_n <= 1'b1;
				state <= S_STATE_1;		
		end
		S_STATE_1: begin    
				SRAM_address <= uv_counter + V_OFFSET;
	
				uv_counter <= uv_counter + 1'd1;		
				state <= S_STATE_2;			
		end
		S_STATE_2: begin	
				SRAM_address <= uv_counter + U_OFFSET;
	
				Y_buffer <= m1_read_data;
				state <= S_STATE_3;			
		end
		S_STATE_3: begin	
				SRAM_address <= uv_counter + V_OFFSET;
				
				U_buffer[0] <= m1_read_data;
				U_buffer[1] <= m1_read_data;
				
				uv_counter <= uv_counter + 1'd1;		
				state <= S_STATE_4;			
		end
		S_STATE_4: begin	
				SRAM_address <= uv_counter + U_OFFSET;
				
				V_buffer[0] <= m1_read_data;
				V_buffer[1] <= m1_read_data;
				
				state <= S_STATE_5;			
		end
		S_STATE_5: begin	
				SRAM_address <= uv_counter + V_OFFSET;
				
				U_buffer[2] <= m1_read_data;
				
				// 21*U3
				Mult_op_1[0]<= 5'd21;
				Mult_op_2[0]<= m1_read_data[15:8];
				// 52*U2
				Mult_op_1[1]<= -6'd52;
				Mult_op_2[1]<= m1_read_data[7:0];
				// 159*U1
				Mult_op_1[2]<= 8'd159;
				Mult_op_2[2]<= U_buffer[1][15:8];
				
				
				state <= S_STATE_6;			
		end
		S_STATE_6: begin	
				V_buffer[2] <= m1_read_data;
				
				// (21U3 - 52U2 + 159U1)
				U_odd <= add_Mult_012;
				
				// 21*U0
				Mult_op_1[0]<= 5'd21;
				Mult_op_2[0]<= U_buffer[1][7:0];
				// -52*U0
				Mult_op_1[1]<= -6'd52;
				Mult_op_2[1]<= U_buffer[1][7:0];
				// 159*U0
				Mult_op_1[2]<= 8'd159;
				Mult_op_2[2]<= U_buffer[1][7:0];
				
				state <= S_STATE_7;			
		end
		S_STATE_7: begin
				U_buffer[3] <= m1_read_data;
				
				// (21U3 - 52U2 + 159U + 21U0 - 52U0 + 159U0 + 128)/256
				U_odd <= (U_odd + add_Mult_012 + 8'd128)>>>8;
				
				// 21*V3
				Mult_op_1[0]<= 5'd21;
				Mult_op_2[0]<= V_buffer[2][15:8];
				// -52*V2
				Mult_op_1[1]<= -6'd52;
				Mult_op_2[1]<= V_buffer[2][7:0];
				// 159*V1
				Mult_op_1[2]<= 8'd159;
				Mult_op_2[2]<= V_buffer[1][15:8];
				
				state <= S_STATE_8;			
		end
		S_STATE_8: begin
				V_buffer[3] <= m1_read_data;
				
				// (21V3 - 52V2 + 159V1)
				V_odd <= add_Mult_012;
				
				// 21*V0
				Mult_op_1[0]<= 5'd21;
				Mult_op_2[0]<= V_buffer[1][7:0];
				// -52*V0
				Mult_op_1[1]<= -6'd52;
				Mult_op_2[1]<= V_buffer[1][7:0];
				// 159*V0
				Mult_op_1[2]<= 8'd159;
				Mult_op_2[2]<= V_buffer[1][7:0];
				
				y_counter <= y_counter + 1'd1;//1			
				state <= S_STATE_9;			
		end
		S_STATE_9: begin
				
				
				// (21V3 - 52V2 + 159V1 + 21V0 - 52V0 + 159V0)/256
				V_odd <= (V_odd + add_Mult_012 + 8'd128)>>>8;
				// 76284*(Y0-16)
				Mult_op_1[0]<= 17'd76284;
				Mult_op_2[0]<= (Y_buffer[7:0]- 5'd16);
				// 104595*(V0-128)
				Mult_op_1[1]<= 17'd104595;
				Mult_op_2[1]<= (V_buffer[1][7:0]- 8'd128);
				// 132251*(U0-128)
				Mult_op_1[2]<= 18'd132251;
				Mult_op_2[2]<= (U_buffer[1][7:0]- 8'd128);
				
				state <= S_STATE_10;			
		end
		S_STATE_10: begin
				SRAM_address <= y_counter;
				
				if(add_Mult_01[31] == 1'b1) //<0
					SRAM_write_data_a <= 8'd0;
				else if(add_Mult_01[31:16]>8'd255) //>255
					SRAM_write_data_a <= 8'd255;
				else
					SRAM_write_data_a <= add_Mult_01[31:16];
			
				// -25624*(V0-128)
				Mult_op_1[1]<= -15'd25624;
				Mult_op_2[1]<= (U_buffer[1][7:0]- 8'd128);
				// -53281*(U0-128)
				Mult_op_1[2]<= -16'd53281;
				Mult_op_2[2]<= (V_buffer[1][7:0]- 8'd128);
				
				if(add_Mult_02[31] == 1'b1) //<0
					RGB_buffer[0] <=8'd0;
				else if(add_Mult_02[31:16]>8'd255) //>255
					RGB_buffer[0] <= 8'd255;
				else
					RGB_buffer[0] <= add_Mult_02[31:16];
				
				
				state <= S_DELAY_STATE_1;			
		end
		S_DELAY_STATE_1: begin // Address 1
		
				SRAM_address <= rgb_counter + RGB_OFFSET; 
				
				if(add_Mult_012[31] == 1'b1) //<0
					SRAM_write_data_b <= 8'd0;
				else if(add_Mult_012[31:16]>8'd255) //>255
					SRAM_write_data_b <= 8'd255;
				else
					SRAM_write_data_b <= add_Mult_012[31:16]; 
				
				SRAM_we_n <= 1'b0;
				state <= S_STATE_11;
		
		end
		S_STATE_11: begin
				
				// 76284*(Y1-16)
				Mult_op_1[0]<= 17'd76284;
				Mult_op_2[0]<= (Y_buffer[15:8]- 5'd16);
				// 104595*(V_odd-128)
				Mult_op_1[1]<= 17'd104595;
				Mult_op_2[1]<= (V_odd[7:0]- 8'd128);
				// 132251*(U_odd-128)
				Mult_op_1[2]<= 18'd132251;
				Mult_op_2[2]<= (U_odd[7:0]- 8'd128);
				
				rgb_counter <= rgb_counter + 1'b1; 
				SRAM_we_n <= 1'b1;
				state <= S_STATE_12;			
		end
		S_STATE_12: begin
				Y_buffer = m1_read_data;
				
				SRAM_write_data_a <= (RGB_buffer[0]);
				
				if(add_Mult_01[31] == 1'b1) //<0
					SRAM_write_data_b <= 8'd0;
				else if(add_Mult_01[31:16]>8'd255) //>255
					SRAM_write_data_b <= 8'd255;
				else
					SRAM_write_data_b <= add_Mult_01[31:16];
				
				if(add_Mult_02[31] == 1'b1) //<0
					RGB_buffer[1] <=8'd0;				
				else if(add_Mult_02[31:16]>8'd255) //>255
					RGB_buffer[1] <= 8'd255;
				else
					RGB_buffer[1] <= add_Mult_02[31:16];
				
				// -25624*(U_odd-128)
				Mult_op_1[1]<= -15'd25624;
				Mult_op_2[1]<= (U_odd[7:0]- 8'd128);
				// -53281*(V_odd-128)
				Mult_op_1[2]<= -16'd53281;
				Mult_op_2[2]<= (V_odd[7:0]- 8'd128);
			
				
				SRAM_we_n <= 1'b0;				
				rgb_counter <= rgb_counter + 1'b1;
				SRAM_address <= rgb_counter + RGB_OFFSET;

				state <= S_STATE_13;		
		end
		S_STATE_13: begin
				if(add_Mult_012[31] == 1'b1) //<0
					SRAM_write_data_a <= 8'd0;
				else if(add_Mult_012[31:16]>8'd255) //>255
					SRAM_write_data_a <= 8'd255;
				else
					SRAM_write_data_a <= add_Mult_012[31:16]; 
					
				SRAM_write_data_b <= (RGB_buffer[1]);
				
				// 76284*(Y2-16)
				Mult_op_1[0]<= 17'd76284;
				Mult_op_2[0]<= (Y_buffer[7:0]- 5'd16);
				// 104595*(V1-128)
				Mult_op_1[1]<= 17'd104595;
				Mult_op_2[1]<= (V_buffer[1][15:8]- 8'd128);
				// 132251*(U1-128)
				Mult_op_1[2]<= 18'd132251;
				Mult_op_2[2]<= (U_buffer[1][15:8]- 8'd128);
				
				SRAM_address <= rgb_counter + RGB_OFFSET;
				rgb_counter <= rgb_counter + 1'b1;
				state <= S_STATE_14;			
		end
		S_STATE_14: begin
		
				if(add_Mult_01[31:16]>8'd255) //>255
					SRAM_write_data_a <= 8'd255;
				
				if(add_Mult_01[31] == 1'b1) //<0
					SRAM_write_data_a <= 8'd0;
				else
					SRAM_write_data_a <= add_Mult_01[31:16];
				
				// -25624*(U1-128)
				Mult_op_1[1]<= -15'd25624;
				Mult_op_2[1]<= (U_buffer[1][15:8]- 8'd128);
				// -53281*(V1-128)
				Mult_op_1[2]<= -16'd53281;
				Mult_op_2[2]<= (V_buffer[1][15:8]- 8'd128);
				if(add_Mult_02[31] == 1'b1) //<0
					RGB_buffer[2] <=8'd0;				
				else if(add_Mult_02[31:16]>8'd255) //>255
					RGB_buffer[2] <= 8'd255;

				else
					RGB_buffer[2] <= add_Mult_02[31:16];
					
				SRAM_we_n <= 1'b1;
				SRAM_address <= rgb_counter + RGB_OFFSET;
				pixel_counter <= 2'd3;
				flip <= 1'b1;
				uv_counter <= uv_counter + 1'b1;
				state <=S_DELAY_STATE_2;		
		end	
		S_DELAY_STATE_2: begin
				
				if(add_Mult_012[31:16]>8'd255) //>255
					SRAM_write_data_b <= 8'd255;
				
				if(add_Mult_012[31] == 1'b1) //<0
					SRAM_write_data_b <= 8'd0;
				else
					SRAM_write_data_b <= add_Mult_012[31:16];
					
				SRAM_we_n <= 1'b0;
				state <= S_STATE_15;
		end
		S_STATE_15: begin
				
				SRAM_we_n <= 1'b1;
				// First U
				
				if (flip) begin
					SRAM_address <= uv_counter + V_OFFSET;
					// 21*U
					Mult_op_1[0]<= 5'd21;
					Mult_op_2[0]<= (((pixel_counter+3'd5)>>1)<8'd159)? U_buffer[3][7:0] : U_buffer[3][15:8];
					// -52*U
					Mult_op_1[1]<= -6'd52;
					Mult_op_2[1]<= (((pixel_counter+2'd3)>>1)<8'd159)? U_buffer[2][15:8]: U_buffer[3][15:8];
					// 159*U
					Mult_op_1[2]<= 8'd159;
					Mult_op_2[2]<= (((pixel_counter+1'd1)>>1)<8'd159)? U_buffer[2][7:0]: U_buffer[3][15:8];
				end else begin
					// 21*U
					Mult_op_1[0]<= 5'd21;
					Mult_op_2[0]<= (((pixel_counter+3'd5)>>1)<8'd159)? U_buffer[2][15:8]: U_buffer[3][15:8];
					// -52*U
					Mult_op_1[1]<= -6'd52;
					Mult_op_2[1]<= (((pixel_counter+2'd3)>>1)<8'd159)? U_buffer[2][7:0] : U_buffer[3][15:8];
					// 159*U
					Mult_op_1[2]<= 8'd159;
					Mult_op_2[2]<= (((pixel_counter+1'd1)>>1)<8'd159)? U_buffer[1][15:8]: U_buffer[3][15:8];
				end
				
				state <= S_STATE_16;
		end
		S_STATE_16: begin
				U_odd <= add_Mult_012; 
				y_counter <= y_counter + 1'd1;
				
				if (flip) begin
					SRAM_address <= uv_counter + U_OFFSET;
					// 21*U
					Mult_op_1[0]<= 5'd21;
					Mult_op_2[0]<= (((pixel_counter-3'd5)>>1)>1'd0) ? U_buffer[0][15:8]: U_buffer[0][7:0];
					// -52*U
					Mult_op_1[1]<= -6'd52;
					Mult_op_2[1]<= (((pixel_counter-2'd3)>>1)>1'd0) ? U_buffer[1][7:0] : U_buffer[0][7:0];
					// 159*U
					Mult_op_1[2]<= 8'd159;
					Mult_op_2[2]<= (((pixel_counter-1'd1)>>1)>1'd0) ? U_buffer[1][15:8]: U_buffer[0][7:0];
				end else begin
					// 21*U
					Mult_op_1[0]<= 5'd21;
					Mult_op_2[0]<= (((pixel_counter-3'd5)>>1)>1'd0) ? U_buffer[0][7:0] : U_buffer[0][7:0];
					// -52*U
					Mult_op_1[1]<= -6'd52;
					Mult_op_2[1]<= (((pixel_counter-2'd3)>>1)>1'd0) ? U_buffer[0][15:8]: U_buffer[0][7:0];
					// 159*U
					Mult_op_1[2]<= 8'd159;
					Mult_op_2[2]<= (((pixel_counter-1'd1)>>1)>1'd0) ? U_buffer[1][7:0] : U_buffer[0][7:0];
				end
				
				state <= S_STATE_17;
		end
		S_STATE_17: begin
				U_odd <= (U_odd + add_Mult_012 + 8'd128)>>>8;
				SRAM_address <= y_counter;
				
				if (flip) begin
					// 21*U
					Mult_op_1[0]<= 5'd21;
					Mult_op_2[0]<= (((pixel_counter+3'd5)>>1)<8'd159)? V_buffer[3][7:0] : V_buffer[3][15:8];
					// -52*U
					Mult_op_1[1]<= -6'd52;
					Mult_op_2[1]<= (((pixel_counter+2'd3)>>1)<8'd159)? V_buffer[2][15:8]: V_buffer[3][15:8];
					// 159*U
					Mult_op_1[2]<= 8'd159;
					Mult_op_2[2]<= (((pixel_counter+1'd1)>>1)<8'd159)? V_buffer[2][7:0]: V_buffer[3][15:8];
				end else begin
					// 21*U
					Mult_op_1[0]<= 5'd21;
					Mult_op_2[0]<= (((pixel_counter+3'd5)>>1)<8'd159)? V_buffer[2][15:8]: V_buffer[3][15:8];
					// -52*U
					Mult_op_1[1]<= -6'd52;
					Mult_op_2[1]<= (((pixel_counter+2'd3)>>1)<8'd159)? V_buffer[2][7:0] : V_buffer[3][15:8];
					// 159*U
					Mult_op_1[2]<= 8'd159;
					Mult_op_2[2]<= (((pixel_counter+1'd1)>>1)<8'd159)? V_buffer[1][15:8]: V_buffer[3][15:8];
				end
				
				state <= S_STATE_18;
		end 
		S_STATE_18: begin
				// Second V
				V_odd <= add_Mult_012;
				
				if (flip) begin
					temp <= m1_read_data;
					// 21*U
					Mult_op_1[0]<= 5'd21;
					Mult_op_2[0]<= (((pixel_counter-3'd5)>>1)>1'd0) ? V_buffer[0][15:8]: V_buffer[0][7:0];
					// -52*U
					Mult_op_1[1]<= -6'd52;
					Mult_op_2[1]<= (((pixel_counter-2'd3)>>1)>1'd0) ? V_buffer[1][7:0] : V_buffer[0][7:0];
					// 159*U
					Mult_op_1[2]<= 8'd159;
					Mult_op_2[2]<= (((pixel_counter-1'd1)>>1)>1'd0) ? V_buffer[1][15:8]: V_buffer[0][7:0];
				end else begin
					// 21*U
					Mult_op_1[0]<= 5'd21;
					Mult_op_2[0]<= (((pixel_counter-3'd5)>>1)>1'd0) ? V_buffer[0][7:0] : V_buffer[0][7:0];
					// -52*U
					Mult_op_1[1]<= -6'd52;
					Mult_op_2[1]<= (((pixel_counter-2'd3)>>1)>1'd0) ? V_buffer[0][15:8]: V_buffer[0][7:0];
					// 159*U
					Mult_op_1[2]<= 8'd159;
					Mult_op_2[2]<= (((pixel_counter-1'd1)>>1)>1'd0) ? V_buffer[1][7:0] : V_buffer[0][7:0];
				end
				
				state <= S_STATE_19;
		end
		S_STATE_19: begin
				V_odd <= (V_odd + add_Mult_012 + 8'd128)>>>8;
				
				// 76284*(Y1-16)
				Mult_op_1[0]<= 17'd76284;
				Mult_op_2[0]<= (Y_buffer[15:8]- 5'd16);
				// 104595*(V_odd-128)
				Mult_op_1[1]<= 17'd104595;
				Mult_op_2[1]<= (((V_odd + add_Mult_012 + 8'd128)>>>8) - 8'd128);
				// 132251*(U_odd-128)
				Mult_op_1[2]<= 18'd132251;
				Mult_op_2[2]<= (U_odd[7:0] - 8'd128);
				
				
				// Shift Register
				if (flip && (((pixel_counter+3'd5)>>1)<8'd159)) begin
					U_buffer[0] <= U_buffer[1];
					V_buffer[0] <= V_buffer[1];
					U_buffer[1] <= U_buffer[2];
					V_buffer[1] <= V_buffer[2];
					U_buffer[2] <= U_buffer[3];
					V_buffer[2] <= V_buffer[3];
					U_buffer[3] <= m1_read_data;
					V_buffer[3] <= temp;
				end
				
				rgb_counter <= rgb_counter + 1'b1;
				state <= S_STATE_20;			
		end	
		S_STATE_20: begin
		

				SRAM_write_data_a <= RGB_buffer[2];
				if(add_Mult_01[31] == 1'b1) //<0
					SRAM_write_data_b <= 8'd0;
				else if(add_Mult_01[31:16]>8'd255) //>255
					SRAM_write_data_b <= 8'd255;

				else
					SRAM_write_data_b <= add_Mult_01[31:16];
				
				// -25624*(U_odd-128)
				Mult_op_1[1]<= -15'd25624;
				Mult_op_2[1]<= (U_odd- 8'd128);
				// -53281*(V_odd-128)
				Mult_op_1[2]<= -16'd53281;
				Mult_op_2[2]<= (V_odd- 8'd128);
				
				// Store Y data
				Y_buffer <= m1_read_data;
				if(add_Mult_02[31] == 1'b1) //<0
					RGB_buffer[1] <=8'd0;				
				else if(add_Mult_02[31:16]>8'd255) //>255
					RGB_buffer[1] <= 8'd255;

				else
					RGB_buffer[1] <= add_Mult_02[31:16];
					
				SRAM_address <= rgb_counter + RGB_OFFSET;
				rgb_counter <= rgb_counter + 1'b1;
				SRAM_we_n <= 1'b0;
				state <= S_STATE_21;			
		end	
		S_STATE_21: begin
				

				if(add_Mult_012[31] == 1'b1) //<0
					SRAM_write_data_a <= 8'd0;
				else if(add_Mult_012[31:16]>8'd255) //>255
					SRAM_write_data_a <= 8'd255;
				

				else
					SRAM_write_data_a <= add_Mult_012[31:16];
					

				SRAM_write_data_b <= RGB_buffer[1];
		

				// 76284*(Y1-16)
				Mult_op_1[0]<= 17'd76284;
				Mult_op_2[0]<= (Y_buffer[7:0]- 5'd16);
				if (flip) begin // First
					// 104595*(V_odd-128)
					Mult_op_1[1]<= 17'd104595;
					Mult_op_2[1]<= (V_buffer[1][7:0]- 8'd128);
					// 132251*(U_odd-128)
					Mult_op_1[2]<= 18'd132251;
					Mult_op_2[2]<= (U_buffer[1][7:0]- 8'd128);
				end else begin // Second
					// 104595*(V_odd-128)
					Mult_op_1[1]<= 17'd104595;
					Mult_op_2[1]<= (V_buffer[1][15:8]- 8'd128);
					// 132251*(U_odd-128)
					Mult_op_1[2]<= 18'd132251;
					Mult_op_2[2]<= (U_buffer[1][15:8]- 8'd128);
				end
				SRAM_address <= rgb_counter + RGB_OFFSET;
				rgb_counter <= rgb_counter + 1'b1;
				
				state <= S_STATE_22;	
		end	
		S_STATE_22: begin
				
				if(add_Mult_01[31] == 1'b1) //<0
					SRAM_write_data_a <= 8'd0;
					
				else if (add_Mult_01[31:16]>8'd255) //>255
					SRAM_write_data_a <= 8'd255;
				

				else
					SRAM_write_data_a <= add_Mult_01[31:16];
				
				if (flip) begin
					// -25624*(U_odd-128)
					Mult_op_1[1]<= -15'd25624;
					Mult_op_2[1]<= (U_buffer[1][7:0] - 8'd128);
					// -53281*(V_odd-128)
					Mult_op_1[2]<= -16'd53281;
					Mult_op_2[2]<= (V_buffer[1][7:0] - 8'd128);
				end else begin
					// -25624*(U_odd-128)
					Mult_op_1[1]<= -15'd25624;
					Mult_op_2[1]<= (U_buffer[1][15:8] - 8'd128);
					// -53281*(V_odd-128)
					Mult_op_1[2]<= -16'd53281;
					Mult_op_2[2]<= (V_buffer[1][15:8]- 8'd128);
				end
				
				if(add_Mult_02[31] == 1'b1)
					RGB_buffer[2] <=8'd0;
					
				else if(add_Mult_02[31:16]>8'd255)
					RGB_buffer[2] <= 8'd255;

				else
					RGB_buffer[2] <= add_Mult_02[31:16];
					
				SRAM_we_n <= 1'b1;
				SRAM_address <= rgb_counter + RGB_OFFSET;
				flip <= !flip;
				
				// Increment uv_counter every other common and if it does not exceed the row
				if (!flip && (((pixel_counter+3'd5)>>1)<8'd159)) 
					uv_counter <= uv_counter + 1'b1;

				state <= S_DELAY_STATE_3;
		end
		S_DELAY_STATE_3: begin
				if(add_Mult_012[31] == 1'b1) //<0
					SRAM_write_data_b <= 8'd0;
				else if(add_Mult_012[31:16]>8'd255) //>255
					SRAM_write_data_b <= 8'd255;
				else
					SRAM_write_data_b <= add_Mult_012[31:16];
				
				SRAM_we_n <= 1'b0;
				
				if (pixel_counter < 9'd317) begin
					state <= S_STATE_15;
					pixel_counter <= pixel_counter + 2'd2;
				end else 
					state <= S_STATE_23;
		end
		// Lead Out case
		S_STATE_23: begin
				
				SRAM_we_n <= 1'b1;
	
				// 21*U
				Mult_op_1[0]<= 5'd21;
				Mult_op_2[0]<= (((pixel_counter+3'd5)>>1)<8'd159)? U_buffer[3][7:0] : U_buffer[3][15:8];
				// -52*U
				Mult_op_1[1]<= -6'd52;
				Mult_op_2[1]<= (((pixel_counter+2'd3)>>1)<8'd159)? U_buffer[2][15:8]: U_buffer[3][15:8];
				// 159*U
				Mult_op_1[2]<= 8'd159;
				Mult_op_2[2]<= (((pixel_counter+1'd1)>>1)<8'd159)? U_buffer[2][7:0]: U_buffer[3][15:8];
				
				
				state <= S_STATE_24;
		end
		S_STATE_24: begin
				
				U_odd <= add_Mult_012;
				// 21*U
				Mult_op_1[0]<= 5'd21;
				Mult_op_2[0]<= (((pixel_counter-3'd5)>>1)>1'd0) ? U_buffer[0][15:8]: U_buffer[0][7:0];
				// -52*U
				Mult_op_1[1]<= -6'd52;
				Mult_op_2[1]<= (((pixel_counter-2'd3)>>1)>1'd0) ? U_buffer[1][7:0] : U_buffer[0][7:0];
				// 159*U
				Mult_op_1[2]<= 8'd159;
				Mult_op_2[2]<= (((pixel_counter-1'd1)>>1)>1'd0) ? U_buffer[1][15:8]: U_buffer[0][7:0];
				state <= S_STATE_25;
		end
		S_STATE_25: begin
				U_odd <= (U_odd + add_Mult_012 + 8'd128)>>>8;
		
				// 21*U
				Mult_op_1[0]<= 5'd21;
				Mult_op_2[0]<= (((pixel_counter+3'd5)>>1)<8'd159)? V_buffer[3][7:0] : V_buffer[3][15:8];
				// -52*U
				Mult_op_1[1]<= -6'd52;
				Mult_op_2[1]<= (((pixel_counter+2'd3)>>1)<8'd159)? V_buffer[2][15:8]: V_buffer[3][15:8];
				// 159*U
				Mult_op_1[2]<= 8'd159;
				Mult_op_2[2]<= (((pixel_counter+1'd1)>>1)<8'd159)? V_buffer[2][7:0]: V_buffer[3][15:8];
				state <= S_STATE_26;
		end	
		S_STATE_26: begin
				V_odd <= add_Mult_012;
				Mult_op_1[0]<= 5'd21;
				Mult_op_2[0]<= (((pixel_counter-3'd5)>>1)>1'd0) ? V_buffer[0][15:8]: V_buffer[0][7:0];
				// -52*U
				Mult_op_1[1]<= -6'd52;
				Mult_op_2[1]<= (((pixel_counter-2'd3)>>1)>1'd0) ? V_buffer[1][7:0] : V_buffer[0][7:0];
				// 159*U
				Mult_op_1[2]<= 8'd159;
				Mult_op_2[2]<= (((pixel_counter-1'd1)>>1)>1'd0) ? V_buffer[1][15:8]: V_buffer[0][7:0];
				state <= S_STATE_27;
		end
		
		S_STATE_27: begin
				V_odd <= (V_odd + add_Mult_012 + 8'd128)>>>8;
				
				// 76284*(Y1-16)
				Mult_op_1[0]<= 17'd76284;
				Mult_op_2[0]<= (Y_buffer[15:8]- 5'd16);
				// 104595*(V_odd-128)
				Mult_op_1[1]<= 17'd104595;
				Mult_op_2[1]<= ((V_odd + add_Mult_012 + 8'd128)>>>8 - 8'd128);
				// 132251*(U_odd-128)
				Mult_op_1[2]<= 18'd132251;
				Mult_op_2[2]<= (U_odd[7:0] - 8'd128);

				rgb_counter <= rgb_counter + 1'b1;
				state <= S_STATE_28;					
		end	

		S_STATE_28: begin
				
				SRAM_write_data_a <= RGB_buffer[2];
				
				if(add_Mult_01[31] == 1'b1) //<0
					SRAM_write_data_b <= 8'd0;
				else if(add_Mult_01[31:16]>8'd255) //>255
					SRAM_write_data_b <= 8'd255;
				else
					SRAM_write_data_b <= add_Mult_01[31:16];
				
				if(add_Mult_02[31] == 1'b1) //<0
					RGB_buffer[1]<= 8'd0;
				else if(add_Mult_02[31:16]>8'd255) //>255
					RGB_buffer[1]<= 8'd255;
				else
					RGB_buffer[1]<= add_Mult_02[31:16];
				
				// -25624*(U_odd-128)
				Mult_op_1[1]<= -15'd25624;
				Mult_op_2[1]<= (U_odd[7:0]- 8'd128);
				// -53281*(V_odd-128)
				Mult_op_1[2]<= -16'd53281;
				Mult_op_2[2]<= (V_odd[7:0]- 8'd128);
		
				SRAM_address <= rgb_counter + RGB_OFFSET; //rgb 9
				rgb_counter <= rgb_counter + 1'b1;	//10
				SRAM_we_n <= 1'b0;
				state <= S_STATE_29;			
		end	
		
		S_STATE_29: begin
				
				if(add_Mult_012[31] == 1'b1) //<0
					SRAM_write_data_a <= 8'd0;
				else if(add_Mult_012[31:16]>8'd255) //>255
					SRAM_write_data_a <= 8'd255;
				else
					SRAM_write_data_a <= add_Mult_012[31:16];
					
				SRAM_write_data_b <= RGB_buffer[1];
				
				y_counter <= y_counter + 1'b1;
				SRAM_address <= rgb_counter + RGB_OFFSET; //rgb 10
				state <= S_STATE_30;	
		end	

		S_STATE_30: begin
				SRAM_address <= y_counter; 
				pixel_counter <= 1'b0;
				
				if(row_counter < 8'd239) begin
					row_counter<= row_counter + 1'b1;
					rgb_counter<=rgb_counter +1'b1;
					state<=S_STATE_0;
					SRAM_we_n <= 1'b1;
				end else begin	
					SRAM_disable <= 1'b1;	
					state <= S_IDLE_M1;
				end
				
		end
		
		default: state <= S_IDLE_M1;
		endcase
	end
end

endmodule
