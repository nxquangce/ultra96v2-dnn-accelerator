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

parameter NUM_RDATA     = 3;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input  wire                                     clk;
input  wire                                     rst;
input  wire [(BIT_WIDTH * NUM_CHANNEL) - 1 : 0] i_data;
input  wire [(BIT_WIDTH * NUM_KERNEL ) - 1 : 0] i_weight;
input  wire [(BIT_WIDTH * NUM_KERNEL ) - 1 : 0] i_psum;
input  wire                                     i_data_val;
input  wire                                     i_weight_val;
input  wire                                     i_psum_val;
output wire [(BIT_WIDTH * NUM_KERNEL ) - 1 : 0] o_psum;
output wire [NUM_KERNEL - 1 : 0]                o_psum_val;
// output wire [REG_WIDTH * NUM_KCPE - 1 : 0]      err_psum_val;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire [BIT_WIDTH - 1 : 0] i_data_ch0;
wire [BIT_WIDTH - 1 : 0] i_data_ch1;
wire [BIT_WIDTH - 1 : 0] i_data_ch2;
wire [BIT_WIDTH * NUM_RDATA - 1 : 0] buffer_o_data_ch0;
wire [BIT_WIDTH * NUM_RDATA - 1 : 0] buffer_o_data_ch1;
wire [BIT_WIDTH * NUM_RDATA - 1 : 0] buffer_o_data_ch2;
wire                                 buffer_o_data_ch0_val;
wire                                 buffer_o_data_ch1_val;
wire                                 buffer_o_data_ch2_val;
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0] engine_i_data_pos0;
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0] engine_i_data_pos1;
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0] engine_i_data_pos2;

// Split input data into channels
assign i_data_ch0 = i_data[BIT_WIDTH     - 1 : 0];
assign i_data_ch1 = i_data[BIT_WIDTH * 2 - 1 : BIT_WIDTH];
assign i_data_ch2 = i_data[BIT_WIDTH * 3 - 1 : BIT_WIDTH * 2];

// Activation input buffer
input_buffer input_buffer_0(
    .clk              (clk),
    .rst              (rst),
    .i_data_ch0       (i_data_ch0),
    .i_data_ch0_val   (i_data_val),
    .i_data_ch1       (i_data_ch1),
    .i_data_ch1_val   (i_data_val),
    .i_data_ch2       (i_data_ch2),
    .i_data_ch2_val   (i_data_val),
    .o_data_req       (),
    .o_data_ch0       (buffer_o_data_ch0),
    .o_data_ch0_val   (buffer_o_data_ch0_val),
    .o_data_ch1       (buffer_o_data_ch1),
    .o_data_ch1_val   (buffer_o_data_ch1_val),
    .o_data_ch2       (buffer_o_data_ch2),
    .o_data_ch2_val   (buffer_o_data_ch2_val),
    .data_counter_ch0 (),
    .data_counter_ch1 (),
    .data_counter_ch2 ()
    );

// Convert position/channel into channel/position
wire [BIT_WIDTH - 1 : 0] buffer_o_data [NUM_KCPE - 1 : 0][NUM_CHANNEL - 1 : 0];

genvar idxPos;
generate
    for (idxPos = 0; idxPos < NUM_KCPE; idxPos = idxPos + 1) begin
        assign buffer_o_data[idxPos][0] = buffer_o_data_ch0[BIT_WIDTH - 1 : 0];
        assign buffer_o_data[idxPos][1] = buffer_o_data_ch1[BIT_WIDTH * 2 - 1 : BIT_WIDTH];
        assign buffer_o_data[idxPos][2] = buffer_o_data_ch2[BIT_WIDTH * 3 - 1 : BIT_WIDTH * 2];
    end
endgenerate

// Data in position
assign engine_i_data_pos0 = {buffer_o_data[0][2], buffer_o_data[0][1], buffer_o_data[0][0]};
assign engine_i_data_pos1 = {buffer_o_data[1][2], buffer_o_data[1][1], buffer_o_data[1][0]};
assign engine_i_data_pos2 = {buffer_o_data[2][2], buffer_o_data[2][1], buffer_o_data[2][0]};

// KC PE 0
kernel_channel_pe 
    #(
    .NUM_CHANNEL    (NUM_CHANNEL),
    .BIT_WIDTH      (BIT_WIDTH),
    .NUM_KERNEL     (NUM_KERNEL),
    .REG_WIDTH      (REG_WIDTH)
    )
kernel_channel_pe_0
    (
    .clk            (clk),
    .rst            (rst),
    .i_data         (engine_i_data_pos0),
    .i_data_val     (buffer_o_data_ch0_val),
    .i_weight       (),
    .i_weight_val   (),
    .i_psum         (),
    // .i_psum_val     (),
    .o_psum         (),
    .o_psum_val     (),
    .err_psum_val   ()
    );

// KC PE 1
kernel_channel_pe 
    #(
    .NUM_CHANNEL    (NUM_CHANNEL),
    .BIT_WIDTH      (BIT_WIDTH),
    .NUM_KERNEL     (NUM_KERNEL),
    .REG_WIDTH      (REG_WIDTH)
    )
kernel_channel_pe_1
    (
    .clk            (clk),
    .rst            (rst),
    .i_data         (engine_i_data_pos1),
    .i_data_val     (buffer_o_data_ch1_val),
    .i_weight       (),
    .i_weight_val   (),
    .i_psum         (),
    // .i_psum_val     (),
    .o_psum         (),
    .o_psum_val     (),
    .err_psum_val   ()
    );

// KC PE 2
kernel_channel_pe 
    #(
    .NUM_CHANNEL    (NUM_CHANNEL),
    .BIT_WIDTH      (BIT_WIDTH),
    .NUM_KERNEL     (NUM_KERNEL),
    .REG_WIDTH      (REG_WIDTH)
    )
kernel_channel_pe_2
    (
    .clk            (clk),
    .rst            (rst),
    .i_data         (engine_i_data_pos2),
    .i_data_val     (buffer_o_data_ch2_val),
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
