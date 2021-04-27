`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 04/27/2021 11:23:02 PM
// Design Name: 
// Module Name: accelerator_core_tb
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: accelerator core test bench
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module accelerator_core_tb;

parameter BIT_WIDTH     = 8;
parameter NUM_CHANNEL   = 3;
parameter NUM_KERNEL    = 4;
parameter NUM_KCPE      = 3;    // Number of kernel-channel PE
parameter REG_WIDTH     = 32;

parameter NUM_RDATA     = 3;

reg clk;
reg rst;
wire                                                  o_data_req;
wire [(BIT_WIDTH * NUM_CHANNEL             ) - 1 : 0] i_data;
wire [(BIT_WIDTH * NUM_CHANNEL * NUM_KERNEL) - 1 : 0] i_weight;
wire                                                  i_data_val;
wire                                                  i_weight_val;
wire [BIT_WIDTH - 1 : 0]                              o_psum_kn0;
wire [BIT_WIDTH - 1 : 0]                              o_psum_kn1;
wire [BIT_WIDTH - 1 : 0]                              o_psum_kn2;
wire [BIT_WIDTH - 1 : 0]                              o_psum_kn3;
wire                                                  o_psum_kn0_val;
wire                                                  o_psum_kn1_val;
wire                                                  o_psum_kn2_val;
wire                                                  o_psum_kn3_val;
reg [REG_WIDTH - 1 : 0]                               i_conf_ctrl;

accelerator_core uut(
    .clk            (clk),
    .rst            (rst),
    .o_data_req     (o_data_req),
    .i_data         (i_data),
    .i_data_val     (i_data_val),
    .i_weight       (i_weight),
    .i_weight_val   (i_weight_val),
    .o_psum_kn0     (o_psum_kn0),
    .o_psum_kn0_val (o_psum_kn0_val),
    .o_psum_kn1     (o_psum_kn1),
    .o_psum_kn1_val (o_psum_kn1_val),
    .o_psum_kn2     (o_psum_kn2),
    .o_psum_kn2_val (o_psum_kn2_val),
    .o_psum_kn3     (o_psum_kn3),
    .o_psum_kn3_val (o_psum_kn3_val),
    .i_conf_ctrl    (i_conf_ctrl)
    );

accelerator_core_tb_data_gen stimulus(
    .clk            (clk),
    .rst            (rst),
    .o_data_req     (o_data_req),
    .i_data         (i_data),
    .i_data_val     (i_data_val),
    .i_weight       (i_weight),
    .i_weight_val   (i_weight_val)
    );

initial begin
    clk <= 0;
    forever begin
        #5 clk <= ~clk;
    end
end

initial begin
    rst <= 1;
    #20 rst <= 0;
end

initial begin
    i_conf_ctrl <= 0;
    #50 i_conf_ctrl <= 32'b1;
end

endmodule
