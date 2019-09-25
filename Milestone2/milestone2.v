

`timescale 1ns/100ps
`default_nettype none

`include "define_state.h"

module milestone2 (
		input logic CLOCK_50_I,                   // 50 MHz clock
		input logic resetn,
		
		input logic [15:0] SRAM_read_data,
		output logic [17:0] SRAM_address,
		output logic [15:0] SRAM_write_data,
		output logic SRAM_we_n,
		
		input logic m2_enable,
		output logic m2_disable
);

m2_state state;

logic [6:0] address_a[1:0];
logic [6:0] address_b[1:0];

logic [31:0] write_data_a [1:0]; // what is the size of this?
logic [31:0] write_data_b [1:0];

logic write_enable_a [1:0];
logic write_enable_b [1:0];

logic [31:0] read_data_a [1:0];
logic [31:0] read_data_b [1:0];

logic [3:0]row_counter;
logic [3:0]col_counter;
logic [3:0]mult_counter;

// Tracks the dimensions of the Pre-IDCT fetch
logic [3:0]fetch_counter_x;		// 7
logic [11:0]fetch_counter_y;	// 2240

logic [6:0]TS_counter_x;
logic [6:0]TS_counter_y;
logic signed [31:0]TS_accum[1:0];
logic [6:0] buffer_address;

// Offsets for reading from and writing to memory

logic [8:0] FETCH_BLOCK_X;
logic [16:0] FETCH_BLOCK_Y;

logic [8:0] WRITE_BLOCK_X;
logic [16:0] WRITE_BLOCK_Y;

parameter FETCH_S_OFFSET = 18'd76800,
		T_OFFSET = 7'd64;                 // SIZE 128 RAM. Half will be used to store T

assign write_data_a[0] = {{16{SRAM_read_data[15]}},SRAM_read_data};
		
logic signed [31:0] Mult_op_1  [1:0];
logic signed [31:0] Mult_op_2  [1:0];

// Multiplier Outputs
logic signed [31:0] Mult_result[1:0];
logic signed [63:0] Mult_result_long[1:0];

// Mult op logic
assign Mult_op_1[0] = (state == S_COMPUTE_T || state == MS_COMPUTE_T) ? read_data_a[0] : read_data_a[1];
assign Mult_op_2[0] = (state == S_COMPUTE_T || state == MS_COMPUTE_T) ? read_data_a[1] : read_data_b[0];
assign Mult_op_1[1] = (state == S_COMPUTE_T || state == MS_COMPUTE_T) ? read_data_b[0] : read_data_b[1];
assign Mult_op_2[1] = (state == S_COMPUTE_T || state == MS_COMPUTE_T) ? read_data_a[1] : read_data_b[0];
// Multiplier Outputs
assign Mult_result_long[0] = Mult_op_1[0] * Mult_op_2[0];
assign Mult_result_long[1] = Mult_op_1[1] * Mult_op_2[1];

// Truncated Multiplier Outputs
assign Mult_result[0] = Mult_result_long[0][31:0];
assign Mult_result[1] = Mult_result_long[1][31:0];

// Instantiate RAM0
dp_ram0 dp_ram0_inst0 (
	.address_a ( address_a[0] ),
	.address_b ( address_b[0] ),
	.clock ( CLOCK_50_I ),
	.data_a ( write_data_a[0] ),
	.data_b ( write_data_b[0] ),
	.wren_a ( write_enable_a[0] ),
	.wren_b ( write_enable_b[0] ),
	.q_a ( read_data_a[0] ),
	.q_b ( read_data_b[0] )
	);

// Instantiate RAM1
dp_ram1 dp_ram1_inst1(
	.address_a ( address_a[1] ),
	.address_b ( address_b[1] ),
	.clock ( CLOCK_50_I ),
	.data_a ( write_data_a[1] ),
	.data_b ( write_data_b[1] ),
	.wren_a ( write_enable_a[1] ),
	.wren_b ( write_enable_b[1] ),
	.q_a ( read_data_a[1] ),
	.q_b ( read_data_b[1] )
);

// FSM to control the read and write sequence
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		row_counter <= 4'd0;
		col_counter <= 4'd0;
		
		fetch_counter_x <= 4'd0;
		fetch_counter_y <= 12'd0;
		
			
		address_a[0] <= 7'd0;
		address_b[0] <= 7'd0;
		address_a[1] <= 7'd0;
		address_b[1] <= 7'd0;
		
		write_enable_a [0] <= 1'b0;
		write_enable_b [0] <= 1'b0;
		write_enable_a [1] <= 1'b0;
		write_enable_b [1] <= 1'b0;
				
		SRAM_address <= 18'd0;
		
		SRAM_we_n <= 1'b1;
		SRAM_write_data <= 16'd0;
		FETCH_BLOCK_X <= 9'd0;
		FETCH_BLOCK_Y <= 17'd0;
		m2_disable <= 1'b0;
		WRITE_BLOCK_X <= 9'd0;
		WRITE_BLOCK_Y <= 17'd0;
		state <= S_IDLE_M2;
	end else begin
		case (state)
		S_IDLE_M2: begin
			if (m2_enable && !m2_disable) begin
				state <= S_DELAY_M2_1;
				// Initalize S_FETCH_S_PRIME values
				
				address_a[0] <= 7'd0;
				SRAM_address <= FETCH_S_OFFSET;
				SRAM_we_n <= 1'b1;
				
				fetch_counter_x <= 1'd1;
				fetch_counter_y <= 12'd0;
				
				WRITE_BLOCK_X <= 9'd0;
				WRITE_BLOCK_Y <= 17'd0;
				
				FETCH_BLOCK_X <= 9'd0; // increments by 8 until 312
				FETCH_BLOCK_Y <= 17'd0; // increments by 2240 until 64960
				
			end else begin
				row_counter <= 4'd0;
				col_counter <= 4'd0;
				
				fetch_counter_x <= 4'd0;
				fetch_counter_y <= 12'd0;
				
				
				address_a[0] <= 7'd0;
				address_b[0] <= 7'd0;
				address_a[1] <= 7'd0;
				address_b[1] <= 7'd0;
				
				write_enable_a [0] <= 1'b0;
				write_enable_b [0] <= 1'b0;
				write_enable_a [1] <= 1'b0;
				write_enable_b [1] <= 1'b0;
				
				FETCH_BLOCK_X <= 9'd0; // increments by 7 until 280
				FETCH_BLOCK_Y <= 17'd0; // increments by 2240 until 67200
				
				SRAM_address <= 16'd0;
				
				SRAM_we_n <= 1'b1;
				SRAM_write_data <= 16'd0;
			end
		end
		S_DELAY_M2_1: begin
			SRAM_address <= (fetch_counter_x + fetch_counter_y + FETCH_S_OFFSET);
			fetch_counter_x <= fetch_counter_x + 1'd1;
			state <= S_DELAY_M2_2;
		end
		S_DELAY_M2_2: begin
			SRAM_address <= (fetch_counter_x + fetch_counter_y + FETCH_S_OFFSET);
			fetch_counter_x <= fetch_counter_x + 1'd1;
			write_enable_a[0] <= 1'b1;
			state <= S_FETCH_S_PRIME;
		end
		// LEAD IN CASE
		S_FETCH_S_PRIME: begin

			fetch_counter_x <= (fetch_counter_x == 3'd7) ? 4'd0 : (fetch_counter_x + 1'd1);
			fetch_counter_y <= (fetch_counter_x == 3'd7) ? (fetch_counter_y + 9'd320) : fetch_counter_y;
			SRAM_address <= (fetch_counter_x + fetch_counter_y + FETCH_S_OFFSET);
			address_a[0] <= address_a[0] + 1'd1;
			
			if ((fetch_counter_x + fetch_counter_y) > 12'd2560) begin
				state <= S_DELAY_FETCH;
			end
			
		end
		S_DELAY_FETCH: begin
		
				// increments by 8 until 312
				// increments by 2240 until 64960
				FETCH_BLOCK_X <= (FETCH_BLOCK_X == 9'd312) ? 9'd0 : FETCH_BLOCK_X + 4'd8;
				FETCH_BLOCK_Y <= (FETCH_BLOCK_X == 9'd312) ? FETCH_BLOCK_Y + 12'd2240 : FETCH_BLOCK_Y;
			
				write_enable_a[0] <= 1'b0;
				write_enable_b[0] <= 1'b0;
				write_enable_a[1] <= 1'b0;
				
				row_counter <= 1'd0;
				col_counter <= 1'd0;
				mult_counter <= 1'd0;
				
				TS_accum[0] <= 32'd0;
				TS_accum[1] <= 32'd0;
				TS_counter_x <= 7'd0;
				TS_counter_y <= 7'd0;
				
				address_a[0] <= 6'd0;
				address_b[0] <= 4'd8;
				address_a[1] <= 6'd0;
				
				buffer_address <= 6'd0;
				
				state <= S_COMPUTE_T;
		end
		S_COMPUTE_T: begin
			// Mult counters goes from 0-6, 7 cycles because the 1st was loaded the cycle before
			if (mult_counter < 4'd7) begin
				// Do Multiplications by counting the rows of S'
				address_a[0] <= address_a[0] + 1'd1; 
				address_b[0] <= address_b[0] + 1'd1;
				address_a[1] <= address_a[1] + 4'd8;
				
				if (mult_counter == 1'd0 && col_counter ==  1'd0) begin
					// do nothing
				end else begin
					TS_accum[0] <=  TS_accum[0] + {{8{Mult_result[0][31]}},Mult_result[0][31:8]};
					TS_accum[1] <=  TS_accum[1] + {{8{Mult_result[1][31]}},Mult_result[1][31:8]};
				end
				
				mult_counter <= mult_counter + 1'd1;
			end else if (mult_counter == 4'd7) begin
				// Set up writing T to Dual port RAM
				buffer_address <= address_b[0];
				
				TS_accum[1] <= TS_accum[1] + {{8{Mult_result[1][31]}},Mult_result[1][31:8]};
				
				write_data_b[0] <= TS_accum[0] + {{8{Mult_result[0][31]}},Mult_result[0][31:8]};
				address_b[0] <= ( TS_counter_x + TS_counter_y + T_OFFSET);
				write_enable_b[0] <= 1'b1;
				
				mult_counter <= mult_counter + 1'd1;
				
			end else if (mult_counter == 4'd8) begin
				// Write second value to dual port ram
				write_data_b[0] <= TS_accum[1];
				address_b[0] <= (4'd8 + TS_counter_x + TS_counter_y + T_OFFSET);
				
				TS_counter_x <= (TS_counter_x < 4'd7) ? TS_counter_x + 1'd1 : 4'd0;
				TS_counter_y <= (TS_counter_x < 4'd7) ? TS_counter_y : TS_counter_y + 5'd16;
				
				mult_counter <= mult_counter + 1'd1;
				
			end else if (mult_counter == 4'd9) begin
				// Decide the next step based on the column of C
				
				TS_accum[0] <= 32'd0;
				TS_accum[1] <= 32'd0;
				
				write_enable_b[0] <= 1'b0;
				
				if (col_counter < 3'd7) begin
					// The column refering to the C matrix is not the last Column
					col_counter <= col_counter + 1'd1;
					mult_counter <= 1'd0;

					address_a[0] <= address_a[0] - 4'd7; // Reset row
					address_b[0] <= buffer_address - 4'd7; // Reset row
					address_a[1] <= address_a[1] - 7'd55; // Next col

				end else if (col_counter == 3'd7 && row_counter != 2'd3) begin
					// The last column of the C matrix but not the last row
					col_counter <= 1'd0;
					mult_counter <= 1'd0;
					row_counter <= row_counter + 1'd1;
					
					address_a[0] <= address_a[0] + 4'd9; // Jump 2 rows 
					address_b[0] <= buffer_address + 4'd9; // Jump 2 rows
					address_a[1] <= address_a[1] - 7'd63; // Reset Col
					
				end else begin
					// The last row and the last column

					// Initilization for S_FETCH_S_PRIME
					address_a[0] <= 6'd0;
					SRAM_address <= FETCH_S_OFFSET + FETCH_BLOCK_X + FETCH_BLOCK_Y;
					SRAM_we_n <= 1'b1;
					fetch_counter_x <= 1'd1;
					fetch_counter_y <= 12'd0;
					
					// Initilization for S_COMPUTE_S
					write_enable_a[0] <= 1'b0; // S'
					write_enable_b[0] <= 1'b0; // T
					write_enable_a[1] <= 1'b0; // C
					write_enable_a[1] <= 1'b0; // S
					
					row_counter <= 1'd0;  // counts the mutiplied rows of the matrix
					col_counter <= 1'd0;  // counts the multiplied columns of the matrix
					mult_counter <= 1'd0; // counts the multiplication within the rows and columns
					
					TS_accum[0] <= 32'd0; // Accumulator for the 1st col multiplier value
					TS_accum[1] <= 32'd0; // Accumulator for the 2nd col multiplier value
					TS_counter_x <= 7'd0; // Keeps track of writing adresses in the x direction
					TS_counter_y <= 7'd0; // Keeps track of writing adresses in the y direction
					
					address_b[0] <= 6'd0; // Address for fetching T values
					address_a[1] <= 4'd0; // Address for fetching the first row of Ct values, column of C
					address_b[1] <= 6'd1; // Address for fetching the second row of Ct values, column of C
					
					buffer_address <= 6'd0;
					
					state <= S_DELAY_M2_3;
				end				
			end
		end
		S_DELAY_M2_3: begin
			SRAM_address <= (fetch_counter_x + fetch_counter_y + FETCH_S_OFFSET + FETCH_BLOCK_X + FETCH_BLOCK_Y);
			fetch_counter_x <= fetch_counter_x + 1'd1;
			state <= S_DELAY_M2_4;
		end
		
		S_DELAY_M2_4: begin
			SRAM_address <= (fetch_counter_x + fetch_counter_y + FETCH_S_OFFSET + FETCH_BLOCK_X + FETCH_BLOCK_Y);
			fetch_counter_x <= fetch_counter_x + 1'd1;
			state <= MS_COMPUTE_S;
		end
		
		// COMMON CASE
		MS_COMPUTE_S: begin
				
				/////////////////////////////////////////////////////////////////////////////////////////////////////////
				// 2560 is when fetch_counter_x = 0 and fetch_counter_y = 2560
				if ((fetch_counter_x + fetch_counter_y) < 12'd2560) begin
					fetch_counter_x <= (fetch_counter_x == 3'd7) ? 4'd0 : (fetch_counter_x + 1'd1);
					fetch_counter_y <= (fetch_counter_x == 3'd7) ? (fetch_counter_y + 9'd320) : fetch_counter_y;
					SRAM_address <= (fetch_counter_x + fetch_counter_y + FETCH_S_OFFSET + FETCH_BLOCK_X + FETCH_BLOCK_Y);
					address_a[0] <= address_a[0] + 1'd1;
				end else if ((fetch_counter_x + fetch_counter_y) < 12'd2562) begin
					// Add in delay states here since there is extra room
					fetch_counter_x <= fetch_counter_x + 1'd1;
					address_a[0] <= address_a[0] + 1'd1;
					// increments by 8 until 312
					// increments by 2240 until 64960
					FETCH_BLOCK_X <= (FETCH_BLOCK_X == 9'd312) ? 9'd0 : FETCH_BLOCK_X + 4'd8;
					FETCH_BLOCK_Y <= (FETCH_BLOCK_X == 9'd312) ? FETCH_BLOCK_Y + 12'd2240 : FETCH_BLOCK_Y;
				end else begin
					write_enable_a[0] <= 1'b0;
				end
				/////////////////////////////////////////////////////////////////////////////////////////////////////////
				
				// Mult counters goes from 0-6, 7 cycles because the 1st was loaded the cycle before
				if (mult_counter < 4'd7) begin
				
					address_b[0] <= address_b[0] + 4'd8;  
					address_a[1] <= address_a[1] + 4'd8; 
					address_b[1] <= address_b[1] + 4'd8; 
					
				if (mult_counter == 1'd0 && col_counter ==  1'd0)begin
					// do nothing
				end else begin
					TS_accum[0] <= TS_accum[0] + {{16{Mult_result[0][31]}},Mult_result[0][31:16]};
					TS_accum[1] <= TS_accum[1] + {{16{Mult_result[1][31]}},Mult_result[1][31:16]};
				end
					
					
					mult_counter <= mult_counter + 1'd1;
				end else if (mult_counter == 4'd7) begin
				
					buffer_address <= address_b[1];
					
					// May cause clipping
					write_data_b[1] <= {TS_accum[1][15:0] + Mult_result[1][31:16], 
										TS_accum[0][15:0] + Mult_result[0][31:16]};
										
					address_b[1] <= ( TS_counter_x + TS_counter_y + T_OFFSET);
					write_enable_b[1] <= 1'b1;
					
					mult_counter <= mult_counter + 1'd1;
					
					TS_counter_x <= (TS_counter_x < 4'd7) ? TS_counter_x + 1'd1 : 4'd0;
					TS_counter_y <= (TS_counter_x < 4'd7) ? TS_counter_y : TS_counter_y + 5'd8;
					
				end else begin

					TS_accum[0] <= 32'd0;
					TS_accum[1] <= 32'd0;
					
					write_enable_b[1] <= 1'b0;
					
					if (col_counter < 3'd7) begin

						col_counter <= col_counter + 1'd1;
						mult_counter <= 1'd0;

						address_b[0] <= address_b[0] - 6'd55;    
						address_a[1] <= address_a[1] - 6'd56;    
						address_b[1] <= buffer_address - 6'd56; 

					end else if (col_counter == 3'd7 && row_counter != 2'd3) begin
						// The last column of the C matrix but not the last row
						col_counter <= 1'd0;
						mult_counter <= 1'd0;
						row_counter <= row_counter + 1'd1;
						
						address_b[0] <= address_b[0]  - 7'd63; 
						address_a[1] <= address_a[1] - 6'd54; 
						address_b[1] <= buffer_address - 6'd54; 
						
					end else begin
						// The last row and the last column

						// Initilization for S_WRITE_S
						
						address_b[1] <= 7'd0;
						SRAM_address <= WRITE_BLOCK_X + WRITE_BLOCK_Y;
						
						fetch_counter_x <= 1'd0;  // fetch/write counter
						fetch_counter_y <= 12'd0;
						
						// Initilization for S_COMPUTE_T
						write_enable_a[0] <= 1'b0;
						write_enable_b[0] <= 1'b0;
						write_enable_a[1] <= 1'b0;
						
						row_counter <= 1'd0;
						col_counter <= 1'd0;
						mult_counter <= 1'd0;
						
						TS_accum[0] <= 32'd0;
						TS_accum[1] <= 32'd0;
						TS_counter_x <= 7'd0;
						TS_counter_y <= 7'd0;
						
						address_a[0] <= 6'd0;
						address_b[0] <= 4'd8;
						address_a[1] <= 6'd0;
						
						buffer_address <= 6'd0;
						

						state <= S_DELAY_M2_5;
						
					end				
				end
		end
		S_DELAY_M2_5: begin
			SRAM_address <= (fetch_counter_x + fetch_counter_y + WRITE_BLOCK_X + WRITE_BLOCK_Y);
			address_b[1] <= address_b[1] + 1'd1;
			SRAM_write_data <= read_data_b[1];
			SRAM_we_n <= 1'b0;
			state <= MS_COMPUTE_T;
		end
		MS_COMPUTE_T: begin
			if ((fetch_counter_x + fetch_counter_y) < 11'd1280) begin
				fetch_counter_x <= (fetch_counter_x == 2'd3) ? 2'd0 : (fetch_counter_x + 1'd1);
				fetch_counter_y <= (fetch_counter_x == 3'd3) ? (fetch_counter_y + 9'd160) : fetch_counter_y;
				SRAM_address <= (fetch_counter_x + fetch_counter_y + WRITE_BLOCK_X + WRITE_BLOCK_Y);
				SRAM_write_data <= read_data_b[1];
				address_b[1] <= address_b[1] + 1'd1;
			end else if ((fetch_counter_x + fetch_counter_y) < 11'd1281) begin
				fetch_counter_x <= fetch_counter_x + 1'd1;
				write_enable_a[0] <= 1'b0;
				// increments by 4 until 156
				// increments by 1120 until 32480
				WRITE_BLOCK_X <= (WRITE_BLOCK_X == 8'd156) ? 9'd0 : WRITE_BLOCK_X + 3'd4;
				WRITE_BLOCK_Y <= (WRITE_BLOCK_X == 8'd156) ? WRITE_BLOCK_Y + 11'd1120 : WRITE_BLOCK_Y;
			end 
			
			
			// Mult counters goes from 0-6, 7 cycles because the 1st was loaded the cycle before
			if (mult_counter < 4'd7) begin
				// Do Multiplications by counting the rows of S'
				address_a[0] <= address_a[0] + 1'd1; 
				address_b[0] <= address_b[0] + 1'd1;
				address_a[1] <= address_a[1] + 4'd8;
				
				TS_accum[0] <= TS_accum[0] + {{8{Mult_result[0][31]}},Mult_result[0][31:8]};
				TS_accum[1] <= TS_accum[1] + {{8{Mult_result[1][31]}},Mult_result[1][31:8]};
				
				mult_counter <= mult_counter + 1'd1;
			end else if (mult_counter == 4'd7) begin
				// Set up writing T to Dual port RAM
				buffer_address <= address_b[0];
				
				TS_accum[1] <= TS_accum[1] + {{8{Mult_result[1][31]}},Mult_result[1][31:8]};
				
				write_data_b[0] <= TS_accum[0] + {{8{Mult_result[0][31]}},Mult_result[0][31:8]};
				address_b[0] <= ( TS_counter_x + TS_counter_y + T_OFFSET);
				write_enable_b[0] <= 1'b1;
				
				mult_counter <= mult_counter + 1'd1;
				
			end else if (mult_counter == 4'd8) begin
				// Write second value to dual port ram
				write_data_b[0] <= TS_accum[1];
				address_b[0] <= (4'd8 + TS_counter_x + TS_counter_y + T_OFFSET);
				
				TS_counter_x <= (TS_counter_x < 4'd7) ? TS_counter_x + 1'd1 : 4'd0;
				TS_counter_y <= (TS_counter_x < 4'd7) ? TS_counter_y : TS_counter_y + 5'd16;
				
				mult_counter <= mult_counter + 1'd1;
				
			end else if (mult_counter == 4'd9) begin
				// Decide the next step based on the column of C
				
				TS_accum[0] <= 32'd0;
				TS_accum[1] <= 32'd0;
				
				write_enable_b[0] <= 1'b0;
				
				if (col_counter < 3'd7) begin
					// The column refering to the C matrix is not the last Column
					col_counter <= col_counter + 1'd1;
					mult_counter <= 1'd0;

					address_a[0] <= address_a[0] - 4'd7; // Reset row
					address_b[0] <= buffer_address - 4'd7; // Reset row
					address_a[1] <= address_a[1] - 7'd55; // Next col

				end else if (col_counter == 3'd7 && row_counter != 2'd3) begin
					// The last column of the C matrix but not the last row
					col_counter <= 1'd0;
					mult_counter <= 1'd0;
					row_counter <= row_counter + 1'd1;
					
					address_a[0] <= address_a[0] + 4'd9; // Jump 2 rows 
					address_b[0] <= buffer_address + 4'd9; // Jump 2 rows
					address_a[1] <= address_a[1] - 7'd63; // Reset Col
					
				end else begin
					// The last row and the last column

					// Initilization for S_FETCH_S_PRIME
					address_a[0] <= 6'd0;
					SRAM_address <= FETCH_S_OFFSET + FETCH_BLOCK_X + FETCH_BLOCK_Y;
					SRAM_we_n <= 1'b1;
					fetch_counter_x <= 1'd1;
					fetch_counter_y <= 12'd0;
					
					// Initilization for S_COMPUTE_S
					write_enable_a[0] <= 1'b0; // S'
					write_enable_b[0] <= 1'b0; // T
					write_enable_a[1] <= 1'b0; // C
					write_enable_a[1] <= 1'b0; // S
					
					row_counter <= 1'd0;  // counts the mutiplied rows of the matrix
					col_counter <= 1'd0;  // counts the multiplied columns of the matrix
					mult_counter <= 1'd0; // counts the multiplication within the rows and columns
					
					TS_accum[0] <= 32'd0; // Accumulator for the 1st col multiplier value
					TS_accum[1] <= 32'd0; // Accumulator for the 2nd col multiplier value
					TS_counter_x <= 7'd0; // Keeps track of writing adresses in the x direction
					TS_counter_y <= 7'd0; // Keeps track of writing adresses in the y direction
					
					address_b[0] <= 6'd0; // Address for fetching T values
					address_a[1] <= 4'd0; // Address for fetching the first row of Ct values, column of C
					address_b[1] <= 6'd1; // Address for fetching the second row of Ct values, column of C
					
					buffer_address <= 6'd0;
					
					if (FETCH_BLOCK_Y < 16'd64960)
						state <=S_DELAY_M2_3;
					else
						state <= S_COMPUTE_S;
					
				end				
			end
		end
		// END OF COMMON CASE
		// LEAD OUT CASE
		S_COMPUTE_S: begin
			/////////////////////////////////////////////////////////////////////////////////////////////////////////
			// 2560 is when fetch_counter_x = 0 and fetch_counter_y = 2560
			if ((fetch_counter_x + fetch_counter_y) < 12'd2560) begin
				fetch_counter_x <= (fetch_counter_x == 3'd7) ? 4'd0 : (fetch_counter_x + 1'd1);
				fetch_counter_y <= (fetch_counter_x == 3'd7) ? (fetch_counter_y + 9'd320) : fetch_counter_y;
				SRAM_address <= (fetch_counter_x + fetch_counter_y + FETCH_S_OFFSET + FETCH_BLOCK_X + FETCH_BLOCK_Y);
				address_a[0] <= address_a[0] + 1'd1;
			end else if ((fetch_counter_x + fetch_counter_y) < 12'd2562) begin
				// Add in delay states here since there is extra room
				fetch_counter_x <= fetch_counter_x + 1'd1;
				address_a[0] <= address_a[0] + 1'd1;
				// increments by 8 until 312
				// increments by 2240 until 64960
				FETCH_BLOCK_X <= (FETCH_BLOCK_X == 9'd312) ? 9'd0 : FETCH_BLOCK_X + 4'd8;
				FETCH_BLOCK_Y <= (FETCH_BLOCK_X == 9'd312) ? FETCH_BLOCK_Y + 12'd2240 : FETCH_BLOCK_Y;
			end else begin
				write_enable_a[0] <= 1'b0;
			end
			/////////////////////////////////////////////////////////////////////////////////////////////////////////
			
			// Mult counters goes from 0-6, 7 cycles because the 1st was loaded the cycle before
			if (mult_counter < 4'd7) begin
			
				address_b[0] <= address_b[0] + 4'd8;  
				address_a[1] <= address_a[1] + 4'd8; 
				address_b[1] <= address_b[1] + 4'd8; 
				
				TS_accum[0] <= TS_accum[0] + {{16{Mult_result[0][31]}},Mult_result[0][31:16]};
				TS_accum[1] <= TS_accum[1] + {{16{Mult_result[1][31]}},Mult_result[1][31:16]};
				
				mult_counter <= mult_counter + 1'd1;
			end else if (mult_counter == 4'd7) begin
			
				buffer_address <= address_b[1];
				
				// May cause clipping
				write_data_b[1] <= {TS_accum[1][15:0] + Mult_result[1][31:16], 
									TS_accum[0][15:0] + Mult_result[0][31:16]};
									
				address_b[1] <= ( TS_counter_x + TS_counter_y + T_OFFSET);
				write_enable_b[1] <= 1'b1;
				
				mult_counter <= mult_counter + 1'd1;
				
				TS_counter_x <= (TS_counter_x < 4'd7) ? TS_counter_x + 1'd1 : 4'd0;
				TS_counter_y <= (TS_counter_x < 4'd7) ? TS_counter_y : TS_counter_y + 5'd8;
				
			end else begin

				TS_accum[0] <= 32'd0;
				TS_accum[1] <= 32'd0;
				
				write_enable_b[1] <= 1'b0;
				
				if (col_counter < 3'd7) begin

					col_counter <= col_counter + 1'd1;
					mult_counter <= 1'd0;

					address_b[0] <= address_b[0] - 6'd55;    
					address_a[1] <= address_a[1] - 6'd56;    
					address_b[1] <= buffer_address - 6'd56; 

				end else if (col_counter == 3'd7 && row_counter != 2'd3) begin
					// The last column of the C matrix but not the last row
					col_counter <= 1'd0;
					mult_counter <= 1'd0;
					row_counter <= row_counter + 1'd1;
					
					address_b[0] <= address_b[0]  - 7'd63; 
					address_a[1] <= address_a[1] - 6'd54; 
					address_b[1] <= buffer_address - 6'd54; 
					
				end else begin
					// The last row and the last column

					// Initilization for S_WRITE_S
					
					address_b[1] <= 7'd0;
					SRAM_address <= WRITE_BLOCK_X + WRITE_BLOCK_Y;
					
					fetch_counter_x <= 1'd0;  // fetch/write counter
					fetch_counter_y <= 12'd0;
					
					// Initilization for S_COMPUTE_T
					write_enable_a[0] <= 1'b0;
					write_enable_b[0] <= 1'b0;
					write_enable_a[1] <= 1'b0;
					
					row_counter <= 1'd0;
					col_counter <= 1'd0;
					mult_counter <= 1'd0;
					
					TS_accum[0] <= 32'd0;
					TS_accum[1] <= 32'd0;
					TS_counter_x <= 7'd0;
					TS_counter_y <= 7'd0;
					
					address_a[0] <= 6'd0;
					address_b[0] <= 4'd8;
					address_a[1] <= 6'd0;
					
					buffer_address <= 6'd0;
					

					state <= S_WRITE_S;
					
				end				
			end
			
		end
		S_WRITE_S: begin
			/////////////////////////////////////////////////////////////////////////////////////////////////////////
			// 2560 is when fetch_counter_x = 0 and fetch_counter_y = 2560
			if ((fetch_counter_x + fetch_counter_y) < 12'd2560) begin
				fetch_counter_x <= (fetch_counter_x == 3'd7) ? 4'd0 : (fetch_counter_x + 1'd1);
				fetch_counter_y <= (fetch_counter_x == 3'd7) ? (fetch_counter_y + 9'd320) : fetch_counter_y;
				SRAM_address <= (fetch_counter_x + fetch_counter_y + FETCH_S_OFFSET + FETCH_BLOCK_X + FETCH_BLOCK_Y);
				address_a[0] <= address_a[0] + 1'd1;
			end else begin
				write_enable_a[0] <= 1'b0;
				m2_disable <= 1'b1;
				state <= S_COMPUTE_S;
			end
		end
		default: state <= S_IDLE_M2;
		endcase
	end
end

endmodule
