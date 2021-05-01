`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 04/30/2021 10:59:07 PM
// Design Name: 
// Module Name: accelerator_core_tb1_tb
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: accelerator core test bench with data req, bram sim
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module accelerator_core_tb1_tb;

parameter BIT_WIDTH     = 8;
parameter NUM_CHANNEL   = 3;
parameter NUM_KERNEL    = 4;
parameter NUM_KCPE      = 3;    // Number of kernel-channel PE
parameter REG_WIDTH     = 32;

parameter NUM_RDATA     = 3;

parameter ADDR_WIDTH    = 32;
parameter DATA_WIDTH    = 32;

reg clk;
reg rst;
wire                                                  o_data_req;
wire                                                  o_data_end;
wire                                                  o_weight_req;
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
reg [REG_WIDTH - 1 : 0]                               i_conf_cnt;
reg [REG_WIDTH - 1 : 0]                               i_conf_knx;
reg [REG_WIDTH - 1 : 0]                               i_conf_weightinterval;
reg [REG_WIDTH - 1 : 0]                               i_conf_kernelshape;
reg [REG_WIDTH - 1 : 0]                               i_conf_inputshape;


accelerator_core uut(
    .clk                    (clk),
    .rst                    (rst),
    .o_data_req             (o_data_req),
    .o_data_end             (o_data_end),
    .i_data                 (i_data),
    .i_data_val             (i_data_val),
    .o_weight_req           (o_weight_req),
    .i_weight               (i_weight),
    .i_weight_val           (i_weight_val),
    .o_psum_kn0             (o_psum_kn0),
    .o_psum_kn0_val         (o_psum_kn0_val),
    .o_psum_kn1             (o_psum_kn1),
    .o_psum_kn1_val         (o_psum_kn1_val),
    .o_psum_kn2             (o_psum_kn2),
    .o_psum_kn2_val         (o_psum_kn2_val),
    .o_psum_kn3             (o_psum_kn3),
    .o_psum_kn3_val         (o_psum_kn3_val),
    .i_conf_ctrl            (i_conf_ctrl),
    .i_conf_cnt             (i_conf_cnt),
    .i_conf_knx             (i_conf_knx),
    .i_conf_weightinterval  (i_conf_weightinterval),
    .i_conf_kernelshape     (i_conf_kernelshape),
    .i_conf_inputshape      (i_conf_inputshape)
    );

wire                      stall;
wire [ADDR_WIDTH - 1 : 0] addr;
wire                      rden;
wire [DATA_WIDTH - 1 : 0] raw_rd_data;
wire [DATA_WIDTH - 1 : 0] mem_rd_data;
wire                      raw_rd_vld;
wire [ADDR_WIDTH - 1 : 0] mem_rd_addr;

data_req data_req0(
    .clk        (clk),
    .rst        (rst),
    .i_req      (o_data_req),
    .i_stall    (stall),
    .i_end      (o_data_end),
    .o_addr     (addr),
    .o_rden     (rden)
    );

bram_ctrl bram_ctrl0(
    .clk        (clk),
    .rst        (rst),
    .addr       (addr),
    .wren       (0),
    .idat       (0),
    .rden       (rden),
    .odat       (raw_rd_data),
    .oval       (raw_rd_vld),
    .mem_addr   (mem_rd_addr),
    .mem_idat   (),
    .mem_odat   (mem_rd_data),
    .mem_enb    (),
    .mem_rst    (),
    .mem_wen    ()
    );

data_bram_tb_sim bram0(
    .clk        (clk),
    .rst        (rst),
    .irdaddr    (mem_rd_addr),
    .odat       (mem_rd_data)
    );

pixel_concat concat(
    .clk        (clk),
    .rst        (rst),
    .idat       (raw_rd_data),
    .ival       (raw_rd_vld),
    .odat       (i_data),
    .oval       (i_data_val),
    .ostall     (stall)
    );

accelerator_core_tb_data_gen weigth_stimulus(
    .clk            (clk),
    .rst            (rst),
    .o_data_req     (o_data_req),
    .i_data         (),
    .i_data_val     (),
    .o_weight_req   (o_weight_req),
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

localparam WEIGHT_INTERVAL = 50176 - 2 * 222;
initial begin
    i_conf_ctrl <= 0;
    i_conf_cnt <= 0;
    i_conf_knx <= 0;
    i_conf_weightinterval <= 0;
    i_conf_kernelshape <= 0;
    i_conf_inputshape <= 0;

    #50 
    i_conf_ctrl <= 32'b1;
    i_conf_cnt <= 32'd50176;
    i_conf_knx <= 32'hffffffff;
    i_conf_weightinterval <= WEIGHT_INTERVAL;
    i_conf_kernelshape <= 32'h0020_0333;
    i_conf_inputshape <= 32'h0001_03e0;
end

endmodule