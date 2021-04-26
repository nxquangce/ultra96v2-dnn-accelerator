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
    o_data_req,
    i_data,
    i_data_val,
    o_weight_req,
    i_weight,
    i_weight_val,
    // i_psum,
    // i_psum_val,
    o_psum_kn0,
    o_psum_kn0_val,
    o_psum_kn1,
    o_psum_kn1_val,
    o_psum_kn2,
    o_psum_kn2_val,
    o_psum_kn3,
    o_psum_kn3_val
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
input  wire                                                  clk;
input  wire                                                  rst;
output wire                                                  o_data_req;
input  wire [(BIT_WIDTH * NUM_CHANNEL             ) - 1 : 0] i_data;
output wire                                                  o_weight_req;
input  wire [(BIT_WIDTH * NUM_CHANNEL * NUM_KERNEL) - 1 : 0] i_weight;
// input  wire [(BIT_WIDTH * NUM_KERNEL              ) - 1 : 0] i_psum;
input  wire                                                  i_data_val;
input  wire                                                  i_weight_val;
// input  wire                                                  i_psum_val;
// output wire [(BIT_WIDTH * NUM_KERNEL              ) - 1 : 0] o_psum;
// output wire [NUM_KERNEL - 1 : 0]                             o_psum_val;
output wire [BIT_WIDTH - 1 : 0]                              o_psum_kn0;
output wire [BIT_WIDTH - 1 : 0]                              o_psum_kn1;
output wire [BIT_WIDTH - 1 : 0]                              o_psum_kn2;
output wire [BIT_WIDTH - 1 : 0]                              o_psum_kn3;
output wire                                                  o_psum_kn0_val;
output wire                                                  o_psum_kn1_val;
output wire                                                  o_psum_kn2_val;
output wire                                                  o_psum_kn3_val;
// output wire [REG_WIDTH * NUM_KCPE - 1 : 0]      err_psum_val;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
// Input signals
wire [BIT_WIDTH - 1 : 0]               i_data_ch0;
wire [BIT_WIDTH - 1 : 0]               i_data_ch1;
wire [BIT_WIDTH - 1 : 0]               i_data_ch2;
wire [BIT_WIDTH * NUM_RDATA - 1 : 0]   buffer_o_data_ch0;
wire [BIT_WIDTH * NUM_RDATA - 1 : 0]   buffer_o_data_ch1;
wire [BIT_WIDTH * NUM_RDATA - 1 : 0]   buffer_o_data_ch2;
wire                                   buffer_o_data_ch0_val;
wire                                   buffer_o_data_ch1_val;
wire                                   buffer_o_data_ch2_val;
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0] engine_i_data_pos0;
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0] engine_i_data_pos1;
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0] engine_i_data_pos2;
// Weight signals
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0]              i_weight_kn0;
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0]              i_weight_kn1;
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0]              i_weight_kn2;
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0]              i_weight_kn3;

wire [BIT_WIDTH * NUM_CHANNEL * NUM_RDATA - 1 : 0]  buffer_o_weight_3ch3pos_kn0;
wire [BIT_WIDTH * NUM_CHANNEL * NUM_RDATA - 1 : 0]  buffer_o_weight_3ch3pos_kn1;
wire [BIT_WIDTH * NUM_CHANNEL * NUM_RDATA - 1 : 0]  buffer_o_weight_3ch3pos_kn2;
wire [BIT_WIDTH * NUM_CHANNEL * NUM_RDATA - 1 : 0]  buffer_o_weight_3ch3pos_kn3;
wire                                                buffer_o_weight_3ch3pos_kn0_val;
wire                                                buffer_o_weight_3ch3pos_kn1_val;
wire                                                buffer_o_weight_3ch3pos_kn2_val;
wire                                                buffer_o_weight_3ch3pos_kn3_val;

wire [BIT_WIDTH * NUM_CHANNEL * NUM_KERNEL - 1 : 0] engine_i_weight_3ch3kn_pos0;
wire [BIT_WIDTH * NUM_CHANNEL * NUM_KERNEL - 1 : 0] engine_i_weight_3ch3kn_pos1;
wire [BIT_WIDTH * NUM_CHANNEL * NUM_KERNEL - 1 : 0] engine_i_weight_3ch3kn_pos2;

// Psum out signals
wire [BIT_WIDTH * NUM_KERNEL - 1 : 0] engin_o_psum_kcpe0;
wire [BIT_WIDTH * NUM_KERNEL - 1 : 0] engin_o_psum_kcpe1;
wire [BIT_WIDTH * NUM_KERNEL - 1 : 0] engin_o_psum_kcpe2;
wire                                  engin_o_psum_kcpe0_val;
wire                                  engin_o_psum_kcpe1_val;
wire                                  engin_o_psum_kcpe2_val;



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
    .o_data_req       (o_data_req),
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

// Weight Buffer
assign i_weight_kn0 = i_weight[BIT_WIDTH * NUM_CHANNEL - 1 : 0];
assign i_weight_kn1 = i_weight[BIT_WIDTH * NUM_CHANNEL * 2 - 1 : BIT_WIDTH * NUM_CHANNEL];
assign i_weight_kn2 = i_weight[BIT_WIDTH * NUM_CHANNEL * 3 - 1 : BIT_WIDTH * NUM_CHANNEL * 2];
assign i_weight_kn3 = i_weight[BIT_WIDTH * NUM_CHANNEL * 4 - 1 : BIT_WIDTH * NUM_CHANNEL * 3];

weight_buffer weight_buffer_0(
    .clk                (clk),
    .rst                (rst),
    .i_data_kn0         (i_weight_kn0),
    .i_data_kn0_val     (i_weight_val),
    .i_data_kn1         (i_weight_kn1),
    .i_data_kn1_val     (i_weight_val),
    .i_data_kn2         (i_weight_kn2),
    .i_data_kn2_val     (i_weight_val),
    .i_data_kn3         (i_weight_kn3),
    .i_data_kn3_val     (i_weight_val),
    .o_data_req         (o_weight_req),
    .o_data_3ch_kn0     (buffer_o_weight_3ch3pos_kn0),
    .o_data_3ch_kn0_val (buffer_o_weight_3ch3pos_kn0_val),
    .o_data_3ch_kn1     (buffer_o_weight_3ch3pos_kn1),
    .o_data_3ch_kn1_val (buffer_o_weight_3ch3pos_kn1_val),
    .o_data_3ch_kn2     (buffer_o_weight_3ch3pos_kn2),
    .o_data_3ch_kn2_val (buffer_o_weight_3ch3pos_kn2_val),
    .o_data_3ch_kn3     (buffer_o_weight_3ch3pos_kn3),
    .o_data_3ch_kn3_val (buffer_o_weight_3ch3pos_kn3_val)
    );

// Convert weight from kernel to position
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0] buffer_o_weight [NUM_KERNEL - 1 : 0][NUM_RDATA - 1 : 0];

genvar idxIwPos;
generate
    for (idxIwPos = 0; idxIwPos < NUM_KCPE; idxIwPos = idxIwPos + 1) begin
        assign buffer_o_weight[0][idxIwPos] = buffer_o_weight_3ch3pos_kn0[BIT_WIDTH * ((idxIwPos + 1) * NUM_CHANNEL) - 1: BIT_WIDTH * idxIwPos * NUM_CHANNEL];
        assign buffer_o_weight[1][idxIwPos] = buffer_o_weight_3ch3pos_kn1[BIT_WIDTH * ((idxIwPos + 1) * NUM_CHANNEL) - 1: BIT_WIDTH * idxIwPos * NUM_CHANNEL];
        assign buffer_o_weight[2][idxIwPos] = buffer_o_weight_3ch3pos_kn2[BIT_WIDTH * ((idxIwPos + 1) * NUM_CHANNEL) - 1: BIT_WIDTH * idxIwPos * NUM_CHANNEL];
        assign buffer_o_weight[3][idxIwPos] = buffer_o_weight_3ch3pos_kn3[BIT_WIDTH * ((idxIwPos + 1) * NUM_CHANNEL) - 1: BIT_WIDTH * idxIwPos * NUM_CHANNEL];
    end
endgenerate

assign engine_i_weight_3ch3kn_pos0 = {buffer_o_weight[3][0], buffer_o_weight[2][0], buffer_o_weight[1][0], buffer_o_weight[0][0]};
assign engine_i_weight_3ch3kn_pos1 = {buffer_o_weight[3][1], buffer_o_weight[2][1], buffer_o_weight[1][1], buffer_o_weight[0][1]};
assign engine_i_weight_3ch3kn_pos2 = {buffer_o_weight[3][2], buffer_o_weight[2][2], buffer_o_weight[1][2], buffer_o_weight[0][2]};

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
    .i_weight       (engine_i_weight_3ch3kn_pos0),
    .i_weight_val   (buffer_o_weight_3ch3pos_kn0_val),
    .i_psum         (0),
    // .i_psum_val     (),
    .o_psum         (engin_o_psum_kcpe0),
    .o_psum_val     (engin_o_psum_kcpe0_val),
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
    .i_weight       (engine_i_weight_3ch3kn_pos1),
    .i_weight_val   (buffer_o_weight_3ch3pos_kn0_val),
    .i_psum         (0),
    // .i_psum_val     (),
    .o_psum         (engin_o_psum_kcpe1),
    .o_psum_val     (engin_o_psum_kcpe1_val),
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
    .i_weight       (engine_i_weight_3ch3kn_pos2),
    .i_weight_val   (buffer_o_weight_3ch3pos_kn0_val),
    .i_psum         (0),
    // .i_psum_val     (),
    .o_psum         (engin_o_psum_kcpe2),
    .o_psum_val     (engin_o_psum_kcpe2_val),
    .err_psum_val   ()
    );

// Psum output
result_router result_router_0(
    .clk                (clk),
    .rst                (rst),
    .i_psum_kcpe0       (engin_o_psum_kcpe0),
    .i_psum_kcpe0_val   (engin_o_psum_kcpe0_val),
    .i_psum_kcpe1       (engin_o_psum_kcpe1),
    .i_psum_kcpe1_val   (engin_o_psum_kcpe1_val),
    .i_psum_kcpe2       (engin_o_psum_kcpe2),
    .i_psum_kcpe2_val   (engin_o_psum_kcpe2_val),
    .o_psum_kn0         (o_psum_kn0),
    .o_psum_kn0_val     (o_psum_kn0_val),
    .o_psum_kn1         (o_psum_kn1),
    .o_psum_kn1_val     (o_psum_kn1_val),
    .o_psum_kn2         (o_psum_kn2),
    .o_psum_kn2_val     (o_psum_kn2_val),
    .o_psum_kn3         (o_psum_kn3),
    .o_psum_kn3_val     (o_psum_kn3_val)
    );    

//////////////////////////////////////////////////////////////////////////////////
// Error monitor

endmodule
