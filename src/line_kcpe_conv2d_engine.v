`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 03/17/2021 10:39:10 PM
// Design Name: Line kernel-channel-PE-based Convolution 2D Engine
// Module Name: line_kcpe_conv2d_engine
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: An array of 3 kernel-channel processing elements
//              to calculate MAC on 3 positions of 3 channel/4 kernel
//              in parallel
// 
// Dependencies: 
//  kernel_channel_pe
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module line_kcpe_conv2d_engine(
    clk,
    rst,
    i_data,
    i_data_val,
    i_weight,
    i_weight_val,
    i_psum,
    i_psum_val,
    o_psum,
    o_psum_val
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter BIT_WIDTH     = 8;
parameter NUM_CHANNEL   = 3;
parameter NUM_KERNEL    = 4;
parameter NUM_KCPE      = 3;    // Number of kernel-channel PE
parameter REG_WIDTH     = 32;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input  wire                                                clk;
input  wire                                                rst;
input  wire [(BIT_WIDTH * NUM_CHANNEL * NUM_KCPE) - 1 : 0] i_data;
input  wire [(BIT_WIDTH * NUM_KERNEL  * NUM_KCPE) - 1 : 0] i_weight;
input  wire [(BIT_WIDTH * NUM_KERNEL            ) - 1 : 0] i_psum;
input  wire                                                i_data_val;
input  wire                                                i_weight_val;
input  wire                                                i_psum_val;
output wire [(BIT_WIDTH * NUM_KERNEL            ) - 1 : 0] o_psum;
output wire [NUM_KERNEL - 1 : 0]                           o_psum_val;
output wire [REG_WIDTH * NUM_KCPE - 1 : 0]                 err_psum_val;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
kernel_channel_pe kernel_channel_pe_0(
    .clk            (clk),
    .rst            (rst),
    .i_data         (),
    .i_data_val     (),
    .i_weight       (),
    .i_weight_val   (),
    .i_psum         (),
    // .i_psum_val     (),
    .o_psum         (),
    .o_psum_val     (),
    .err_psum_val   ()
    );

//////////////////////////////////////////////////////////////////////////////////
// Error monitor

endmodule
