`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 03/24/2021 02:46:28 PM
// Design Name: DNN Accelerator core wrapper
// Module Name: accelerator_core
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module accelerator_core(
    clk,
    rst,
    o_data_req,
    i_data,
    i_data_val,
    o_weight_req,
    i_weight,
    i_weight_val,
    o_psum_kn0,
    o_psum_kn0_val,
    o_psum_kn1,
    o_psum_kn1_val,
    o_psum_kn2,
    o_psum_kn2_val,
    o_psum_kn3,
    o_psum_kn3_val,
    i_conf_ctrl,
    i_conf_cnt,
    i_conf_knx,
    i_conf_weightinterval,
    i_conf_kernelsize
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
output wire                                                  o_weight_req;
input  wire [(BIT_WIDTH * NUM_CHANNEL             ) - 1 : 0] i_data;
input  wire [(BIT_WIDTH * NUM_CHANNEL * NUM_KERNEL) - 1 : 0] i_weight;
input  wire                                                  i_data_val;
input  wire                                                  i_weight_val;
output wire [BIT_WIDTH - 1 : 0]                              o_psum_kn0;
output wire [BIT_WIDTH - 1 : 0]                              o_psum_kn1;
output wire [BIT_WIDTH - 1 : 0]                              o_psum_kn2;
output wire [BIT_WIDTH - 1 : 0]                              o_psum_kn3;
output wire                                                  o_psum_kn0_val;
output wire                                                  o_psum_kn1_val;
output wire                                                  o_psum_kn2_val;
output wire                                                  o_psum_kn3_val;
input  wire [REG_WIDTH - 1 : 0]                              i_conf_ctrl;
input  wire [REG_WIDTH - 1 : 0]                              i_conf_cnt;
input  wire [REG_WIDTH - 1 : 0]                              i_conf_knx;
input  wire [REG_WIDTH - 1 : 0]                              i_conf_weightinterval;
input  wire [REG_WIDTH - 1 : 0]                              i_conf_kernelsize;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire [BIT_WIDTH - 1 : 0]                accum_i_psum [NUM_KERNEL - 1 : 0];
wire [NUM_KERNEL - 1 : 0]               accum_i_psum_val;
// wire [BIT_WIDTH - 1 : 0]                accum_o_psum [NUM_KERNEL - 1 : 0];
// wire [NUM_KERNEL - 1 : 0]               accum_o_psum_val;

// wire [(BIT_WIDTH * NUM_KERNEL) - 1 : 0] engine_i_psum;
// wire                                    engine_i_psum_val;

line_kcpe_conv2d_engine line_kcpe_conv2d_engine_0(
    .clk                    (clk),
    .rst                    (rst),
    .o_data_req             (o_data_req),
    .i_data                 (i_data),
    .i_data_val             (i_data_val),
    .o_weight_req           (o_weight_req),
    .i_weight               (i_weight),
    .i_weight_val           (i_weight_val),
    // .i_psum                 (engine_i_psum),
    // .i_psum_val             (engine_i_psum_val),
    .o_psum_kn0             (accum_i_psum[0]),
    .o_psum_kn0_val         (accum_i_psum_val[0]),
    .o_psum_kn1             (accum_i_psum[1]),
    .o_psum_kn1_val         (accum_i_psum_val[1]),
    .o_psum_kn2             (accum_i_psum[2]),
    .o_psum_kn2_val         (accum_i_psum_val[2]),
    .o_psum_kn3             (accum_i_psum[3]),
    .o_psum_kn3_val         (accum_i_psum_val[3]),
    .i_conf_ctrl            (i_conf_ctrl),
    .i_conf_weightinterval  (i_conf_weightinterval),
    .i_conf_kernelsize      (i_conf_kernelsize)
    );

psum_accumulator psum_accumulator_0(
    .clk             (clk),
    .rst             (rst),
    .i_conf_knx      (i_conf_knx),
    .i_conf_cnt      (i_conf_cnt),
    .i_psum_kn0      (accum_i_psum[0]),
    .i_psum_kn0_val  (accum_i_psum_val[0]),
    .i_psum_kn1      (accum_i_psum[1]),
    .i_psum_kn1_val  (accum_i_psum_val[1]),
    .i_psum_kn2      (accum_i_psum[2]),
    .i_psum_kn2_val  (accum_i_psum_val[2]),
    .i_psum_kn3      (accum_i_psum[3]),
    .i_psum_kn3_val  (accum_i_psum_val[3]),
    .o_psum_kn0      (o_psum_kn0),
    .o_psum_kn0_val  (o_psum_kn0_val),
    .o_psum_kn1      (o_psum_kn1),
    .o_psum_kn1_val  (o_psum_kn1_val),
    .o_psum_kn2      (o_psum_kn2),
    .o_psum_kn2_val  (o_psum_kn2_val),
    .o_psum_kn3      (o_psum_kn3),
    .o_psum_kn3_val  (o_psum_kn3_val)
    );


// Control logic


endmodule
