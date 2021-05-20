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
    rst,
    i_data,
    i_data_vld,
    i_weight,
    i_weight_vld,
    i_psum,
    // i_psum_vld,
    o_psum,
    o_psum_vld
    );

parameter BIT_WIDTH = 8;
parameter MUL_LAT   = 3;

input  wire                         clk;
input  wire                         rst;
input  wire [BIT_WIDTH - 1:0]       i_data;
input  wire [BIT_WIDTH - 1:0]       i_weight;
input  wire [BIT_WIDTH * 2 - 1:0]   i_psum;
input  wire                         i_data_vld;
input  wire                         i_weight_vld;
// input  wire                   i_psum_vld;
output wire [BIT_WIDTH * 2  - 1:0]  o_psum;
output wire                         o_psum_vld;

reg  [BIT_WIDTH - 1:0] data_reg;
reg  [BIT_WIDTH - 1:0] weight_reg;
// reg  [BIT_WIDTH - 1:0] psum_reg;

wire [BIT_WIDTH * 2 - 1:0] mul_res;

reg  [MUL_LAT : 0]     o_psum_vld_reg;

// Store data
always @(posedge clk) begin
    if (rst) begin
        data_reg    <= 0;
        weight_reg  <= 0;
        // psum_reg    <= 0;
    end
    else begin
        if (i_data_vld) data_reg <= i_data;
        if (i_weight_vld) weight_reg <= i_weight;
        // if (i_psum_vld) psum_reg <= i_psum;
    end
end

// Multiplier
// Pipeline: 3
mult_gen_0 i_mul(
    .CLK(clk),
    .A  (data_reg),
    .B  (weight_reg),
    .P  (mul_res)
    );

// Adder
assign o_psum = i_psum + mul_res;

// Output valid - o_psum_vld
// Num pipeline stage = Muliplier's latency + 1
always @(posedge clk) begin
    if (rst) begin
        o_psum_vld_reg <= 0;
    end
    else begin
        o_psum_vld_reg[0] <= i_data_vld;
        o_psum_vld_reg[1] <= o_psum_vld_reg[0];
        o_psum_vld_reg[2] <= o_psum_vld_reg[1];
        o_psum_vld_reg[3] <= o_psum_vld_reg[2];
    end
end

assign o_psum_vld = o_psum_vld_reg[3];

endmodule
