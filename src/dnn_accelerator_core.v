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

    mem_addr_7,
    mem_idat_7,
    mem_odat_7,
    mem_wren_7,
    mem_enb_7,
    mem_rst_7,

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
    i_conf_outputsize,
    i_conf_kernelsize,
    i_conf_weightinterval,
    i_conf_kernelshape,
    i_conf_inputshape,
    i_conf_inputrstcnt,
    o_conf_status,
    dbg_linekcpe_valid_knx_cnt,
    dbg_linekcpe_psum_line_vld_cnt,
    dbg_linekcpe_idata_req_cnt,
    dbg_linekcpe_odata_req_cnt,
    dbg_linekcpe_weight_line_req_cnt,
    dbg_linekcpe_weight_done_cnt,
    dbg_linekcpe_kernel_done_cnt,
    dbg_psumacc_base_addr,
    dbg_psumacc_psum_out_cnt,
    dbg_psumacc_wr_addr,
    dbg_psumacc_rd_addr,
    dbg_datareq_knlinex_cnt,
    dbg_datareq_addr_reg,

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

output [ADDR_WIDTH - 1 : 0] mem_addr_7;
output [DATA_WIDTH - 1 : 0] mem_idat_7;
input  [DATA_WIDTH - 1 : 0] mem_odat_7;
output   [NUM_BYTE - 1 : 0] mem_wren_7;
output                      mem_enb_7;
output                      mem_rst_7;

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
wire                               core_i_data_val;
wire                               core_i_weight_val;
wire          [ADDR_WIDTH - 1 : 0] core_memctrl0_wadd;
wire                               core_memctrl0_wren;
wire          [DATA_WIDTH - 1 : 0] core_memctrl0_idat;
wire          [ADDR_WIDTH - 1 : 0] core_memctrl0_radd;
wire                               core_memctrl0_rden;
wire          [DATA_WIDTH - 1 : 0] core_memctrl0_odat;
wire                               core_memctrl0_oval;

input [REG_WIDTH - 1 : 0] i_conf_ctrl;
input [REG_WIDTH - 1 : 0] i_conf_outputsize;
input [REG_WIDTH - 1 : 0] i_conf_kernelsize;
input [REG_WIDTH - 1 : 0] i_conf_weightinterval;
input [REG_WIDTH - 1 : 0] i_conf_kernelshape;
input [REG_WIDTH - 1 : 0] i_conf_inputshape;
input [REG_WIDTH - 1 : 0] i_conf_inputrstcnt;
output [REG_WIDTH - 1 : 0] o_conf_status;

output [REG_WIDTH - 1 : 0] dbg_linekcpe_valid_knx_cnt;
output [REG_WIDTH - 1 : 0] dbg_linekcpe_psum_line_vld_cnt;
output [REG_WIDTH - 1 : 0] dbg_linekcpe_idata_req_cnt;
output [REG_WIDTH - 1 : 0] dbg_linekcpe_odata_req_cnt;
output [REG_WIDTH - 1 : 0] dbg_linekcpe_weight_line_req_cnt;
output [REG_WIDTH - 1 : 0] dbg_linekcpe_weight_done_cnt;
output [REG_WIDTH - 1 : 0] dbg_linekcpe_kernel_done_cnt;
output [REG_WIDTH - 1 : 0] dbg_psumacc_base_addr;
output [REG_WIDTH - 1 : 0] dbg_psumacc_psum_out_cnt;
output [REG_WIDTH - 1 : 0] dbg_psumacc_wr_addr;
output [REG_WIDTH - 1 : 0] dbg_psumacc_rd_addr;

output [REG_WIDTH - 1 : 0] dbg_datareq_knlinex_cnt;
output [REG_WIDTH - 1 : 0] dbg_datareq_addr_reg;


// Core
accelerator_core accelerator_core_inst(
    .clk                    (clk),
    .rst                    (rst),
    .o_data_req             (core_o_data_req),
    .o_data_end             (core_o_data_end),
    .i_data                 (core_i_data),
    .i_data_val             (core_i_data_val),
    .o_weight_req           (core_o_weight_req),
    .i_weight               (core_i_weight),
    .i_weight_val           (core_i_weight_val),
    .memctrl0_wadd          (core_memctrl0_wadd),
    .memctrl0_wren          (core_memctrl0_wren),
    .memctrl0_idat          (core_memctrl0_idat),
    .memctrl0_radd          (core_memctrl0_radd),
    .memctrl0_rden          (core_memctrl0_rden),
    .memctrl0_odat          (core_memctrl0_odat),
    .memctrl0_oval          (core_memctrl0_oval),
    .i_conf_ctrl            (i_conf_ctrl),
    .i_conf_outputsize      (i_conf_outputsize),
    .i_conf_kernelsize      (i_conf_kernelsize),
    .i_conf_weightinterval  (i_conf_weightinterval),
    .i_conf_kernelshape     (i_conf_kernelshape),
    .i_conf_inputshape      (i_conf_inputshape),
    .i_conf_inputrstcnt     (i_conf_inputrstcnt),
    .o_conf_status          (o_conf_status),
    .dbg_linekcpe_valid_knx_cnt         (dbg_linekcpe_valid_knx_cnt),
    .dbg_linekcpe_psum_line_vld_cnt     (dbg_linekcpe_psum_line_vld_cnt),
    .dbg_linekcpe_idata_req_cnt         (dbg_linekcpe_idata_req_cnt),
    .dbg_linekcpe_odata_req_cnt         (dbg_linekcpe_odata_req_cnt),
    .dbg_linekcpe_weight_line_req_cnt   (dbg_linekcpe_weight_line_req_cnt),
    .dbg_linekcpe_weight_done_cnt       (dbg_linekcpe_weight_done_cnt),
    .dbg_linekcpe_kernel_done_cnt       (dbg_linekcpe_kernel_done_cnt),
    .dbg_psumacc_base_addr              (dbg_psumacc_base_addr),
    .dbg_psumacc_psum_out_cnt           (dbg_psumacc_psum_out_cnt),
    .dbg_psumacc_rd_addr                (dbg_psumacc_rd_addr),
    .dbg_psumacc_wr_addr                (dbg_psumacc_wr_addr)
    );

// Data request
wire [DATA_WIDTH - 1 : 0] pixelconcat_idat;
wire                      pixelconcat_ival;
wire                      pixelconcat_ostall;
wire [ADDR_WIDTH - 1 : 0] datareq_o_addr;
wire                      datareq_o_rden;

data_req data_req_inst(
    .clk                    (clk),
    .rst                    (rst),
    .i_req                  (core_o_data_req),
    .i_end                  (core_o_data_end),
    .i_stall                (pixelconcat_ostall),
    .o_addr                 (datareq_o_addr),
    .o_rden                 (datareq_o_rden),
    .i_conf_inputshape      (i_conf_inputshape),
    .i_conf_kernelshape     (i_conf_kernelshape),
    .dbg_datareq_knlinex_cnt(dbg_datareq_knlinex_cnt),
    .dbg_datareq_addr_reg   (dbg_datareq_addr_reg)
    );

pixel_concat pixel_concat_inst(
    .clk                    (clk),
    .rst                    (rst),
    .idat                   (pixelconcat_idat),
    .ival                   (pixelconcat_ival),
    .odat                   (core_i_data),
    .oval                   (core_i_data_val),
    .ostall                 (pixelconcat_ostall)
    );

bram_ctrl
    #(
    .ADDR_MODE              (2)
    )
data_bram_ctrl_inst(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (datareq_o_addr),
    .wren                   (0),
    .idat                   (0),
    .rden                   (datareq_o_rden),
    .odat                   (pixelconcat_idat),
    .oval                   (pixelconcat_ival),
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
wire                      weightreq_mem0_oval;
wire                      weightreq_mem1_oval;
wire                      weightreq_mem2_oval;
wire                      weightreq_mem3_oval;

weight_req weight_req_inst(
    .clk                    (clk),
    .rst                    (rst),
    .i_req                  (core_o_weight_req),
    .o_dat                  (core_i_weight),
    .o_vld                  (core_i_weight_val),
    .memx_addr              (weightreq_memx_addr),
    .memx_rden              (weightreq_memx_rden),
    .mem0_odat              (weightreq_mem0_odat),
    .mem1_odat              (weightreq_mem1_odat),
    .mem2_odat              (weightreq_mem2_odat),
    .mem3_odat              (weightreq_mem3_odat),
    .mem0_oval              (weightreq_mem0_oval),
    .mem1_oval              (weightreq_mem1_oval),
    .mem2_oval              (weightreq_mem2_oval),
    .mem3_oval              (weightreq_mem3_oval)
    );

bram_ctrl
    #(
    .ADDR_MODE              (2)
    )
weight_bram_ctrl_inst_0(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (weightreq_memx_addr),
    .wren                   (0),
    .idat                   (0),
    .rden                   (weightreq_memx_rden),
    .odat                   (weightreq_mem0_odat),
    .oval                   (weightreq_mem0_oval),
    .mem_addr               (mem_addr_1),
    .mem_idat               (mem_idat_1),
    .mem_odat               (mem_odat_1),
    .mem_wren               (mem_wren_1),
    .mem_enb                (mem_enb_1),
    .mem_rst                (mem_rst_1)
    );

bram_ctrl
    #(
    .ADDR_MODE              (2)
    )
weight_bram_ctrl_inst_1(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (weightreq_memx_addr),
    .wren                   (0),
    .idat                   (0),
    .rden                   (weightreq_memx_rden),
    .odat                   (weightreq_mem1_odat),
    .oval                   (weightreq_mem1_oval),
    .mem_addr               (mem_addr_2),
    .mem_idat               (mem_idat_2),
    .mem_odat               (mem_odat_2),
    .mem_wren               (mem_wren_2),
    .mem_enb                (mem_enb_2),
    .mem_rst                (mem_rst_2)
    );

bram_ctrl
    #(
    .ADDR_MODE              (2)
    )
weight_bram_ctrl_inst_2(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (weightreq_memx_addr),
    .wren                   (0),
    .idat                   (0),
    .rden                   (weightreq_memx_rden),
    .odat                   (weightreq_mem2_odat),
    .oval                   (weightreq_mem2_oval),
    .mem_addr               (mem_addr_3),
    .mem_idat               (mem_idat_3),
    .mem_odat               (mem_odat_3),
    .mem_wren               (mem_wren_3),
    .mem_enb                (mem_enb_3),
    .mem_rst                (mem_rst_3)
    );

bram_ctrl
    #(
    .ADDR_MODE              (2)
    )
weight_bram_ctrl_inst_3(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (weightreq_memx_addr),
    .wren                   (0),
    .idat                   (0),
    .rden                   (weightreq_memx_rden),
    .odat                   (weightreq_mem3_odat),
    .oval                   (weightreq_mem3_oval),
    .mem_addr               (mem_addr_4),
    .mem_idat               (mem_idat_4),
    .mem_odat               (mem_odat_4),
    .mem_wren               (mem_wren_4),
    .mem_enb                (mem_enb_4),
    .mem_rst                (mem_rst_4)
    );

// Psum accum
bram_ctrl psum_bram_ctrl_inst_0(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (core_memctrl0_radd),
    .wren                   (0),
    .idat                   (0),
    .rden                   (core_memctrl0_rden),
    .odat                   (core_memctrl0_odat),
    .oval                   (core_memctrl0_oval),
    .mem_addr               (mem_addr_5),
    .mem_idat               (mem_idat_5),
    .mem_odat               (mem_odat_5),
    .mem_wren               (mem_wren_5),
    .mem_enb                (mem_enb_5),
    .mem_rst                (mem_rst_5)
    );

bram_ctrl psum_bram_ctrl_inst_1(
    .clk                    (clk),
    .rst                    (rst),
    .addr                   (core_memctrl0_wadd),
    .wren                   (core_memctrl0_wren),
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


assign mem_addr_7 = mem_addr_6 << 2;
assign mem_idat_7 = mem_idat_6;
assign mem_odat_7 = mem_odat_6;
assign mem_wren_7 = mem_wren_6;
assign mem_enb_7 = mem_enb_6;
assign mem_rst_7 = mem_rst_6;

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
