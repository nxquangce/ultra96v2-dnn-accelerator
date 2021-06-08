`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 05/11/2021 01:10:45 PM
// Design Name: 
// Module Name: accelerator_core_tb2_tb
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


module dnn_accelerator_core_tb;

parameter BIT_WIDTH     = 8;
parameter NUM_CHANNEL   = 3;
parameter NUM_KERNEL    = 4;
parameter NUM_KCPE      = 3;    // Number of kernel-channel PE
parameter REG_WIDTH     = 32;

parameter NUM_RDATA     = 3;

parameter ADDR_WIDTH    = 32;
parameter DATA_WIDTH    = 32;
parameter NUM_BYTE      = 4;

reg clk;
reg rst;

reg [REG_WIDTH - 1 : 0] i_conf_ctrl;
reg [REG_WIDTH - 1 : 0] i_conf_cnt;
reg [REG_WIDTH - 1 : 0] i_conf_kernelsize;
reg [REG_WIDTH - 1 : 0] i_conf_weightinterval;
reg [REG_WIDTH - 1 : 0] i_conf_kernelshape;
reg [REG_WIDTH - 1 : 0] i_conf_inputshape;
reg [REG_WIDTH - 1 : 0] i_conf_outputsize;
reg [REG_WIDTH - 1 : 0] i_conf_inputrstcnt;
wire [REG_WIDTH - 1 : 0] o_conf_status;

wire [ADDR_WIDTH - 1 : 0] mem_addr [6 : 0];
wire [DATA_WIDTH - 1 : 0] mem_idat [6 : 0];
wire [DATA_WIDTH - 1 : 0] mem_odat [6 : 0];
wire   [NUM_BYTE - 1 : 0] mem_wren [6 : 0];
wire                      mem_enb  [6 : 0];
wire                      mem_rst  [6 : 0];

dnn_accelerator_core dut(
    .clk                    (clk),
    .rst                    (rst),

    .i_conf_ctrl            (i_conf_ctrl),
    .i_conf_outputsize      (i_conf_outputsize),
    .i_conf_kernelsize      (i_conf_kernelsize),
    .i_conf_weightinterval  (i_conf_weightinterval),
    .i_conf_kernelshape     (i_conf_kernelshape),
    .i_conf_inputshape      (i_conf_inputshape),
    .i_conf_inputrstcnt     (i_conf_inputrstcnt),
    .o_conf_status          (o_conf_status),

    .mem_addr_0             (mem_addr[0]),
    .mem_idat_0             (mem_idat[0]),
    .mem_odat_0             (mem_odat[0]),
    .mem_wren_0             (mem_wren[0]),
    .mem_enb_0              (mem_enb[0]),
    .mem_rst_0              (mem_rst[0]),

    .mem_addr_1             (mem_addr[1]),
    .mem_idat_1             (mem_idat[1]),
    .mem_odat_1             (mem_odat[1]),
    .mem_wren_1             (mem_wren[1]),
    .mem_enb_1              (mem_enb[1]),
    .mem_rst_1              (mem_rst[1]),

    .mem_addr_2             (mem_addr[2]),
    .mem_idat_2             (mem_idat[2]),
    .mem_odat_2             (mem_odat[2]),
    .mem_wren_2             (mem_wren[2]),
    .mem_enb_2              (mem_enb[2]),
    .mem_rst_2              (mem_rst[2]),

    .mem_addr_3             (mem_addr[3]),
    .mem_idat_3             (mem_idat[3]),
    .mem_odat_3             (mem_odat[3]),
    .mem_wren_3             (mem_wren[3]),
    .mem_enb_3              (mem_enb[3]),
    .mem_rst_3              (mem_rst[3]),

    .mem_addr_4             (mem_addr[4]),
    .mem_idat_4             (mem_idat[4]),
    .mem_odat_4             (mem_odat[4]),
    .mem_wren_4             (mem_wren[4]),
    .mem_enb_4              (mem_enb[4]),
    .mem_rst_4              (mem_rst[4]),

    .mem_addr_5             (mem_addr[5]),
    .mem_idat_5             (mem_idat[5]),
    .mem_odat_5             (mem_odat[5]),
    .mem_wren_5             (mem_wren[5]),
    .mem_enb_5              (mem_enb[5]),
    .mem_rst_5              (mem_rst[5]),

    .mem_addr_6             (mem_addr[6]),
    .mem_idat_6             (mem_idat[6]),
    .mem_odat_6             (mem_odat[6]),
    .mem_wren_6             (mem_wren[6]),
    .mem_enb_6              (mem_enb[6]),
    .mem_rst_6              (mem_rst[6])
    );

rtest_data_bram_tb_sim bram0_data(
    .clk                    (clk),
    .rst                    (rst),
    .irdaddr                (mem_addr[0]),
    .odat                   (mem_odat[0])
    );

rtest_weight_bram_tb_sim bram1_weight0(
    .clk                    (clk),
    .rst                    (rst),
    .irdaddr                (mem_addr[1]),
    .odat                   (mem_odat[1])
    );

data_bram_tb_sim bram2_weight1(
    .clk                    (clk),
    .rst                    (rst),
    .irdaddr                (mem_addr[2]),
    .odat                   (mem_odat[2])
    );

data_bram_tb_sim bram3_weight2(
    .clk                    (clk),
    .rst                    (rst),
    .irdaddr                (mem_addr[3]),
    .odat                   (mem_odat[3])
    );

data_bram_tb_sim bram4_weight3(
    .clk                    (clk),
    .rst                    (rst),
    .irdaddr                (mem_addr[4]),
    .odat                   (mem_odat[4])
    );

reg               [18:0] bram_addr_a = 0;
reg                      bram_clk_a = 0;
reg [DATA_WIDTH - 1 : 0] bram_wrdata_a = 0;
wire               [18:0] bram_rddata_a;
reg                      bram_en_a = 0;
reg                      bram_rst_a = 0;
reg   [NUM_BYTE - 1 : 0] bram_we_a = 0;

wire [ADDR_WIDTH - 1 : 0] bram_psum_addr;
wire [DATA_WIDTH - 1 : 0] bram_psum_idat;
wire [DATA_WIDTH - 1 : 0] bram_psum_odat;
wire   [NUM_BYTE - 1 : 0] bram_psum_wren;
wire                      bram_psum_enb;
wire                      bram_psum_rst;
wire                      bram_psum_clk;

psum_bramctrl_bus_mux bram5_bus_mux(
    .clk                    (clk),
    .i_conf_ctrl            (i_conf_ctrl),
    .bram_addr_a            (bram_addr_a),
    .bram_clk_a             (bram_clk_a),
    .bram_wrdata_a          (bram_wrdata_a),
    .bram_rddata_a          (bram_rddata_a),
    .bram_en_a              (bram_en_a),
    .bram_rst_a             (bram_rst_a),
    .bram_we_a              (bram_we_a),
    .mem_addr               (mem_addr[5]),
    .mem_idat               (mem_idat[5]),
    .mem_odat               (mem_odat[5]),
    .mem_wren               (mem_wren[5]),
    .mem_enb                (mem_enb[5]),
    .mem_rst                (mem_rst[5]),
    .addra                  (bram_psum_addr),
    .clka                   (bram_psum_clk),
    .dina                   (bram_psum_idat),
    .douta                  (bram_psum_odat),
    .ena                    (bram_psum_wren),
    .rsta                   (bram_psum_enb),
    .wea                    (bram_psum_rst)
    );

psum_bram_tb_sim bram5_psum(
    .clk                    (clk),
    .rst                    (rst),
    .waddr                  (mem_addr[6]),
    .idat                   (mem_idat[6]),
    .wren                   (mem_wren[6]),
    .raddr                  (bram_psum_addr),
    .odat                   (bram_psum_odat)
    );

initial begin
    clk <= 0;
    forever begin
        #0.5 clk <= ~clk;
    end
end

initial begin
    rst <= 1;
    #20 rst <= 0;
end

localparam WEIGHT_INTERVAL = 32'd147851; // 222 * 222 * 3 - 1
initial begin
    i_conf_ctrl <= 0;
    i_conf_cnt <= 0;
    i_conf_kernelsize <= 0;
    i_conf_weightinterval <= 0;
    i_conf_kernelshape <= 0;
    i_conf_inputshape <= 0;
    i_conf_inputrstcnt <= 0;
    i_conf_outputsize <= 0;

    #50 
    i_conf_ctrl <= 32'b1;
    i_conf_cnt <= 32'd50176;
    i_conf_kernelsize <= 32'd9;
    i_conf_weightinterval <= WEIGHT_INTERVAL;
    i_conf_kernelshape <= 32'h0008_0333; // h0020_0333
    i_conf_inputshape <= 32'h0001_03e0;
    // i_conf_inputrstcnt <= 32'd49283; // 222 * 222 - 1
    i_conf_inputrstcnt <= 32'd49727; // 224 * 222 - 1
    i_conf_outputsize <= 32'd49283;

    #300000.5
    i_conf_ctrl <= 32'b10001;
    
    // #50
    // i_conf_ctrl <= 32'b00001;
end

endmodule
