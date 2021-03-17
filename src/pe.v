`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 17/03/2021 14:38:00 PM
// Design Name: Processing element - MAC
// Module Name: pe
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: processing element - mac
// 
// Dependencies: 
//  mult_gen_0 : Xilinx Multiplier IP v12 - 8 bit
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module pe (
    clk,
    i_data,
    i_data_val,
    i_weight,
    i_weight_val,
    i_psum,
    i_psum_val,
    o_psum,
    o_psum_val
    );

parameter BIT_WIDTH = 8;
parameter MUL_LAT   = 3;

input  wire [BIT_WIDTH - 1:0] i_data;
input  wire [BIT_WIDTH - 1:0] i_weight;
input  wire [BIT_WIDTH - 1:0] i_psum;
input  wire                   i_data_val;
input  wire                   i_weight_val;
input  wire                   i_psum_val;
output wire [BIT_WIDTH - 1:0] o_psum;
output wire                   o_psum_val;

reg  [BIT_WIDTH - 1:0] data_reg;
reg  [BIT_WIDTH - 1:0] weight_reg;
reg  [BIT_WIDTH - 1:0] psum_reg;

reg  [MUL_LAT : 0]     o_psum_val_reg;

wire [BIT_WIDTH - 1:0] mul_res;

// Store data
always @(posedge clk) begin
    if (i_data_val) data_reg <= i_data;
    if (i_weight_val) weight_reg <= i_weight;
    if (i_psum_val) psum_reg <= i_psum;
end

// Multiplier
// Pipeline: 3
mult_gen_0 mul0(
    .CLK(clk),
    .A  (data_reg),
    .B  (weight_reg),
    .P  (mul_res)
    );

// Adder
assign o_psum = i_psum + mul_res;

// Output valid - o_psum_val
// Num pipeline stage = Muliplier's latency + 1
always @(posedge clk) begin
    o_psum_val_reg[0] <= i_data_val;
    o_psum_val_reg[1] <= o_psum_val_reg[0];
    o_psum_val_reg[2] <= o_psum_val_reg[1];
    o_psum_val_reg[3] <= o_psum_val_reg[3];
end

assign o_psum_val = o_psum_val_reg[3];

endmodule
