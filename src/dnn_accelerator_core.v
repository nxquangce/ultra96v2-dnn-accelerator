`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 05/09/2021 01:00:36 AM
// Design Name: DNN Accelerator Core
// Module Name: dnn_accelerator_core
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: DNN Accelerator Core
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dnn_accelerator_core(
    clk,
    rst,

    mem_addr_0,
    mem_idat_0,
    mem_odat_0,
    mem_wren_0,
    mem_enb_0,
    mem_rst_0,

    mem_addr_1,
    mem_idat_1,
    mem_odat_1,
    mem_wren_1,
    mem_enb_1,
    mem_rst_1,

    mem_addr_2,
    mem_idat_2,
    mem_odat_2,
    mem_wren_2,
    mem_enb_2,
    mem_rst_2,

    mem_addr_3,
    mem_idat_3,
    mem_odat_3,
    mem_wren_3,
    mem_enb_3,
    mem_rst_3,

    mem_addr_4,
    mem_idat_4,
    mem_odat_4,
    mem_wren_4,
    mem_enb_4,
    mem_rst_4,

    mem_addr_5,
    mem_idat_5,
    mem_odat_5,
    mem_wren_5,
    mem_enb_5,
    mem_rst_5,

    mem_addr_6,
    mem_idat_6,
    mem_odat_6,
    mem_wren_6,
    mem_enb_6,
    mem_rst_6,

`ifdef ENABLE_DUPLICATE_OUTPUT_BRAM
    
    mem_addr_7,
    mem_idat_7,
    mem_odat_7,
    mem_wren_7,
    mem_enb_7,
    mem_rst_7,

`else
    mem_addr_7,
    mem_idat_7,
    mem_odat_7,
    mem_wren_7,
    mem_enb_7,
    mem_rst_7,

    mem_addr_8,
    mem_idat_8,
    mem_odat_8,
    mem_wren_8,
    mem_enb_8,
    mem_rst_8,

    mem_addr_9,
    mem_idat_9,
    mem_odat_9,
    mem_wren_9,
    mem_enb_9,
    mem_rst_9,

    mem_addr_10,
    mem_idat_10,
    mem_odat_10,
    mem_wren_10,
    mem_enb_10,
    mem_rst_10,

    mem_addr_11,
    mem_idat_11,
    mem_odat_11,
    mem_wren_11,
    mem_enb_11,
    mem_rst_11,

    mem_addr_12,
    mem_idat_12,
    mem_odat_12,
    mem_wren_12,
    mem_enb_12,
    mem_rst_12,

`endif

    // S_AXI_ACLK,
    // S_AXI_ARESETN,
    // S_AXI_AWADDR,
    // S_AXI_AWPROT,
    // S_AXI_AWVALID,
    // S_AXI_AWREADY,
    // S_AXI_WDATA,
    // S_AXI_WSTRB,
    // S_AXI_WVALID,
    // S_AXI_WREADY,
    // S_AXI_BRESP,
    // S_AXI_BVALID,
    // S_AXI_BREADY,
    // S_AXI_ARADDR,
    // S_AXI_ARPROT,
    // S_AXI_ARVALID,
    // S_AXI_ARREADY,
    // S_AXI_RDATA,
    // S_AXI_RRESP,
    // S_AXI_RVALID,
    // S_AXI_RREADY,
    i_conf_ctrl,
    i_conf_inputshape,
    i_conf_kernelshape,
    i_conf_kernelsize,
    i_conf_outputshape,
    i_conf_outputsize,
    i_conf_weightinterval,
    i_conf_inputrstcnt,
    i_conf_addr,
    i_conf_data,
    o_conf_status,
    dbg_reg_data,
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations

parameter DATA_WIDTH    = 32;
parameter ADDR_WIDTH    = 32;

localparam NUM_BYTE     = 4;

parameter REG_WIDTH     = 32;

parameter BIT_WIDTH     = 8;
parameter NUM_CHANNEL   = 3;
parameter NUM_KERNEL    = 4;
parameter NUM_KCPE      = 3;    // Number of kernel-channel PE

parameter IN_INPUT_DAT_WIDTH  = BIT_WIDTH * NUM_CHANNEL;
parameter IN_WEIGHT_DAT_WIDTH = BIT_WIDTH * NUM_CHANNEL * NUM_KERNEL;

parameter OUTPUT_MEM_ADDR_MODE = 2;
parameter OUTPUT_MEM_DELAY     = 1;

// AXI
// Width of S_AXI data bus
parameter integer C_S_AXI_DATA_WIDTH    = 32;
// Width of S_AXI address bus
parameter integer C_S_AXI_ADDR_WIDTH    = 7;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                      clk;
input                      rst;

output [ADDR_WIDTH - 1 : 0] mem_addr_0;
output [DATA_WIDTH - 1 : 0] mem_idat_0;
input  [DATA_WIDTH - 1 : 0] mem_odat_0;
output   [NUM_BYTE - 1 : 0] mem_wren_0;
output                      mem_enb_0;
output                      mem_rst_0;

output [ADDR_WIDTH - 1 : 0] mem_addr_1;
output [DATA_WIDTH - 1 : 0] mem_idat_1;
input  [DATA_WIDTH - 1 : 0] mem_odat_1;
output   [NUM_BYTE - 1 : 0] mem_wren_1;
output                      mem_enb_1;
output                      mem_rst_1;

output [ADDR_WIDTH - 1 : 0] mem_addr_2;
output [DATA_WIDTH - 1 : 0] mem_idat_2;
input  [DATA_WIDTH - 1 : 0] mem_odat_2;
output   [NUM_BYTE - 1 : 0] mem_wren_2;
output                      mem_enb_2;
output                      mem_rst_2;

output [ADDR_WIDTH - 1 : 0] mem_addr_3;
output [DATA_WIDTH - 1 : 0] mem_idat_3;
input  [DATA_WIDTH - 1 : 0] mem_odat_3;
output   [NUM_BYTE - 1 : 0] mem_wren_3;
output                      mem_enb_3;
output                      mem_rst_3;

output [ADDR_WIDTH - 1 : 0] mem_addr_4;
output [DATA_WIDTH - 1 : 0] mem_idat_4;
input  [DATA_WIDTH - 1 : 0] mem_odat_4;
output   [NUM_BYTE - 1 : 0] mem_wren_4;
output                      mem_enb_4;
output                      mem_rst_4;

output [ADDR_WIDTH - 1 : 0] mem_addr_5;
output [DATA_WIDTH - 1 : 0] mem_idat_5;
input  [DATA_WIDTH - 1 : 0] mem_odat_5;
output   [NUM_BYTE - 1 : 0] mem_wren_5;
output                      mem_enb_5;
output                      mem_rst_5;

output [ADDR_WIDTH - 1 : 0] mem_addr_6;
output [DATA_WIDTH - 1 : 0] mem_idat_6;
input  [DATA_WIDTH - 1 : 0] mem_odat_6;
output   [NUM_BYTE - 1 : 0] mem_wren_6;
output                      mem_enb_6;
output                      mem_rst_6;

`ifdef ENABLE_DUPLICATE_OUTPUT_BRAM

output [ADDR_WIDTH - 1 : 0] mem_addr_7;
output [DATA_WIDTH - 1 : 0] mem_idat_7;
input  [DATA_WIDTH - 1 : 0] mem_odat_7;
output   [NUM_BYTE - 1 : 0] mem_wren_7;
output                      mem_enb_7;
output                      mem_rst_7;

`else

output [ADDR_WIDTH - 1 : 0] mem_addr_7;
output [DATA_WIDTH - 1 : 0] mem_idat_7;
input  [DATA_WIDTH - 1 : 0] mem_odat_7;
output   [NUM_BYTE - 1 : 0] mem_wren_7;
output                      mem_enb_7;
output                      mem_rst_7;

output [ADDR_WIDTH - 1 : 0] mem_addr_8;
output [DATA_WIDTH - 1 : 0] mem_idat_8;
input  [DATA_WIDTH - 1 : 0] mem_odat_8;
output   [NUM_BYTE - 1 : 0] mem_wren_8;
output                      mem_enb_8;
output                      mem_rst_8;

output [ADDR_WIDTH - 1 : 0] mem_addr_9;
output [DATA_WIDTH - 1 : 0] mem_idat_9;
input  [DATA_WIDTH - 1 : 0] mem_odat_9;
output   [NUM_BYTE - 1 : 0] mem_wren_9;
output                      mem_enb_9;
output                      mem_rst_9;

output [ADDR_WIDTH - 1 : 0] mem_addr_10;
output [DATA_WIDTH - 1 : 0] mem_idat_10;
input  [DATA_WIDTH - 1 : 0] mem_odat_10;
output   [NUM_BYTE - 1 : 0] mem_wren_10;
output                      mem_enb_10;
output                      mem_rst_10;

output [ADDR_WIDTH - 1 : 0] mem_addr_11;
output [DATA_WIDTH - 1 : 0] mem_idat_11;
input  [DATA_WIDTH - 1 : 0] mem_odat_11;
output   [NUM_BYTE - 1 : 0] mem_wren_11;
output                      mem_enb_11;
output                      mem_rst_11;

output [ADDR_WIDTH - 1 : 0] mem_addr_12;
output [DATA_WIDTH - 1 : 0] mem_idat_12;
input  [DATA_WIDTH - 1 : 0] mem_odat_12;
output   [NUM_BYTE - 1 : 0] mem_wren_12;
output                      mem_enb_12;
output                      mem_rst_12;

`endif

input   [REG_WIDTH - 1 : 0] i_conf_ctrl;
input   [REG_WIDTH - 1 : 0] i_conf_inputshape;
input   [REG_WIDTH - 1 : 0] i_conf_kernelshape;
input   [REG_WIDTH - 1 : 0] i_conf_kernelsize;
input   [REG_WIDTH - 1 : 0] i_conf_outputshape;
input   [REG_WIDTH - 1 : 0] i_conf_outputsize;
input   [REG_WIDTH - 1 : 0] i_conf_weightinterval;
input   [REG_WIDTH - 1 : 0] i_conf_inputrstcnt;
input   [REG_WIDTH - 1 : 0] i_conf_addr;
input   [REG_WIDTH - 1 : 0] i_conf_data;
output  [REG_WIDTH - 1 : 0] o_conf_status;
output  [REG_WIDTH - 1 : 0] dbg_reg_data;

// Config regfile AXI
//input  wire                                S_AXI_ACLK;
//input  wire                                S_AXI_ARESETN;
//input  wire     [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR;
//input  wire                        [2 : 0] S_AXI_AWPROT;
//input  wire                                S_AXI_AWVALID;
//output wire                                S_AXI_AWREADY;
//input  wire     [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA;
//input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB;
//input  wire                                S_AXI_WVALID;
//output wire                                S_AXI_WREADY;
//output wire                        [1 : 0] S_AXI_BRESP;
//output wire                                S_AXI_BVALID;
//input  wire                                S_AXI_BREADY;
//input  wire     [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR;
//input  wire                        [2 : 0] S_AXI_ARPROT;
//input  wire                                S_AXI_ARVALID;
//output wire                                S_AXI_ARREADY;
//output wire     [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA;
//output wire                        [1 : 0] S_AXI_RRESP;
//output wire                                S_AXI_RVALID;
//input  wire                                S_AXI_RREADY;


////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire                               core_o_data_req;
wire                               core_o_data_end;
wire                               core_o_weight_req;
wire [IN_INPUT_DAT_WIDTH  - 1 : 0] core_i_data;
wire [IN_WEIGHT_DAT_WIDTH - 1 : 0] core_i_weight;
wire                               core_i_data_vld;
wire                               core_i_weight_vld;

wire          [ADDR_WIDTH - 1 : 0] core_memctrl0_wadd;
wire                               core_memctrl0_wren;
wire          [DATA_WIDTH - 1 : 0] core_memctrl0_idat;
wire          [ADDR_WIDTH - 1 : 0] core_memctrl0_radd;
wire                               core_memctrl0_rden;
wire          [DATA_WIDTH - 1 : 0] core_memctrl0_odat;
wire                               core_memctrl0_ovld;

wire           [REG_WIDTH - 1 : 0] core_ps_addr;
wire                               core_ps_wren;
wire           [REG_WIDTH - 1 : 0] core_ps_wdat;
wire                               core_ps_rden;
wire           [REG_WIDTH - 1 : 0] core_ps_rdat;
wire                               core_ps_rvld;


// Core
accelerator_core
    #(
    .OUTPUT_MEM_DELAY       (OUTPUT_MEM_DELAY + 1)
    )
accelerator_core_inst(
    .clk                                (clk),
    .rst                                (rst),
    .o_data_req                         (core_o_data_req),
    .o_data_end                         (core_o_data_end),
    .i_data                             (core_i_data),
    .i_data_vld                         (core_i_data_vld),
    .o_weight_req                       (core_o_weight_req),
    .i_weight                           (core_i_weight),
    .i_weight_vld                       (core_i_weight_vld),
    .memctrl0_wadd                      (core_memctrl0_wadd),
    .memctrl0_wren                      (core_memctrl0_wren),
    .memctrl0_idat                      (core_memctrl0_idat),
    .memctrl0_radd                      (core_memctrl0_radd),
    .memctrl0_rden                      (core_memctrl0_rden),
    .memctrl0_odat                      (core_memctrl0_odat),
    .memctrl0_ovld                      (core_memctrl0_ovld),
    .i_conf_ctrl                        (i_conf_ctrl),
    .i_conf_outputsize                  (i_conf_outputsize),
    .i_conf_kernelsize                  (i_conf_kernelsize),
    .i_conf_weightinterval              (i_conf_weightinterval),
    .i_conf_kernelshape                 (i_conf_kernelshape),
    .i_conf_inputshape                  (i_conf_inputshape),
    .i_conf_inputrstcnt                 (i_conf_inputrstcnt),
    .i_conf_outputshape                 (i_conf_outputshape),
    .o_conf_status                      (o_conf_status),
    .ps_addr                            (core_ps_addr),
    .ps_wren                            (core_ps_wren),
    .ps_wdat                            (core_ps_wdat),
    .ps_rden                            (core_ps_rden),
    .ps_rdat                            (core_ps_rdat),
    .ps_rvld                            (core_ps_rvld)
    );

// Data request
wire [DATA_WIDTH - 1 : 0] pixelconcat_idat;
wire                      pixelconcat_ivld;
wire                      pixelconcat_ostall;
wire [ADDR_WIDTH - 1 : 0] datareq_o_addr;
wire                      datareq_o_rden;
wire                [3:0] i_cnfx_stride;
wire                [3:0] i_cnfx_padding;

assign i_cnfx_stride = i_conf_kernelsize[19:16];
assign i_cnfx_padding = i_conf_kernelsize[27:24];

data_req data_req_inst(
    .clk                    (clk),
    .rst                    (rst),
    .i_req                  (core_o_data_req),
    .i_end                  (core_o_data_end),
    .i_stall                (pixelconcat_ostall),
    .o_addr                 (datareq_o_addr),
    .o_rden                 (datareq_o_rden),
    .i_cnfx_stride          (i_cnfx_stride),
    .i_cnfx_padding         (i_cnfx_padding),
    .i_conf_inputshape      (i_conf_inputshape),
    .i_conf_kernelshape     (i_conf_kernelshape),
    .dbg_datareq_knlinex_cnt(datareq_knlinex_cnt),
    .dbg_datareq_addr_reg   (datareq_addr_reg)
    );

pixel_concat pixel_concat_inst(
    .clk                    (clk),
    .rst                    (rst),
    .idat                   (pixelconcat_idat),
    .ival                   (pixelconcat_ivld),
    .odat                   (core_i_data),
    .oval                   (core_i_data_vld),
    .ostall                 (pixelconcat_ostall)
    );

bram_ctrl
    #(
    .ADDR_MODE              (2),
    .MEM_DELAY              (1)
    )
data_bram_ctrl_inst(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (datareq_o_addr),
    .wren                   (0),
    .idat                   (0),
    .rden                   (datareq_o_rden),
    .odat                   (pixelconcat_idat),
    .oval                   (pixelconcat_ivld),
    .mem_addr               (mem_addr_0),
    .mem_idat               (mem_idat_0),
    .mem_odat               (mem_odat_0),
    .mem_wren               (mem_wren_0),
    .mem_enb                (mem_enb_0),
    .mem_rst                (mem_rst_0)
    );

// Weight request
wire [ADDR_WIDTH - 1 : 0] weightreq_memx_addr;
wire                      weightreq_memx_rden;
wire [DATA_WIDTH - 1 : 0] weightreq_mem0_odat;
wire [DATA_WIDTH - 1 : 0] weightreq_mem1_odat;
wire [DATA_WIDTH - 1 : 0] weightreq_mem2_odat;
wire [DATA_WIDTH - 1 : 0] weightreq_mem3_odat;
wire                      weightreq_mem0_ovld;
wire                      weightreq_mem1_ovld;
wire                      weightreq_mem2_ovld;
wire                      weightreq_mem3_ovld;

weight_req weight_req_inst(
    .clk                    (clk),
    .rst                    (rst),
    .i_req                  (core_o_weight_req),
    .o_dat                  (core_i_weight),
    .o_vld                  (core_i_weight_vld),
    .memx_addr              (weightreq_memx_addr),
    .memx_rden              (weightreq_memx_rden),
    .mem0_odat              (weightreq_mem0_odat),
    .mem1_odat              (weightreq_mem1_odat),
    .mem2_odat              (weightreq_mem2_odat),
    .mem3_odat              (weightreq_mem3_odat),
    .mem0_oval              (weightreq_mem0_ovld),
    .mem1_oval              (weightreq_mem1_ovld),
    .mem2_oval              (weightreq_mem2_ovld),
    .mem3_oval              (weightreq_mem3_ovld)
    );

bram_ctrl
    #(
    .ADDR_MODE              (2),
    .MEM_DELAY              (1)
    )
weight_bram_ctrl_inst_0(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (weightreq_memx_addr),
    .wren                   (0),
    .idat                   (0),
    .rden                   (weightreq_memx_rden),
    .odat                   (weightreq_mem0_odat),
    .oval                   (weightreq_mem0_ovld),
    .mem_addr               (mem_addr_1),
    .mem_idat               (mem_idat_1),
    .mem_odat               (mem_odat_1),
    .mem_wren               (mem_wren_1),
    .mem_enb                (mem_enb_1),
    .mem_rst                (mem_rst_1)
    );

bram_ctrl
    #(
    .ADDR_MODE              (2),
    .MEM_DELAY              (1)
    )
weight_bram_ctrl_inst_1(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (weightreq_memx_addr),
    .wren                   (0),
    .idat                   (0),
    .rden                   (weightreq_memx_rden),
    .odat                   (weightreq_mem1_odat),
    .oval                   (weightreq_mem1_ovld),
    .mem_addr               (mem_addr_2),
    .mem_idat               (mem_idat_2),
    .mem_odat               (mem_odat_2),
    .mem_wren               (mem_wren_2),
    .mem_enb                (mem_enb_2),
    .mem_rst                (mem_rst_2)
    );

bram_ctrl
    #(
    .ADDR_MODE              (2),
    .MEM_DELAY              (1)
    )
weight_bram_ctrl_inst_2(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (weightreq_memx_addr),
    .wren                   (0),
    .idat                   (0),
    .rden                   (weightreq_memx_rden),
    .odat                   (weightreq_mem2_odat),
    .oval                   (weightreq_mem2_ovld),
    .mem_addr               (mem_addr_3),
    .mem_idat               (mem_idat_3),
    .mem_odat               (mem_odat_3),
    .mem_wren               (mem_wren_3),
    .mem_enb                (mem_enb_3),
    .mem_rst                (mem_rst_3)
    );

bram_ctrl
    #(
    .ADDR_MODE              (2),
    .MEM_DELAY              (1)
    )
weight_bram_ctrl_inst_3(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (weightreq_memx_addr),
    .wren                   (0),
    .idat                   (0),
    .rden                   (weightreq_memx_rden),
    .odat                   (weightreq_mem3_odat),
    .oval                   (weightreq_mem3_ovld),
    .mem_addr               (mem_addr_4),
    .mem_idat               (mem_idat_4),
    .mem_odat               (mem_odat_4),
    .mem_wren               (mem_wren_4),
    .mem_enb                (mem_enb_4),
    .mem_rst                (mem_rst_4)
    );

// Psum accum
wire          [ADDR_WIDTH - 1 : 0] bramctrl1_wadd;
wire                               bramctrl1_wren;
wire          [ADDR_WIDTH - 1 : 0] bramctrl0_radd;
wire                               bramctrl0_rden;
wire          [DATA_WIDTH - 1 : 0] bramctrl0_odat;
wire                               bramctrl0_ovld;

wire          [ADDR_WIDTH - 1 : 0] bramctrl3_wadd;
wire                               bramctrl3_wren;
wire          [ADDR_WIDTH - 1 : 0] bramctrl2_radd;
wire                               bramctrl2_rden;
wire          [DATA_WIDTH - 1 : 0] bramctrl2_odat;
wire                               bramctrl2_ovld;

wire          [ADDR_WIDTH - 1 : 0] bramctrl5_wadd;
wire                               bramctrl5_wren;
wire          [ADDR_WIDTH - 1 : 0] bramctrl4_radd;
wire                               bramctrl4_rden;
wire          [DATA_WIDTH - 1 : 0] bramctrl4_odat;
wire                               bramctrl4_ovld;

wire          [ADDR_WIDTH - 1 : 0] bramctrl7_wadd;
wire                               bramctrl7_wren;
wire          [ADDR_WIDTH - 1 : 0] bramctrl6_radd;
wire                               bramctrl6_rden;
wire          [DATA_WIDTH - 1 : 0] bramctrl6_odat;
wire                               bramctrl6_ovld;

output_mem_addr_decoder output_mem_addr_decoder_inst(
    .clk                    (clk),

    .psumctrl_wadd          (core_memctrl0_wadd),
    .psumctrl_wren          (core_memctrl0_wren),
    .psumctrl_radd          (core_memctrl0_radd),
    .psumctrl_rden          (core_memctrl0_rden),
    .psumctrl_odat          (core_memctrl0_odat),
    .psumctrl_ovld          (core_memctrl0_ovld),

    .bramctrl_addr_rd_0     (bramctrl0_radd),
    .bramctrl_rden_rd_0     (bramctrl0_rden),
    .bramctrl_odat_rd_0     (bramctrl0_odat),
    .bramctrl_oval_rd_0     (bramctrl0_ovld),
    .bramctrl_addr_wr_0     (bramctrl1_wadd),
    .bramctrl_wren_wr_0     (bramctrl1_wren),

    .bramctrl_addr_rd_1     (bramctrl2_radd),
    .bramctrl_rden_rd_1     (bramctrl2_rden),
    .bramctrl_odat_rd_1     (bramctrl2_odat),
    .bramctrl_oval_rd_1     (bramctrl2_ovld),
    .bramctrl_addr_wr_1     (bramctrl3_wadd),
    .bramctrl_wren_wr_1     (bramctrl3_wren),

    .bramctrl_addr_rd_2     (bramctrl4_radd),
    .bramctrl_rden_rd_2     (bramctrl4_rden),
    .bramctrl_odat_rd_2     (bramctrl4_odat),
    .bramctrl_oval_rd_2     (bramctrl4_ovld),
    .bramctrl_addr_wr_2     (bramctrl5_wadd),
    .bramctrl_wren_wr_2     (bramctrl5_wren),

    .bramctrl_addr_rd_3     (bramctrl6_radd),
    .bramctrl_rden_rd_3     (bramctrl6_rden),
    .bramctrl_odat_rd_3     (bramctrl6_odat),
    .bramctrl_oval_rd_3     (bramctrl6_ovld),
    .bramctrl_addr_wr_3     (bramctrl7_wadd),
    .bramctrl_wren_wr_3     (bramctrl7_wren)
    );

bram_ctrl
    #(
    .ADDR_MODE              (OUTPUT_MEM_ADDR_MODE),
    .MEM_DELAY              (OUTPUT_MEM_DELAY)
    )
psum_bram_ctrl_inst_0(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (bramctrl0_radd),
    .wren                   (0),
    .idat                   (0),
    .rden                   (bramctrl0_rden),
    .odat                   (bramctrl0_odat),
    .oval                   (bramctrl0_ovld),
    .mem_addr               (mem_addr_5),
    .mem_idat               (mem_idat_5),
    .mem_odat               (mem_odat_5),
    .mem_wren               (mem_wren_5),
    .mem_enb                (mem_enb_5),
    .mem_rst                (mem_rst_5)
    );

bram_ctrl
    #(
    .ADDR_MODE              (OUTPUT_MEM_ADDR_MODE),
    .MEM_DELAY              (OUTPUT_MEM_DELAY)
    )
psum_bram_ctrl_inst_1(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (bramctrl1_wadd),
    .wren                   (bramctrl1_wren),
    .idat                   (core_memctrl0_idat),
    .rden                   (0),
    .odat                   (),
    .oval                   (),
    .mem_addr               (mem_addr_6),
    .mem_idat               (mem_idat_6),
    .mem_odat               (mem_odat_6),
    .mem_wren               (mem_wren_6),
    .mem_enb                (mem_enb_6),
    .mem_rst                (mem_rst_6)
    );

`ifdef ENABLE_DUPLICATE_OUTPUT_BRAM

assign mem_addr_7 = mem_addr_6 << 2;
assign mem_idat_7 = mem_idat_6;
assign mem_wren_7 = mem_wren_6;
assign mem_enb_7 = mem_enb_6;
assign mem_rst_7 = mem_rst_6;

`else

bram_ctrl
    #(
    .ADDR_MODE              (OUTPUT_MEM_ADDR_MODE),
    .MEM_DELAY              (OUTPUT_MEM_DELAY)
    )
psum_bram_ctrl_inst_2(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (bramctrl2_radd),
    .wren                   (0),
    .idat                   (0),
    .rden                   (bramctrl2_rden),
    .odat                   (bramctrl2_odat),
    .oval                   (bramctrl2_ovld),
    .mem_addr               (mem_addr_7),
    .mem_idat               (mem_idat_7),
    .mem_odat               (mem_odat_7),
    .mem_wren               (mem_wren_7),
    .mem_enb                (mem_enb_7),
    .mem_rst                (mem_rst_7)
    );

bram_ctrl
    #(
    .ADDR_MODE              (OUTPUT_MEM_ADDR_MODE),
    .MEM_DELAY              (OUTPUT_MEM_DELAY)
    )
psum_bram_ctrl_inst_3(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (bramctrl3_wadd),
    .wren                   (bramctrl3_wren),
    .idat                   (core_memctrl0_idat),
    .rden                   (0),
    .odat                   (),
    .oval                   (),
    .mem_addr               (mem_addr_8),
    .mem_idat               (mem_idat_8),
    .mem_odat               (mem_odat_8),
    .mem_wren               (mem_wren_8),
    .mem_enb                (mem_enb_8),
    .mem_rst                (mem_rst_8)
    );

bram_ctrl
    #(
    .ADDR_MODE              (OUTPUT_MEM_ADDR_MODE),
    .MEM_DELAY              (OUTPUT_MEM_DELAY)
    )
psum_bram_ctrl_inst_4(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (bramctrl4_radd),
    .wren                   (0),
    .idat                   (0),
    .rden                   (bramctrl4_rden),
    .odat                   (bramctrl4_odat),
    .oval                   (bramctrl4_ovld),
    .mem_addr               (mem_addr_9),
    .mem_idat               (mem_idat_9),
    .mem_odat               (mem_odat_9),
    .mem_wren               (mem_wren_9),
    .mem_enb                (mem_enb_9),
    .mem_rst                (mem_rst_9)
    );

bram_ctrl
    #(
    .ADDR_MODE              (OUTPUT_MEM_ADDR_MODE),
    .MEM_DELAY              (OUTPUT_MEM_DELAY)
    )
psum_bram_ctrl_inst_5(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (bramctrl5_wadd),
    .wren                   (bramctrl5_wren),
    .idat                   (core_memctrl0_idat),
    .rden                   (0),
    .odat                   (),
    .oval                   (),
    .mem_addr               (mem_addr_10),
    .mem_idat               (mem_idat_10),
    .mem_odat               (mem_odat_10),
    .mem_wren               (mem_wren_10),
    .mem_enb                (mem_enb_10),
    .mem_rst                (mem_rst_10)
    );

bram_ctrl
    #(
    .ADDR_MODE              (OUTPUT_MEM_ADDR_MODE),
    .MEM_DELAY              (OUTPUT_MEM_DELAY)
    )
psum_bram_ctrl_inst_6(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (bramctrl6_radd),
    .wren                   (0),
    .idat                   (0),
    .rden                   (bramctrl6_rden),
    .odat                   (bramctrl6_odat),
    .oval                   (bramctrl6_ovld),
    .mem_addr               (mem_addr_11),
    .mem_idat               (mem_idat_11),
    .mem_odat               (mem_odat_11),
    .mem_wren               (mem_wren_11),
    .mem_enb                (mem_enb_11),
    .mem_rst                (mem_rst_11)
    );

bram_ctrl
    #(
    .ADDR_MODE              (OUTPUT_MEM_ADDR_MODE),
    .MEM_DELAY              (OUTPUT_MEM_DELAY)
    )
psum_bram_ctrl_inst_7(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (bramctrl7_wadd),
    .wren                   (bramctrl7_wren),
    .idat                   (core_memctrl0_idat),
    .rden                   (0),
    .odat                   (),
    .oval                   (),
    .mem_addr               (mem_addr_12),
    .mem_idat               (mem_idat_12),
    .mem_odat               (mem_odat_12),
    .mem_wren               (mem_wren_12),
    .mem_enb                (mem_enb_12),
    .mem_rst                (mem_rst_12)
    );

`endif
////////////////////////////////////////////////////////////////////
// Debug
wire [REG_WIDTH - 1 : 0] ps_addr;
wire                     ps_wren;
wire [REG_WIDTH - 1 : 0] ps_wdat;
wire                     ps_rden;
wire [REG_WIDTH - 1 : 0] ps_rdat;
wire                     ps_rvld;

wire [REG_WIDTH - 1 : 0] dbg_cnt_register_rdat;
wire                     dbg_cnt_register_rvld;

assign ps_rdat = dbg_cnt_register_rdat | core_ps_rdat;
assign ps_rvld = dbg_cnt_register_rvld | core_ps_rvld;

reg_access_ps_gen ps_dbg(
    .clk        (clk),
    .rst        (rst),
    .host_addr  (i_conf_addr),
    .host_idat  (i_conf_data),
    .host_odat  (dbg_reg_data),
    .user_addr  (ps_addr),
    .user_wren  (ps_wren),
    .user_wdat  (ps_wdat),
    .user_rden  (ps_rden),
    .user_rdat  (ps_rdat),
    .user_rvld  (ps_rvld)
    );

assign core_ps_addr = ps_addr;
assign core_ps_wren = ps_wren;
assign core_ps_wdat = ps_wdat;
assign core_ps_rden = ps_rden;

// Config registers
// config_regfile #
// (
//     .C_S_AXI_DATA_WIDTH     (C_S_AXI_DATA_WIDTH),
//     .C_S_AXI_ADDR_WIDTH     (C_S_AXI_ADDR_WIDTH)
// )
// config_regfile_inst
// (
//     // Users to add ports here
//     .reg0                   (i_conf_ctrl),
//     .reg1                   (i_conf_outputsize),
//     .reg2                   (i_conf_kernelsize),
//     .reg3                   (i_conf_weightinterval),
//     .reg4                   (i_conf_kernelshape),
//     .reg5                   (i_conf_inputshape),
//     .reg6                   (i_conf_inputrstcnt),
//     .ireg0                  (o_conf_status),
//     .ireg1                  (dbg_datareq_knlinex_cnt),
//     .ireg2                  (dbg_datareq_addr_reg),
//     .ireg3                  (dbg_linekcpe_valid_knx_cnt),
//     .ireg4                  (dbg_linekcpe_psum_line_vld_cnt),
//     .ireg5                  (dbg_linekcpe_idata_req_cnt),
//     .ireg6                  (dbg_linekcpe_odata_req_cnt),
//     .ireg7                  (dbg_linekcpe_weight_line_req_cnt),
//     .ireg8                  (dbg_linekcpe_weight_done_cnt),
//     .ireg9                  (dbg_linekcpe_kernel_done_cnt),
//     .ireg10                 (dbg_psumacc_base_addr),
//     .ireg11                 (dbg_psumacc_psum_out_cnt),
//     .ireg12                 (dbg_psumacc_rd_addr),
//     .ireg13                 (dbg_psumacc_wr_addr),

//     .S_AXI_ACLK             (S_AXI_ACLK),
//     .S_AXI_ARESETN          (S_AXI_ARESETN),
//     .S_AXI_AWADDR           (S_AXI_AWADDR),
//     .S_AXI_AWPROT           (S_AXI_AWPROT),
//     .S_AXI_AWVALID          (S_AXI_AWVALID),
//     .S_AXI_AWREADY          (S_AXI_AWREADY),
//     .S_AXI_WDATA            (S_AXI_WDATA),
//     .S_AXI_WSTRB            (S_AXI_WSTRB),
//     .S_AXI_WVALID           (S_AXI_WVALID),
//     .S_AXI_WREADY           (S_AXI_WREADY),
//     .S_AXI_BRESP            (S_AXI_BRESP),
//     .S_AXI_BVALID           (S_AXI_BVALID),
//     .S_AXI_BREADY           (S_AXI_BREADY),
//     .S_AXI_ARADDR           (S_AXI_ARADDR),
//     .S_AXI_ARPROT           (S_AXI_ARPROT),
//     .S_AXI_ARVALID          (S_AXI_ARVALID),
//     .S_AXI_ARREADY          (S_AXI_ARREADY),
//     .S_AXI_RDATA            (S_AXI_RDATA),
//     .S_AXI_RRESP            (S_AXI_RRESP),
//     .S_AXI_RVALID           (S_AXI_RVALID),
//     .S_AXI_RREADY           (S_AXI_RREADY)
// );

endmodule
