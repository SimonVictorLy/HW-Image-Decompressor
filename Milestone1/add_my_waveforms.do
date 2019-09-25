

# add waves to waveform
add wave Clock_50
add wave -divider {Project Variables}

add wave -unsigned uut/SRAM_address
add wave uut/SRAM_we_n

add wave -divider {Milestone 1}
add wave -decimal uut/m1_unit/state

add wave -divider {reads and writes}
add wave -hexadecimal uut/m1_unit/SRAM_read_data;

add wave -hexadecimal uut/m1_unit/SRAM_write_data_a;
add wave -hexadecimal uut/m1_unit/SRAM_write_data_b;

add wave -divider {Counters}
add wave -unsigned uut/m1_unit/y_counter
add wave -unsigned uut/m1_unit/uv_counter
add wave -unsigned uut/m1_unit/rgb_counter
add wave -unsigned uut/m1_unit/pixel_counter
add wave -unsigned uut/m1_unit/row_counter

add wave -divider {Buffers}
add wave -hexadecimal uut/m1_unit/Y_buffer
add wave -hexadecimal uut/m1_unit/U_buffer
add wave -hexadecimal uut/m1_unit/V_buffer
add wave -hexadecimal uut/m1_unit/RGB_buffer
add wave -hexadecimal uut/m1_unit/temp

add wave -divider {Multipliers}
add wave -decimal uut/m1_unit/U_odd
add wave -decimal uut/m1_unit/V_odd

add wave -decimal uut/m1_unit/Mult_result
add wave -hexadecimal uut/m1_unit/Mult_result

add wave -hexadecimal uut/m1_unit/Mult_op_1
add wave -hexadecimal uut/m1_unit/Mult_op_2

add wave -decimal uut/m1_unit/Mult_op_1
add wave -decimal uut/m1_unit/Mult_op_2

