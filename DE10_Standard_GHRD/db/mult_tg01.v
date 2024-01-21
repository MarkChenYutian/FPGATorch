//lpm_mult CBX_DECLARE_ALL_CONNECTED_PORTS="OFF" DEDICATED_MULTIPLIER_CIRCUITRY="NO" DEVICE_FAMILY="Cyclone V" DSP_BLOCK_BALANCING="Auto" INPUT_A_IS_CONSTANT="NO" INPUT_B_IS_CONSTANT="NO" LPM_REPRESENTATION="UNSIGNED" LPM_WIDTHA=4 LPM_WIDTHB=4 LPM_WIDTHP=8 LPM_WIDTHS=1 MAXIMIZE_SPEED=5 dataa datab result CARRY_CHAIN="MANUAL" CARRY_CHAIN_LENGTH=48
//VERSION_BEGIN 16.1 cbx_cycloneii 2017:01:11:18:30:33:SJ cbx_lpm_add_sub 2017:01:11:18:30:33:SJ cbx_lpm_mult 2017:01:11:18:30:33:SJ cbx_mgl 2017:01:11:19:37:47:SJ cbx_nadder 2017:01:11:18:30:33:SJ cbx_padd 2017:01:11:18:30:33:SJ cbx_stratix 2017:01:11:18:30:33:SJ cbx_stratixii 2017:01:11:18:30:33:SJ cbx_util_mgl 2017:01:11:18:30:33:SJ  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 2017  Intel Corporation. All rights reserved.
//  Your use of Intel Corporation's design tools, logic functions 
//  and other software and tools, and its AMPP partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Intel Program License 
//  Subscription Agreement, the Intel Quartus Prime License Agreement,
//  the Intel MegaCore Function License Agreement, or other 
//  applicable license agreement, including, without limitation, 
//  that your use is for the sole purpose of programming logic 
//  devices manufactured by Intel and sold by Intel or its 
//  authorized distributors.  Please refer to the applicable 
//  agreement for further details.




//adder CBX_DECLARE_ALL_CONNECTED_PORTS="OFF" DEVICE_FAMILY="Cyclone V" WIDTH=7 dataa datab datac result
//VERSION_BEGIN 16.1 cbx_mgl 2017:01:11:19:37:47:SJ cbx_stratixii 2017:01:11:18:30:33:SJ cbx_util_mgl 2017:01:11:18:30:33:SJ  VERSION_END


//lpm_add_sub CARRY_CHAIN="MANUAL" CARRY_CHAIN_LENGTH=48 CBX_DECLARE_ALL_CONNECTED_PORTS="OFF" DEVICE_FAMILY="Cyclone V" LPM_REPRESENTATION="UNSIGNED" LPM_WIDTH=5 dataa datab result
//VERSION_BEGIN 16.1 cbx_cycloneii 2017:01:11:18:30:33:SJ cbx_lpm_add_sub 2017:01:11:18:30:33:SJ cbx_mgl 2017:01:11:19:37:47:SJ cbx_nadder 2017:01:11:18:30:33:SJ cbx_stratix 2017:01:11:18:30:33:SJ cbx_stratixii 2017:01:11:18:30:33:SJ  VERSION_END


//lpm_add_sub CARRY_CHAIN="MANUAL" CARRY_CHAIN_LENGTH=48 CBX_DECLARE_ALL_CONNECTED_PORTS="OFF" DEVICE_FAMILY="Cyclone V" LPM_REPRESENTATION="UNSIGNED" LPM_WIDTH=5 dataa datab result
//VERSION_BEGIN 16.1 cbx_cycloneii 2017:01:11:18:30:33:SJ cbx_lpm_add_sub 2017:01:11:18:30:33:SJ cbx_mgl 2017:01:11:19:37:47:SJ cbx_nadder 2017:01:11:18:30:33:SJ cbx_stratix 2017:01:11:18:30:33:SJ cbx_stratixii 2017:01:11:18:30:33:SJ  VERSION_END

//synthesis_resources = lut 24 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  mult_tg01
	( 
	dataa,
	datab,
	result) /* synthesis synthesis_clearbox=1 */;
	input   [3:0]  dataa;
	input   [3:0]  datab;
	output   [7:0]  result;

	wire	[6:0]	wire_add2_result;
	wire	[4:0]	wire_sum_adder1aa_0dataa;
	wire	[4:0]	wire_sum_adder1aa_0datab;
	wire	[4:0]	wire_sum_adder1aa_0result;
	wire	[4:0]	wire_sum_adder1aa_1dataa;
	wire	[4:0]	wire_sum_adder1aa_1datab;
	wire	[4:0]	wire_sum_adder1aa_1result;
	wire  [6:0]   wire_sft3a_in;
	wire  [6:0]   wire_sft3a_out;
	wire  [6:0]   wire_sft4a_in;
	wire  [6:0]   wire_sft4a_out;
	wire  [6:0]   wire_sft5a_in;
	wire  [6:0]   wire_sft5a_out;
	wire  [6:0]   wire_sft6a_in;
	wire  [6:0]   wire_sft6a_out;
	wire  [3:0]  dataa_node;
	wire  [3:0]  datab_node;
	wire  [7:0]  final_result_node;
	wire  [8:0]  w110w;
	wire  w80w;
	wire  [15:0]  w_decoder_node9w;
	wire  [3:0]  w_le_datab_node8w;
	wire  [11:0]  w_sum_node10w;

	assign
		wire_add2_result = wire_sft3a_out + wire_sft4a_out + wire_sft5a_out;
	assign
		wire_sum_adder1aa_0result = wire_sum_adder1aa_0dataa + wire_sum_adder1aa_0datab;
	assign
		wire_sum_adder1aa_0dataa = {1'b0, w_decoder_node9w[7:4]},
		wire_sum_adder1aa_0datab = {{2{1'b0}}, w_decoder_node9w[3:1]};
	assign
		wire_sum_adder1aa_1result = wire_sum_adder1aa_1dataa + wire_sum_adder1aa_1datab;
	assign
		wire_sum_adder1aa_1dataa = {1'b0, w_decoder_node9w[15:12]},
		wire_sum_adder1aa_1datab = {{2{1'b0}}, w_decoder_node9w[11:9]};
	soft   sft3a_0
	( 
	.in(wire_sft3a_in[0:0]),
	.out(wire_sft3a_out[0:0]));
	soft   sft3a_1
	( 
	.in(wire_sft3a_in[1:1]),
	.out(wire_sft3a_out[1:1]));
	soft   sft3a_2
	( 
	.in(wire_sft3a_in[2:2]),
	.out(wire_sft3a_out[2:2]));
	soft   sft3a_3
	( 
	.in(wire_sft3a_in[3:3]),
	.out(wire_sft3a_out[3:3]));
	soft   sft3a_4
	( 
	.in(wire_sft3a_in[4:4]),
	.out(wire_sft3a_out[4:4]));
	soft   sft3a_5
	( 
	.in(wire_sft3a_in[5:5]),
	.out(wire_sft3a_out[5:5]));
	soft   sft3a_6
	( 
	.in(wire_sft3a_in[6:6]),
	.out(wire_sft3a_out[6:6]));
	assign
		wire_sft3a_in = {w80w, {w_sum_node10w[11], {w_sum_node10w[10], {w_sum_node10w[5], {w_sum_node10w[4], {w_sum_node10w[3:2]}}}}}};
	soft   sft4a_0
	( 
	.in(wire_sft4a_in[0:0]),
	.out(wire_sft4a_out[0:0]));
	soft   sft4a_1
	( 
	.in(wire_sft4a_in[1:1]),
	.out(wire_sft4a_out[1:1]));
	soft   sft4a_2
	( 
	.in(wire_sft4a_in[2:2]),
	.out(wire_sft4a_out[2:2]));
	soft   sft4a_3
	( 
	.in(wire_sft4a_in[3:3]),
	.out(wire_sft4a_out[3:3]));
	soft   sft4a_4
	( 
	.in(wire_sft4a_in[4:4]),
	.out(wire_sft4a_out[4:4]));
	soft   sft4a_5
	( 
	.in(wire_sft4a_in[5:5]),
	.out(wire_sft4a_out[5:5]));
	soft   sft4a_6
	( 
	.in(wire_sft4a_in[6:6]),
	.out(wire_sft4a_out[6:6]));
	assign
		wire_sft4a_in = {w80w, {w80w, {w80w, {w_sum_node10w[9], {w_sum_node10w[8], {w_sum_node10w[7:6]}}}}}};
	soft   sft5a_0
	( 
	.in(wire_sft5a_in[0:0]),
	.out(wire_sft5a_out[0:0]));
	soft   sft5a_1
	( 
	.in(wire_sft5a_in[1:1]),
	.out(wire_sft5a_out[1:1]));
	soft   sft5a_2
	( 
	.in(wire_sft5a_in[2:2]),
	.out(wire_sft5a_out[2:2]));
	soft   sft5a_3
	( 
	.in(wire_sft5a_in[3:3]),
	.out(wire_sft5a_out[3:3]));
	soft   sft5a_4
	( 
	.in(wire_sft5a_in[4:4]),
	.out(wire_sft5a_out[4:4]));
	soft   sft5a_5
	( 
	.in(wire_sft5a_in[5:5]),
	.out(wire_sft5a_out[5:5]));
	soft   sft5a_6
	( 
	.in(wire_sft5a_in[6:6]),
	.out(wire_sft5a_out[6:6]));
	assign
		wire_sft5a_in = {w80w, {w80w, {w80w, {w80w, {w80w, {2{w80w}}}}}}};
	soft   sft6a_0
	( 
	.in(wire_sft6a_in[0:0]),
	.out(wire_sft6a_out[0:0]));
	soft   sft6a_1
	( 
	.in(wire_sft6a_in[1:1]),
	.out(wire_sft6a_out[1:1]));
	soft   sft6a_2
	( 
	.in(wire_sft6a_in[2:2]),
	.out(wire_sft6a_out[2:2]));
	soft   sft6a_3
	( 
	.in(wire_sft6a_in[3:3]),
	.out(wire_sft6a_out[3:3]));
	soft   sft6a_4
	( 
	.in(wire_sft6a_in[4:4]),
	.out(wire_sft6a_out[4:4]));
	soft   sft6a_5
	( 
	.in(wire_sft6a_in[5:5]),
	.out(wire_sft6a_out[5:5]));
	soft   sft6a_6
	( 
	.in(wire_sft6a_in[6:6]),
	.out(wire_sft6a_out[6:6]));
	assign
		wire_sft6a_in = wire_add2_result;
	assign
		dataa_node = {dataa[3:0]},
		datab_node = {datab[3:0]},
		final_result_node = {w110w[7:0]},
		result = {final_result_node[7:0]},
		w110w = {wire_sft6a_out[6:5], wire_sft6a_out[4:3], wire_sft6a_out[2:1], wire_sft6a_out[0], w_sum_node10w[1], w_sum_node10w[0]},
		w80w = 1'b0,
		w_decoder_node9w = {({dataa_node[3:0]} & {4{w_le_datab_node8w[3]}}), ({dataa_node[3:0]} & {4{w_le_datab_node8w[2]}}), ({dataa_node[3:0]} & {4{w_le_datab_node8w[1]}}), ({dataa_node[3:0]} & {4{w_le_datab_node8w[0]}})},
		w_le_datab_node8w = {datab_node[3:0]},
		w_sum_node10w = {wire_sum_adder1aa_1result[4:0], w_decoder_node9w[8], wire_sum_adder1aa_0result[4:0], w_decoder_node9w[0]};
endmodule //mult_tg01
//VALID FILE
